// Copyright (c) 2025 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

module guineveer #(
    `include "el2_param.vh",
    // AXI ID width for subordinates = log2(n_managers) + manager_id_width_max
    localparam int SUB_ID_WIDTH = 4
) (
    input  bit clk_i,
    input  bit rst_ni,
    input  bit cpu_rst_ni,

    input  bit i3c_clk_i,
    input  bit i3c_rst_ni,

`ifdef GUINEVEER_TESTBENCH
    input  bit cpu_halt_req_i,        // Async halt req to CPU
    output bit cpu_halt_ack_o,        // core response to halt
    output bit cpu_halt_status_o,     // 1'b1 indicates core is halted
    input  bit cpu_run_req_i,         // Async restart req to CPU
    output bit cpu_run_ack_o,         // Core response to run req
    input  bit mpc_debug_halt_req_i,
    output bit mpc_debug_halt_ack_o,
    input  bit mpc_debug_run_req_i,
    output bit mpc_debug_run_ack_o,
    output bit debug_mode_status_o,
    input  bit lsu_bus_clk_en_i,

    input logic timer_int_i,
    input logic soft_int_i,

    input logic [31:1] reset_vector_i,
    input logic        nmi_int_i,
    input logic [31:1] nmi_vector_i,
    input logic [31:1] jtag_id_i,
`endif

    input  wire  uart_rx_i,
    output logic uart_tx_o,

    // I3C bus IO
    inout wire i3c_scl_io,
    inout wire i3c_sda_io
);

  el2_mem_if el2_mem_export ();

  // AXI Slaves

  `AXI_TYPEDEF_ALL(s_axi, logic [31:0], logic [SUB_ID_WIDTH-1:0], logic [63:0], logic [7:0], logic [0:0]);

  s_axi_req_t  i3c_axi_req_slow, i3c_axi_req_fast;
  s_axi_resp_t i3c_axi_resp_slow, i3c_axi_resp_fast;

  logic i3c_recovery_payload_available_unused;
  logic i3c_recovery_image_activated_unused;
  logic i3c_peripheral_reset_unused;
  logic i3c_escalated_reset_unused;
  logic i3c_irq_unused;

  s_axi_req_t  uart_axi_req;
  s_axi_resp_t uart_axi_resp;

  // AXI Masters

  `AXI_TYPEDEF_ALL(lmem_axi, logic [16:0], logic [3:0], logic [63:0], logic [7:0], logic)
  lmem_axi_req_t  lmem_axi_req;
  lmem_axi_resp_t lmem_axi_resp;

  `AXI_TYPEDEF_ALL(ifu_axi, logic [31:0], logic [`RV_IFU_BUS_TAG-1:0], logic [63:0], logic [7:0], logic [0:0])
  ifu_axi_req_t  ifu_axi_req;
  ifu_axi_resp_t ifu_axi_resp;

  `AXI_TYPEDEF_ALL(lsu_axi, logic [31:0], logic [`RV_LSU_BUS_TAG-1:0], logic [63:0], logic [7:0], logic [0:0])
  lsu_axi_req_t  lsu_axi_req;
  lsu_axi_resp_t lsu_axi_resp;

  // AHB (uart)

  logic [               31:0] uart_ahb_haddr;
  logic [               63:0] uart_ahb_hwdata;
  logic                       uart_ahb_hsel;
  logic                       uart_ahb_hwrite;
  logic                       uart_ahb_hready;
  logic [                1:0] uart_ahb_htrans;
  logic [                2:0] uart_ahb_hsize;
  logic                       uart_ahb_hresp;
  logic                       uart_ahb_hreadyout;
  logic [               63:0] uart_ahb_hrdata;

  logic [               31:0] ahb_haddr_bridge_out;
  logic [                2:0] ahb_hsize_bridge_out;

  assign uart_ahb_hready = uart_ahb_hreadyout;
  assign uart_ahb_hsel   = '1;

  // When the hsize is 3'b11 then veer is asking for 32-bit unaligned data address but by doing that it alignes to 64 and expects
  // uart to return 2 x 32-bit data and then it would extract the part it needs.
  // To avoid this we explicitly request the 32 bit data from uart and set the size to 2'b10 so that uart returns 32-bit data.
  // TODO: Realize this using an AXI downsizer instead
  assign uart_ahb_haddr  = ahb_haddr_bridge_out + (ahb_hsize_bridge_out == 'b11 ? 'h4 : 0);
  assign uart_ahb_hsize  = ahb_hsize_bridge_out == 'b11 ? 'b10 : ahb_hsize_bridge_out;

  //=========================================================================-
  // RTL instances
  //=========================================================================-
  localparam unsigned [31:0] reset_vector = `RV_RESET_VEC;

  // Keep VeeR trace interface nets for debugging use.
  (* keep, dont_touch, mark_debug = "true" *)logic [31:0] trace_rv_i_insn;
  (* keep, dont_touch, mark_debug = "true" *)logic [31:0] trace_rv_i_address;
  (* keep, dont_touch, mark_debug = "true" *)logic        trace_rv_i_valid;
  (* keep, dont_touch, mark_debug = "true" *)logic        trace_rv_i_exception;
  (* keep, dont_touch, mark_debug = "true" *)logic [4:0]  trace_rv_i_ecause;
  (* keep, dont_touch, mark_debug = "true" *)logic        trace_rv_i_interrupt;
  (* keep, dont_touch, mark_debug = "true" *)logic [31:0] trace_rv_i_tval;

  el2_veer_wrapper rvtop_wrapper (
      .clk      (clk_i),
      .rst_l    (cpu_rst_ni),
      .dbg_rst_l(),
`ifndef GUINEVEER_TESTBENCH
      .rst_vec  (reset_vector[31:1]),
      .nmi_int  (),
      .nmi_vec  (),
      .jtag_id  (),
`else
      .rst_vec  (reset_vector_i),
      .nmi_int  (nmi_int_i),
      .nmi_vec  (nmi_vector_i),
      .jtag_id  (jtag_id_i),
`endif

      //-------------------------- LSU AXI signals--------------------------
      // AXI Write Channels
      .lsu_axi_awvalid (lsu_axi_req.aw_valid),
      .lsu_axi_awready (lsu_axi_resp.aw_ready),
      .lsu_axi_awid    (lsu_axi_req.aw.id),
      .lsu_axi_awaddr  (lsu_axi_req.aw.addr),
      .lsu_axi_awregion(lsu_axi_req.aw.region),
      .lsu_axi_awlen   (lsu_axi_req.aw.len),
      .lsu_axi_awsize  (lsu_axi_req.aw.size),
      .lsu_axi_awburst (lsu_axi_req.aw.burst),
      .lsu_axi_awlock  (lsu_axi_req.aw.lock),
      .lsu_axi_awcache (lsu_axi_req.aw.cache),
      .lsu_axi_awprot  (lsu_axi_req.aw.prot),
      .lsu_axi_awqos   (lsu_axi_req.aw.qos),

      .lsu_axi_wvalid(lsu_axi_req.w_valid),
      .lsu_axi_wready(lsu_axi_resp.w_ready),
      .lsu_axi_wdata (lsu_axi_req.w.data),
      .lsu_axi_wstrb (lsu_axi_req.w.strb),
      .lsu_axi_wlast (lsu_axi_req.w.last),

      .lsu_axi_bvalid(lsu_axi_resp.b_valid),
      .lsu_axi_bready(lsu_axi_req.b_ready),
      .lsu_axi_bresp (lsu_axi_resp.b.resp),
      .lsu_axi_bid   (lsu_axi_resp.b.id),

      .lsu_axi_arvalid (lsu_axi_req.ar_valid),
      .lsu_axi_arready (lsu_axi_resp.ar_ready),
      .lsu_axi_arid    (lsu_axi_req.ar.id),
      .lsu_axi_araddr  (lsu_axi_req.ar.addr),
      .lsu_axi_arregion(lsu_axi_req.ar.region),
      .lsu_axi_arlen   (lsu_axi_req.ar.len),
      .lsu_axi_arsize  (lsu_axi_req.ar.size),
      .lsu_axi_arburst (lsu_axi_req.ar.burst),
      .lsu_axi_arlock  (lsu_axi_req.ar.lock),
      .lsu_axi_arcache (lsu_axi_req.ar.cache),
      .lsu_axi_arprot  (lsu_axi_req.ar.prot),
      .lsu_axi_arqos   (lsu_axi_req.ar.qos),

      .lsu_axi_rvalid(lsu_axi_resp.r_valid),
      .lsu_axi_rready(lsu_axi_req.r_ready),
      .lsu_axi_rid   (lsu_axi_resp.r.id),
      .lsu_axi_rdata (lsu_axi_resp.r.data),
      .lsu_axi_rresp (lsu_axi_resp.r.resp),
      .lsu_axi_rlast (lsu_axi_resp.r.last),

      //-------------------------- IFU AXI signals--------------------------
      // AXI Write Channels
      .ifu_axi_awvalid (ifu_axi_req.aw_valid),
      .ifu_axi_awready (ifu_axi_resp.aw_ready),
      .ifu_axi_awid    (ifu_axi_req.aw.id),
      .ifu_axi_awaddr  (ifu_axi_req.aw.addr),
      .ifu_axi_awregion(ifu_axi_req.aw.region),
      .ifu_axi_awlen   (ifu_axi_req.aw.len),
      .ifu_axi_awsize  (ifu_axi_req.aw.size),
      .ifu_axi_awburst (ifu_axi_req.aw.burst),
      .ifu_axi_awlock  (ifu_axi_req.aw.lock),
      .ifu_axi_awcache (ifu_axi_req.aw.cache),
      .ifu_axi_awprot  (ifu_axi_req.aw.prot),
      .ifu_axi_awqos   (ifu_axi_req.aw.qos),

      .ifu_axi_wvalid(ifu_axi_req.w_valid),
      .ifu_axi_wready(ifu_axi_resp.w_ready),
      .ifu_axi_wdata (ifu_axi_req.w.data),
      .ifu_axi_wstrb (ifu_axi_req.w.strb),
      .ifu_axi_wlast (ifu_axi_req.w.last),

      .ifu_axi_bvalid(ifu_axi_resp.b_valid),
      .ifu_axi_bready(ifu_axi_req.b_ready),
      .ifu_axi_bresp (ifu_axi_resp.b.resp),
      .ifu_axi_bid   (ifu_axi_resp.b.id),

      .ifu_axi_arvalid (ifu_axi_req.ar_valid),
      .ifu_axi_arready (ifu_axi_resp.ar_ready),
      .ifu_axi_arid    (ifu_axi_req.ar.id),
      .ifu_axi_araddr  (ifu_axi_req.ar.addr),
      .ifu_axi_arregion(ifu_axi_req.ar.region),
      .ifu_axi_arlen   (ifu_axi_req.ar.len),
      .ifu_axi_arsize  (ifu_axi_req.ar.size),
      .ifu_axi_arburst (ifu_axi_req.ar.burst),
      .ifu_axi_arlock  (ifu_axi_req.ar.lock),
      .ifu_axi_arcache (ifu_axi_req.ar.cache),
      .ifu_axi_arprot  (ifu_axi_req.ar.prot),
      .ifu_axi_arqos   (ifu_axi_req.ar.qos),

      .ifu_axi_rvalid(ifu_axi_resp.r_valid),
      .ifu_axi_rready(ifu_axi_req.r_ready),
      .ifu_axi_rid   (ifu_axi_resp.r.id),
      .ifu_axi_rdata (ifu_axi_resp.r.data),
      .ifu_axi_rresp (ifu_axi_resp.r.resp),
      .ifu_axi_rlast (ifu_axi_resp.r.last),

      //-------------------------- SB AXI signals--------------------------
      // AXI Write Channels
      .sb_axi_awvalid (),
      .sb_axi_awready (),
      .sb_axi_awid    (),
      .sb_axi_awaddr  (),
      .sb_axi_awregion(),
      .sb_axi_awlen   (),
      .sb_axi_awsize  (),
      .sb_axi_awburst (),
      .sb_axi_awlock  (),
      .sb_axi_awcache (),
      .sb_axi_awprot  (),
      .sb_axi_awqos   (),

      .sb_axi_wvalid(),
      .sb_axi_wready(),
      .sb_axi_wdata (),
      .sb_axi_wstrb (),
      .sb_axi_wlast (),

      .sb_axi_bvalid(),
      .sb_axi_bready(),
      .sb_axi_bresp (),
      .sb_axi_bid   (),


      .sb_axi_arvalid (),
      .sb_axi_arready (),
      .sb_axi_arid    (),
      .sb_axi_araddr  (),
      .sb_axi_arregion(),
      .sb_axi_arlen   (),
      .sb_axi_arsize  (),
      .sb_axi_arburst (),
      .sb_axi_arlock  (),
      .sb_axi_arcache (),
      .sb_axi_arprot  (),
      .sb_axi_arqos   (),

      .sb_axi_rvalid(),
      .sb_axi_rready(),
      .sb_axi_rid   (),
      .sb_axi_rdata (),
      .sb_axi_rresp (),
      .sb_axi_rlast (),

      //-------------------------- DMA AXI signals--------------------------
      // AXI Write Channels
      .dma_axi_awvalid(),
      .dma_axi_awready(),
      .dma_axi_awid   (),
      .dma_axi_awaddr (),
      .dma_axi_awsize (),
      .dma_axi_awprot (),
      .dma_axi_awlen  (),
      .dma_axi_awburst(),

      .dma_axi_wvalid(),
      .dma_axi_wready(),
      .dma_axi_wdata (),
      .dma_axi_wstrb (),
      .dma_axi_wlast (),

      .dma_axi_bvalid(),
      .dma_axi_bready(),
      .dma_axi_bresp (),
      .dma_axi_bid   (),

      .dma_axi_arvalid(),
      .dma_axi_arready(),
      .dma_axi_arid   (),
      .dma_axi_araddr (),
      .dma_axi_arsize (),
      .dma_axi_arprot (),
      .dma_axi_arlen  (),
      .dma_axi_arburst(),

      .dma_axi_rvalid(),
      .dma_axi_rready(),
      .dma_axi_rid   (),
      .dma_axi_rdata (),
      .dma_axi_rresp (),
      .dma_axi_rlast (),

      .extintsrc_req(),

      .lsu_bus_clk_en(1'b1),  // Clock ratio b/w cpu core clk & AHB master interface
      .ifu_bus_clk_en(1'b1),  // Clock ratio b/w cpu core clk & AHB master interface
      .dbg_bus_clk_en(1'b1),  // Clock ratio b/w cpu core clk & AHB Debug master interface
      .dma_bus_clk_en(1'b0),  // Clock ratio b/w cpu core clk & AHB slave interface

      .trace_rv_i_insn_ip     (trace_rv_i_insn),
      .trace_rv_i_address_ip  (trace_rv_i_address),
      .trace_rv_i_valid_ip    (trace_rv_i_valid),
      .trace_rv_i_exception_ip(trace_rv_i_exception),
      .trace_rv_i_ecause_ip   (trace_rv_i_ecause),
      .trace_rv_i_interrupt_ip(trace_rv_i_interrupt),
      .trace_rv_i_tval_ip     (trace_rv_i_tval),

      .jtag_tck   (),
      .jtag_tms   (),
      .jtag_tdi   (),
      .jtag_trst_n(),
      .jtag_tdo   (),
      .jtag_tdoEn (),

`ifndef GUINEVEER_TESTBENCH
      .timer_int         (),
      .mpc_debug_halt_ack(),
      .mpc_debug_halt_req(0),
      .mpc_debug_run_ack (),
      .mpc_debug_run_req (0),
      .mpc_reset_run_req (1'b1),  // Start running after reset
      .debug_brkpt_status(),

      .i_cpu_halt_req     (0),                     // Async halt req to CPU
      .o_cpu_halt_ack     (),                      // core response to halt
      .o_cpu_halt_status  (),                      // 1'b1 indicates core is halted
      .i_cpu_run_req      (0),                     // Async restart req to CPU
      .o_debug_mode_status(),
      .o_cpu_run_ack      (),                      // Core response to run req
      .soft_int           (0),
`else
      .timer_int          (timer_int_i),
      .mpc_debug_halt_ack (mpc_debug_halt_ack_o),
      .mpc_debug_halt_req (mpc_debug_halt_req_i),
      .mpc_debug_run_ack  (mpc_debug_run_ack_o),
      .mpc_debug_run_req  (mpc_debug_run_req_i),
      .mpc_reset_run_req  (1'b1),                  // Start running after reset
      .debug_brkpt_status (),

      .i_cpu_halt_req     (cpu_halt_req_i),       // Async halt req to CPU
      .o_cpu_halt_ack     (cpu_halt_ack_o),       // core response to halt
      .o_cpu_halt_status  (cpu_halt_status_o),    // 1'b1 indicates core is halted
      .i_cpu_run_req      (cpu_run_req_i),        // Async restart req to CPU
      .o_debug_mode_status(debug_mode_status_o),
      .o_cpu_run_ack      (cpu_run_ack_o),        // Core response to run req
      .soft_int           (soft_int_i),
`endif

      .dec_tlu_perfcnt0(),
      .dec_tlu_perfcnt1(),
      .dec_tlu_perfcnt2(),
      .dec_tlu_perfcnt3(),

      .el2_mem_export(el2_mem_export),
      .el2_icache_export(el2_mem_export),

      .iccm_ecc_single_error(),
      .iccm_ecc_double_error(),
      .dccm_ecc_single_error(),
      .dccm_ecc_double_error(),

      .core_id   ('0),
      .scan_mode (1'b0),  // To enable scan mode
      .mbist_mode(1'b0),  // to enable mbist

      .dmi_core_enable  (),
      .dmi_uncore_enable(),
      .dmi_uncore_en    (),
      .dmi_uncore_wr_en (),
      .dmi_uncore_addr  (),
      .dmi_uncore_wdata (),
      .dmi_uncore_rdata (),
      .dmi_active       ()

  );

  axi_intercon #() axi_interconnect (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      .i_veer_lsu_awid(lsu_axi_req.aw.id),
      .i_veer_lsu_awaddr(lsu_axi_req.aw.addr),
      .i_veer_lsu_awlen(lsu_axi_req.aw.len),
      .i_veer_lsu_awsize(lsu_axi_req.aw.size),
      .i_veer_lsu_awburst(lsu_axi_req.aw.burst),
      .i_veer_lsu_awlock(lsu_axi_req.aw.lock),
      .i_veer_lsu_awcache(lsu_axi_req.aw.cache),
      .i_veer_lsu_awprot(lsu_axi_req.aw.prot),
      .i_veer_lsu_awregion(lsu_axi_req.aw.region),
      .i_veer_lsu_awqos(lsu_axi_req.aw.qos),
      .i_veer_lsu_awvalid(lsu_axi_req.aw_valid),
      .o_veer_lsu_awready(lsu_axi_resp.aw_ready),
      .i_veer_lsu_arid(lsu_axi_req.ar.id),
      .i_veer_lsu_araddr(lsu_axi_req.ar.addr),
      .i_veer_lsu_arlen(lsu_axi_req.ar.len),
      .i_veer_lsu_arsize(lsu_axi_req.ar.size),
      .i_veer_lsu_arburst(lsu_axi_req.ar.burst),
      .i_veer_lsu_arlock(lsu_axi_req.ar.lock),
      .i_veer_lsu_arcache(lsu_axi_req.ar.cache),
      .i_veer_lsu_arprot(lsu_axi_req.ar.prot),
      .i_veer_lsu_arregion(lsu_axi_req.ar.region),
      .i_veer_lsu_arqos(lsu_axi_req.ar.qos),
      .i_veer_lsu_arvalid(lsu_axi_req.ar_valid),
      .o_veer_lsu_arready(lsu_axi_resp.ar_ready),
      .i_veer_lsu_wdata(lsu_axi_req.w.data),
      .i_veer_lsu_wstrb(lsu_axi_req.w.strb),
      .i_veer_lsu_wlast(lsu_axi_req.w.last),
      .i_veer_lsu_wvalid(lsu_axi_req.w_valid),
      .o_veer_lsu_wready(lsu_axi_resp.w_ready),
      .o_veer_lsu_bid(lsu_axi_resp.b.id),
      .o_veer_lsu_bresp(lsu_axi_resp.b.resp),
      .o_veer_lsu_bvalid(lsu_axi_resp.b_valid),
      .i_veer_lsu_bready(lsu_axi_req.b_ready),
      .o_veer_lsu_rid(lsu_axi_resp.r.id),
      .o_veer_lsu_rdata(lsu_axi_resp.r.data),
      .o_veer_lsu_rresp(lsu_axi_resp.r.resp),
      .o_veer_lsu_rlast(lsu_axi_resp.r.last),
      .o_veer_lsu_rvalid(lsu_axi_resp.r_valid),
      .i_veer_lsu_rready(lsu_axi_req.r_ready),

      .i_veer_ifu_awid(ifu_axi_req.aw.id),
      .i_veer_ifu_awaddr(ifu_axi_req.aw.addr),
      .i_veer_ifu_awlen(ifu_axi_req.aw.len),
      .i_veer_ifu_awsize(ifu_axi_req.aw.size),
      .i_veer_ifu_awburst(ifu_axi_req.aw.burst),
      .i_veer_ifu_awlock(ifu_axi_req.aw.lock),
      .i_veer_ifu_awcache(ifu_axi_req.aw.cache),
      .i_veer_ifu_awprot(ifu_axi_req.aw.prot),
      .i_veer_ifu_awregion(ifu_axi_req.aw.region),
      .i_veer_ifu_awqos(ifu_axi_req.aw.qos),
      .i_veer_ifu_awvalid(ifu_axi_req.aw_valid),
      .o_veer_ifu_awready(ifu_axi_resp.aw_ready),
      .i_veer_ifu_arid(ifu_axi_req.ar.id),
      .i_veer_ifu_araddr(ifu_axi_req.ar.addr),
      .i_veer_ifu_arlen(ifu_axi_req.ar.len),
      .i_veer_ifu_arsize(ifu_axi_req.ar.size),
      .i_veer_ifu_arburst(ifu_axi_req.ar.burst),
      .i_veer_ifu_arlock(ifu_axi_req.ar.lock),
      .i_veer_ifu_arcache(ifu_axi_req.ar.cache),
      .i_veer_ifu_arprot(ifu_axi_req.ar.prot),
      .i_veer_ifu_arregion(ifu_axi_req.ar.region),
      .i_veer_ifu_arqos(ifu_axi_req.ar.qos),
      .i_veer_ifu_arvalid(ifu_axi_req.ar_valid),
      .o_veer_ifu_arready(ifu_axi_resp.ar_ready),
      .i_veer_ifu_wdata(ifu_axi_req.w.data),
      .i_veer_ifu_wstrb(ifu_axi_req.w.strb),
      .i_veer_ifu_wlast(ifu_axi_req.w.last),
      .i_veer_ifu_wvalid(ifu_axi_req.w_valid),
      .o_veer_ifu_wready(ifu_axi_resp.w_ready),
      .o_veer_ifu_bid(ifu_axi_resp.b.id),
      .o_veer_ifu_bresp(ifu_axi_resp.b.resp),
      .o_veer_ifu_bvalid(ifu_axi_resp.b_valid),
      .i_veer_ifu_bready(ifu_axi_req.b_ready),
      .o_veer_ifu_rid(ifu_axi_resp.r.id),
      .o_veer_ifu_rdata(ifu_axi_resp.r.data),
      .o_veer_ifu_rresp(ifu_axi_resp.r.resp),
      .o_veer_ifu_rlast(ifu_axi_resp.r.last),
      .o_veer_ifu_rvalid(ifu_axi_resp.r_valid),
      .i_veer_ifu_rready(ifu_axi_req.r_ready),

      .o_mem_awid(lmem_axi_req.aw.id),
      .o_mem_awaddr(lmem_axi_req.aw.addr),
      .o_mem_awlen(lmem_axi_req.aw.len),
      .o_mem_awsize(lmem_axi_req.aw.size),
      .o_mem_awburst(lmem_axi_req.aw.burst),
      .o_mem_awlock(lmem_axi_req.aw.lock),
      .o_mem_awcache(lmem_axi_req.aw.cache),
      .o_mem_awprot(lmem_axi_req.aw.prot),
      .o_mem_awregion(lmem_axi_req.aw.region),
      .o_mem_awqos(lmem_axi_req.aw.qos),
      .o_mem_awvalid(lmem_axi_req.aw_valid),
      .i_mem_awready(lmem_axi_resp.aw_ready),
      .o_mem_arid(lmem_axi_req.ar.id),
      .o_mem_araddr(lmem_axi_req.ar.addr),
      .o_mem_arlen(lmem_axi_req.ar.len),
      .o_mem_arsize(lmem_axi_req.ar.size),
      .o_mem_arburst(lmem_axi_req.ar.burst),
      .o_mem_arlock(lmem_axi_req.ar.lock),
      .o_mem_arcache(lmem_axi_req.ar.cache),
      .o_mem_arprot(lmem_axi_req.ar.prot),
      .o_mem_arregion(lmem_axi_req.ar.region),
      .o_mem_arqos(lmem_axi_req.ar.qos),
      .o_mem_arvalid(lmem_axi_req.ar_valid),
      .i_mem_arready(lmem_axi_resp.ar_ready),
      .o_mem_wdata(lmem_axi_req.w.data),
      .o_mem_wstrb(lmem_axi_req.w.strb),
      .o_mem_wlast(lmem_axi_req.w.last),
      .o_mem_wvalid(lmem_axi_req.w_valid),
      .i_mem_wready(lmem_axi_resp.w_ready),
      .i_mem_bid(lmem_axi_resp.b.id),
      .i_mem_bresp(lmem_axi_resp.b.resp),
      .i_mem_bvalid(lmem_axi_resp.b_valid),
      .o_mem_bready(lmem_axi_req.b_ready),
      .i_mem_rid(lmem_axi_resp.r.id),
      .i_mem_rdata(lmem_axi_resp.r.data),
      .i_mem_rresp(lmem_axi_resp.r.resp),
      .i_mem_rlast(lmem_axi_resp.r.last),
      .i_mem_rvalid(lmem_axi_resp.r_valid),
      .o_mem_rready(lmem_axi_req.r_ready),

      .o_uart_awid(uart_axi_req.aw.id),
      .o_uart_awaddr(uart_axi_req.aw.addr),
      .o_uart_awlen(uart_axi_req.aw.len),
      .o_uart_awsize(uart_axi_req.aw.size),
      .o_uart_awburst(uart_axi_req.aw.burst),
      .o_uart_awlock(uart_axi_req.aw.lock),
      .o_uart_awcache(uart_axi_req.aw.cache),
      .o_uart_awprot(uart_axi_req.aw.prot),
      .o_uart_awregion(uart_axi_req.aw.region),
      .o_uart_awqos(uart_axi_req.aw.qos),
      .o_uart_awvalid(uart_axi_req.aw_valid),
      .i_uart_awready(uart_axi_resp.aw_ready),
      .o_uart_arid(uart_axi_req.ar.id),
      .o_uart_araddr(uart_axi_req.ar.addr),
      .o_uart_arlen(uart_axi_req.ar.len),
      .o_uart_arsize(uart_axi_req.ar.size),
      .o_uart_arburst(uart_axi_req.ar.burst),
      .o_uart_arlock(uart_axi_req.ar.lock),
      .o_uart_arcache(uart_axi_req.ar.cache),
      .o_uart_arprot(uart_axi_req.ar.prot),
      .o_uart_arregion(uart_axi_req.ar.region),
      .o_uart_arqos(uart_axi_req.ar.qos),
      .o_uart_arvalid(uart_axi_req.ar_valid),
      .i_uart_arready(uart_axi_resp.ar_ready),
      .o_uart_wdata(uart_axi_req.w.data),
      .o_uart_wstrb(uart_axi_req.w.strb),
      .o_uart_wlast(uart_axi_req.w.last),
      .o_uart_wvalid(uart_axi_req.w_valid),
      .i_uart_wready(uart_axi_resp.w_ready),
      .i_uart_bid(uart_axi_resp.b.id),
      .i_uart_bresp(uart_axi_resp.b.resp),
      .i_uart_bvalid(uart_axi_resp.b_valid),
      .o_uart_bready(uart_axi_req.b_ready),
      .i_uart_rid(uart_axi_resp.r.id),
      .i_uart_rdata(uart_axi_resp.r.data),
      .i_uart_rresp(uart_axi_resp.r.resp),
      .i_uart_rlast(uart_axi_resp.r.last),
      .i_uart_rvalid(uart_axi_resp.r_valid),
      .o_uart_rready(uart_axi_req.r_ready),

      .o_i3c_awid(i3c_axi_req_slow.aw.id),
      .o_i3c_awaddr(i3c_axi_req_slow.aw.addr),
      .o_i3c_awlen(i3c_axi_req_slow.aw.len),
      .o_i3c_awsize(i3c_axi_req_slow.aw.size),
      .o_i3c_awburst(i3c_axi_req_slow.aw.burst),
      .o_i3c_awlock(i3c_axi_req_slow.aw.lock),
      .o_i3c_awcache(i3c_axi_req_slow.aw.cache),
      .o_i3c_awprot(i3c_axi_req_slow.aw.prot),
      .o_i3c_awregion(i3c_axi_req_slow.aw.region),
      .o_i3c_awqos(i3c_axi_req_slow.aw.qos),
      .o_i3c_awvalid(i3c_axi_req_slow.aw_valid),
      .i_i3c_awready(i3c_axi_resp_slow.aw_ready),
      .o_i3c_arid(i3c_axi_req_slow.ar.id),
      .o_i3c_araddr(i3c_axi_req_slow.ar.addr),
      .o_i3c_arlen(i3c_axi_req_slow.ar.len),
      .o_i3c_arsize(i3c_axi_req_slow.ar.size),
      .o_i3c_arburst(i3c_axi_req_slow.ar.burst),
      .o_i3c_arlock(i3c_axi_req_slow.ar.lock),
      .o_i3c_arcache(i3c_axi_req_slow.ar.cache),
      .o_i3c_arprot(i3c_axi_req_slow.ar.prot),
      .o_i3c_arregion(i3c_axi_req_slow.ar.region),
      .o_i3c_arqos(i3c_axi_req_slow.ar.qos),
      .o_i3c_arvalid(i3c_axi_req_slow.ar_valid),
      .i_i3c_arready(i3c_axi_resp_slow.ar_ready),
      .o_i3c_wdata(i3c_axi_req_slow.w.data),
      .o_i3c_wstrb(i3c_axi_req_slow.w.strb),
      .o_i3c_wlast(i3c_axi_req_slow.w.last),
      .o_i3c_wvalid(i3c_axi_req_slow.w_valid),
      .i_i3c_wready(i3c_axi_resp_slow.w_ready),
      .i_i3c_bid(i3c_axi_resp_slow.b.id),
      .i_i3c_bresp(i3c_axi_resp_slow.b.resp),
      .i_i3c_bvalid(i3c_axi_resp_slow.b_valid),
      .o_i3c_bready(i3c_axi_req_slow.b_ready),
      .i_i3c_rid(i3c_axi_resp_slow.r.id),
      .i_i3c_rdata(i3c_axi_resp_slow.r.data),
      .i_i3c_rresp(i3c_axi_resp_slow.r.resp),
      .i_i3c_rlast(i3c_axi_resp_slow.r.last),
      .i_i3c_rvalid(i3c_axi_resp_slow.r_valid),
      .o_i3c_rready(i3c_axi_req_slow.r_ready)
  );

  guineveer_sram #(
      .ADDR_WIDTH($bits(lmem_axi_req.aw.addr)),
      .DATA_WIDTH($bits(lmem_axi_req.w.data)),
      .ID_WIDTH  (SUB_ID_WIDTH),
      .AXI_REQ_T (lmem_axi_req_t),
      .AXI_RESP_T(lmem_axi_resp_t)
  ) lmem (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .axi_req_i(lmem_axi_req),
      .axi_resp_o(lmem_axi_resp)
  );

  axi4_to_ahb #(
      .TAG(SUB_ID_WIDTH)
  ) axi_bridge (
      .clk(clk_i),
      .free_clk(clk_i),
      .rst_l(rst_ni),

      .scan_mode(0),

      .bus_clk_en(1),
      .clk_override(0),
      .dec_tlu_force_halt(0),

      .axi_awvalid(uart_axi_req.aw_valid),
      .axi_awready(uart_axi_resp.aw_ready),
      .axi_awid(uart_axi_req.aw.id),
      .axi_awaddr(uart_axi_req.aw.addr),
      .axi_awsize(uart_axi_req.aw.size),
      .axi_awprot(uart_axi_req.aw.prot),
      .axi_wvalid(uart_axi_req.w_valid),
      .axi_wready(uart_axi_resp.w_ready),
      .axi_wdata(uart_axi_req.w.data),
      .axi_wstrb(uart_axi_req.w.strb),
      .axi_wlast(uart_axi_req.w.last),
      .axi_bvalid(uart_axi_resp.b_valid),
      .axi_bready(uart_axi_req.b_ready),
      .axi_bresp(uart_axi_resp.b.resp),
      .axi_bid(uart_axi_resp.b.id),
      .axi_arvalid(uart_axi_req.ar_valid),
      .axi_arready(uart_axi_resp.ar_ready),
      .axi_arid(uart_axi_req.ar.id),
      .axi_araddr(uart_axi_req.ar.addr),
      .axi_arsize(uart_axi_req.ar.size),
      .axi_arprot(uart_axi_req.ar.prot),
      .axi_rvalid(uart_axi_resp.r_valid),
      .axi_rready(uart_axi_req.r_ready),
      .axi_rid(uart_axi_resp.r.id),
      .axi_rdata(uart_axi_resp.r.data),
      .axi_rresp(uart_axi_resp.r.resp),
      .axi_rlast(uart_axi_resp.r.last),

      .ahb_haddr(ahb_haddr_bridge_out),
      .ahb_hburst(),
      .ahb_hmastlock(),
      .ahb_hprot(),
      .ahb_hsize(ahb_hsize_bridge_out),
      .ahb_htrans(uart_ahb_htrans),
      .ahb_hwrite(uart_ahb_hwrite),
      .ahb_hwdata(uart_ahb_hwdata),
      .ahb_hrdata(uart_ahb_hrdata),
      .ahb_hready(uart_ahb_hready),
      .ahb_hresp(uart_ahb_hresp)
  );

  uart #(
      .AHBAddrWidth($bits(uart_ahb_haddr)),
      .AHBDataWidth(64)
  ) uart_core (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      .cio_rx_i(uart_rx_i),
      .cio_tx_o(uart_tx_o),

      .haddr_i    (uart_ahb_haddr),
      .hwdata_i   (uart_ahb_hwdata),
      .hsel_i     (uart_ahb_hsel),
      .hwrite_i   (uart_ahb_hwrite),
      .hready_i   (uart_ahb_hready),
      .htrans_i   (uart_ahb_htrans),
      .hsize_i    (uart_ahb_hsize),
      .hresp_o    (uart_ahb_hresp),
      .hreadyout_o(uart_ahb_hreadyout),
      .hrdata_o   (uart_ahb_hrdata),

      .alert_rx_i(),
      .alert_tx_o(),

      .cio_tx_en_o(),

      .intr_tx_watermark_o (),
      .intr_rx_watermark_o (),
      .intr_tx_empty_o     (),
      .intr_rx_overflow_o  (),
      .intr_rx_frame_err_o (),
      .intr_rx_break_err_o (),
      .intr_rx_timeout_o   (),
      .intr_rx_parity_err_o()
  );

  axi_cdc #(
    .aw_chan_t  (s_axi_aw_chan_t),
    .w_chan_t   (s_axi_w_chan_t),
    .b_chan_t   (s_axi_b_chan_t),
    .ar_chan_t  (s_axi_ar_chan_t),
    .r_chan_t   (s_axi_r_chan_t),
    .axi_req_t  (s_axi_req_t),
    .axi_resp_t (s_axi_resp_t)
  ) i_axi_cdc_lsu (
    .src_clk_i  (clk_i),
    .src_rst_ni (rst_ni),
    .src_req_i  (i3c_axi_req_slow),
    .src_resp_o (i3c_axi_resp_slow),
    .dst_clk_i  (i3c_clk_i),
    .dst_rst_ni (i3c_rst_ni),
    .dst_req_o  (i3c_axi_req_fast),
    .dst_resp_i (i3c_axi_resp_fast)
  );

  i3c_wrapper #(
      .AxiAddrWidth($bits(i3c_axi_req_fast.aw.addr)),
      .AxiDataWidth(64),
      .AxiUserWidth(1),
      .AxiIdWidth  (SUB_ID_WIDTH)
  ) i3c_core (
      .clk_i (i3c_clk_i),
      .rst_ni(i3c_rst_ni),

      .araddr_i(i3c_axi_req_fast.ar.addr),
      .arburst_i(i3c_axi_req_fast.ar.burst),
      .arsize_i(i3c_axi_req_fast.ar.size),
      .arlen_i(i3c_axi_req_fast.ar.len),
      .aruser_i(i3c_axi_req_fast.ar.user),
      .arid_i(i3c_axi_req_fast.ar.id),
      .arlock_i(i3c_axi_req_fast.ar.lock),
      .arvalid_i(i3c_axi_req_fast.ar_valid),
      .arready_o(i3c_axi_resp_fast.ar_ready),

      .rdata_o(i3c_axi_resp_fast.r.data),
      .rresp_o(i3c_axi_resp_fast.r.resp),
      .rid_o(i3c_axi_resp_fast.r.id),
      .ruser_o(i3c_axi_resp_fast.r.user),
      .rlast_o(i3c_axi_resp_fast.r.last),
      .rvalid_o(i3c_axi_resp_fast.r_valid),
      .rready_i(i3c_axi_req_fast.r_ready),

      .awaddr_i(i3c_axi_req_fast.aw.addr),
      .awburst_i(i3c_axi_req_fast.aw.burst),
      .awsize_i(i3c_axi_req_fast.aw.size),
      .awlen_i(i3c_axi_req_fast.aw.len),
      .awuser_i(i3c_axi_req_fast.aw.user),
      .awid_i(i3c_axi_req_fast.aw.id),
      .awlock_i(i3c_axi_req_fast.aw.lock),
      .awvalid_i(i3c_axi_req_fast.aw_valid),
      .awready_o(i3c_axi_resp_fast.aw_ready),

      .wdata_i (i3c_axi_req_fast.w.data),
      .wstrb_i (i3c_axi_req_fast.w.strb),
      .wuser_i (i3c_axi_req_fast.w.user),
      .wlast_i (i3c_axi_req_fast.w.last),
      .wvalid_i(i3c_axi_req_fast.w_valid),
      .wready_o(i3c_axi_resp_fast.w_ready),

      .bresp_o(i3c_axi_resp_fast.b.resp),
      .bid_o(i3c_axi_resp_fast.b.id),
      .buser_o(i3c_axi_resp_fast.b.user),
      .bvalid_o(i3c_axi_resp_fast.b_valid),
      .bready_i(i3c_axi_req_fast.b_ready),

`ifdef DIGITAL_IO_I3C
      .sda_i(),
      .sda_o(),
      .scl_o(),
      .scl_i(),
      .sel_od_pp_o(),
`else
      .i3c_scl_io(i3c_scl_io),
      .i3c_sda_io(i3c_sda_io),
`endif
      .recovery_payload_available_o(i3c_recovery_payload_available_unused),
      .recovery_image_activated_o  (i3c_recovery_image_activated_unused),

      .peripheral_reset_o(i3c_peripheral_reset_unused),
      .peripheral_reset_done_i('0),
      .escalated_reset_o(i3c_escalated_reset_unused),

      .irq_o(i3c_irq_unused)
  );

endmodule
