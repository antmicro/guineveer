// Copyright (c) 2025 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

module guineveer #(
    `include "el2_param.vh",
    // AXI ID width for subordinates = log2(n_managers) + manager_id_width_max
    localparam int SUB_ID_WIDTH = 4
) (
    input  bit clk_i,
    input  bit rst_ni,
    input  bit cpu_halt_req_i,       // Async halt req to CPU
    output bit cpu_halt_ack_o,       // core response to halt
    output bit cpu_halt_status_o,    // 1'b1 indicates core is halted
    input  bit cpu_run_req_i,        // Async restart req to CPU
    output bit cpu_run_ack_o,        // Core response to run req
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

    input  logic uart_rx_i,
    output logic uart_tx_o,

    input  logic scl_i,
    input  logic sda_i,
    output logic scl_o,
    output logic sda_o,
    output logic sel_od_pp_o,

    output logic [31:0] trace_rv_i_insn_ip_o,
    output logic [31:0] trace_rv_i_address_ip_o,
    output logic        trace_rv_i_valid_ip_o,
    output logic        trace_rv_i_exception_ip_o,
    output logic [ 4:0] trace_rv_i_ecause_ip_o,
    output logic        trace_rv_i_interrupt_ip_o,
    output logic [31:0] trace_rv_i_tval_ip_o
);

  el2_mem_if el2_mem_export ();

  //-------------------------- LSU AXI signals--------------------------
  // AXI Write Channels
  wire                       lsu_axi_awvalid;
  wire                       lsu_axi_awready;
  wire [`RV_LSU_BUS_TAG-1:0] lsu_axi_awid;
  wire [               31:0] lsu_axi_awaddr;
  wire [                3:0] lsu_axi_awregion;
  wire [                7:0] lsu_axi_awlen;
  wire [                2:0] lsu_axi_awsize;
  wire [                1:0] lsu_axi_awburst;
  wire                       lsu_axi_awlock;
  wire [                3:0] lsu_axi_awcache;
  wire [                2:0] lsu_axi_awprot;
  wire [                3:0] lsu_axi_awqos;

  wire                       lsu_axi_wvalid;
  wire                       lsu_axi_wready;
  wire [               63:0] lsu_axi_wdata;
  wire [                7:0] lsu_axi_wstrb;
  wire                       lsu_axi_wlast;

  wire                       lsu_axi_bvalid;
  wire                       lsu_axi_bready;
  wire [                1:0] lsu_axi_bresp;
  wire [`RV_LSU_BUS_TAG-1:0] lsu_axi_bid;

  // AXI Read Channels
  wire                       lsu_axi_arvalid;
  wire                       lsu_axi_arready;
  wire [`RV_LSU_BUS_TAG-1:0] lsu_axi_arid;
  wire [               31:0] lsu_axi_araddr;
  wire [                3:0] lsu_axi_arregion;
  wire [                7:0] lsu_axi_arlen;
  wire [                2:0] lsu_axi_arsize;
  wire [                1:0] lsu_axi_arburst;
  wire                       lsu_axi_arlock;
  wire [                3:0] lsu_axi_arcache;
  wire [                2:0] lsu_axi_arprot;
  wire [                3:0] lsu_axi_arqos;

  wire                       lsu_axi_rvalid;
  wire                       lsu_axi_rready;
  wire [`RV_LSU_BUS_TAG-1:0] lsu_axi_rid;
  wire [               63:0] lsu_axi_rdata;
  wire [                1:0] lsu_axi_rresp;
  wire                       lsu_axi_rlast;
  wire                       lsu_axi_awuser;
  wire                       lsu_axi_wuser;
  wire                       lsu_axi_buser;
  wire                       lsu_axi_aruser;
  wire                       lsu_axi_ruser;

  //-------------------------- IFU AXI signals--------------------------
  // AXI Write Channels
  wire                       ifu_axi_awvalid;
  wire                       ifu_axi_awready;
  wire [`RV_IFU_BUS_TAG-1:0] ifu_axi_awid;
  wire [               31:0] ifu_axi_awaddr;
  wire [                3:0] ifu_axi_awregion;
  wire [                7:0] ifu_axi_awlen;
  wire [                2:0] ifu_axi_awsize;
  wire [                1:0] ifu_axi_awburst;
  wire                       ifu_axi_awlock;
  wire [                3:0] ifu_axi_awcache;
  wire [                2:0] ifu_axi_awprot;
  wire [                3:0] ifu_axi_awqos;

  wire                       ifu_axi_wvalid;
  wire                       ifu_axi_wready;
  wire [               63:0] ifu_axi_wdata;
  wire [                7:0] ifu_axi_wstrb;
  wire                       ifu_axi_wlast;

  wire                       ifu_axi_bvalid;
  wire                       ifu_axi_bready;
  wire [                1:0] ifu_axi_bresp;
  wire [`RV_IFU_BUS_TAG-1:0] ifu_axi_bid;

  // AXI Read Channels
  wire                       ifu_axi_arvalid;
  wire                       ifu_axi_arready;
  wire [`RV_IFU_BUS_TAG-1:0] ifu_axi_arid;
  wire [               31:0] ifu_axi_araddr;
  wire [                3:0] ifu_axi_arregion;
  wire [                7:0] ifu_axi_arlen;
  wire [                2:0] ifu_axi_arsize;
  wire [                1:0] ifu_axi_arburst;
  wire                       ifu_axi_arlock;
  wire [                3:0] ifu_axi_arcache;
  wire [                2:0] ifu_axi_arprot;
  wire [                3:0] ifu_axi_arqos;

  wire                       ifu_axi_rvalid;
  wire                       ifu_axi_rready;
  wire [`RV_IFU_BUS_TAG-1:0] ifu_axi_rid;
  wire [               63:0] ifu_axi_rdata;
  wire [                1:0] ifu_axi_rresp;
  wire                       ifu_axi_rlast;

  //-------------------------- DMA AXI signals--------------------------
  // AXI Write Channels
  wire                       dma_axi_awvalid;
  wire                       dma_axi_awready;
  wire [`RV_DMA_BUS_TAG-1:0] dma_axi_awid;
  wire [               31:0] dma_axi_awaddr;
  wire [                2:0] dma_axi_awsize;
  wire [                2:0] dma_axi_awprot;
  wire [                7:0] dma_axi_awlen;
  wire [                1:0] dma_axi_awburst;


  wire                       dma_axi_wvalid;
  wire                       dma_axi_wready;
  wire [               63:0] dma_axi_wdata;
  wire [                7:0] dma_axi_wstrb;
  wire                       dma_axi_wlast;

  wire                       dma_axi_bvalid;
  wire                       dma_axi_bready;
  wire [                1:0] dma_axi_bresp;
  wire [`RV_DMA_BUS_TAG-1:0] dma_axi_bid;

  // AXI Read Channels
  wire                       dma_axi_arvalid;
  wire                       dma_axi_arready;
  wire [`RV_DMA_BUS_TAG-1:0] dma_axi_arid;
  wire [               31:0] dma_axi_araddr;
  wire [                2:0] dma_axi_arsize;
  wire [                2:0] dma_axi_arprot;
  wire [                7:0] dma_axi_arlen;
  wire [                1:0] dma_axi_arburst;

  wire                       dma_axi_rvalid;
  wire                       dma_axi_rready;
  wire [`RV_DMA_BUS_TAG-1:0] dma_axi_rid;
  wire [               63:0] dma_axi_rdata;
  wire [                1:0] dma_axi_rresp;
  wire                       dma_axi_rlast;

  //-------------------------- UART AXI signals--------------------------

  wire [   SUB_ID_WIDTH-1:0] uart_axi_awid;
  wire [               31:0] uart_axi_awaddr;
  wire [                7:0] uart_axi_awlen;
  wire [                2:0] uart_axi_awsize;
  wire [                1:0] uart_axi_awburst;
  wire                       uart_axi_awlock;
  wire [                3:0] uart_axi_awcache;
  wire [                2:0] uart_axi_awprot;
  wire [                3:0] uart_axi_awregion;
  wire [                3:0] uart_axi_awqos;
  wire                       uart_axi_awvalid;
  wire                       uart_axi_awready;

  wire [   SUB_ID_WIDTH-1:0] uart_axi_arid;
  wire [               31:0] uart_axi_araddr;
  wire [                7:0] uart_axi_arlen;
  wire [                2:0] uart_axi_arsize;
  wire [                1:0] uart_axi_arburst;
  wire                       uart_axi_arlock;
  wire [                3:0] uart_axi_arcache;
  wire [                2:0] uart_axi_arprot;
  wire [                3:0] uart_axi_arregion;
  wire [                3:0] uart_axi_arqos;
  wire                       uart_axi_arvalid;
  wire                       uart_axi_arready;

  wire [               63:0] uart_axi_wdata;
  wire [                7:0] uart_axi_wstrb;
  wire                       uart_axi_wlast;
  wire                       uart_axi_wvalid;
  wire                       uart_axi_wready;

  wire [   SUB_ID_WIDTH-1:0] uart_axi_bid;
  wire [                1:0] uart_axi_bresp;
  wire                       uart_axi_bvalid;
  wire                       uart_axi_bready;

  wire [   SUB_ID_WIDTH-1:0] uart_axi_rid;
  wire [               63:0] uart_axi_rdata;
  wire [                1:0] uart_axi_rresp;
  wire                       uart_axi_rlast;
  wire                       uart_axi_rvalid;
  wire                       uart_axi_rready;

  logic [              31:0] uart_ahb_haddr;
  logic [              63:0] uart_ahb_hwdata;
  logic                      uart_ahb_hsel;
  logic                      uart_ahb_hwrite;
  logic                      uart_ahb_hready;
  logic [               1:0] uart_ahb_htrans;
  logic [               2:0] uart_ahb_hsize;
  logic                      uart_ahb_hresp;
  logic                      uart_ahb_hreadyout;
  logic [              63:0] uart_ahb_hrdata;

  logic [              31:0] ahb_haddr_bridge_out;
  logic [               2:0] ahb_hsize_bridge_out;

  //-------------------------- I3C AXI signals--------------------------

  wire [   SUB_ID_WIDTH-1:0] i3c_axi_awid;
  wire [               31:0] i3c_axi_awaddr;
  wire [                7:0] i3c_axi_awlen;
  wire [                2:0] i3c_axi_awsize;
  wire [                1:0] i3c_axi_awburst;
  wire                       i3c_axi_awlock;
  wire [                3:0] i3c_axi_awcache;
  wire [                2:0] i3c_axi_awprot;
  wire [                3:0] i3c_axi_awregion;
  wire [                3:0] i3c_axi_awqos;
  wire                       i3c_axi_awvalid;
  wire                       i3c_axi_awready;

  wire [   SUB_ID_WIDTH-1:0] i3c_axi_arid;
  wire [               31:0] i3c_axi_araddr;
  wire [                7:0] i3c_axi_arlen;
  wire [                2:0] i3c_axi_arsize;
  wire [                1:0] i3c_axi_arburst;
  wire                       i3c_axi_arlock;
  wire [                3:0] i3c_axi_arcache;
  wire [                2:0] i3c_axi_arprot;
  wire [                3:0] i3c_axi_arregion;
  wire [                3:0] i3c_axi_arqos;
  wire                       i3c_axi_arvalid;
  wire                       i3c_axi_arready;

  wire [               63:0] i3c_axi_wdata;
  wire [                7:0] i3c_axi_wstrb;
  wire                       i3c_axi_wlast;
  wire                       i3c_axi_wvalid;
  wire                       i3c_axi_wready;

  wire [   SUB_ID_WIDTH-1:0] i3c_axi_bid;
  wire [                1:0] i3c_axi_bresp;
  wire [                0:0] i3c_axi_buser_unused;
  wire                       i3c_axi_bvalid;
  wire                       i3c_axi_bready;

  wire [   SUB_ID_WIDTH-1:0] i3c_axi_rid;
  wire [                0:0] i3c_axi_ruser_unused;
  wire [               63:0] i3c_axi_rdata;
  wire [                1:0] i3c_axi_rresp;
  wire                       i3c_axi_rlast;
  wire                       i3c_axi_rvalid;
  wire                       i3c_axi_rready;

  wire                       i3c_recovery_payload_available_unused;
  wire                       i3c_recovery_image_activated_unused;

  wire                       i3c_peripheral_reset_unused;
  wire                       i3c_escalated_reset_unused;

  wire                       i3c_irq_unused;

  `AXI_TYPEDEF_ALL(lmem_axi, logic [23:0], logic [3:0], logic [63:0], logic [7:0], logic)
  lmem_axi_req_t  lmem_axi_req;
  lmem_axi_resp_t lmem_axi_resp;

  // AHB loopback
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

      .axi_awvalid(uart_axi_awvalid),
      .axi_awready(uart_axi_awready),
      .axi_awid(uart_axi_awid),
      .axi_awaddr(uart_axi_awaddr),
      .axi_awsize(uart_axi_awsize),
      .axi_awprot(uart_axi_awprot),
      .axi_wvalid(uart_axi_wvalid),
      .axi_wready(uart_axi_wready),
      .axi_wdata(uart_axi_wdata),
      .axi_wstrb(uart_axi_wstrb),
      .axi_wlast(uart_axi_wlast),
      .axi_bvalid(uart_axi_bvalid),
      .axi_bready(uart_axi_bready),
      .axi_bresp(uart_axi_bresp),
      .axi_bid(uart_axi_bid),
      .axi_arvalid(uart_axi_arvalid),
      .axi_arready(uart_axi_arready),
      .axi_arid(uart_axi_arid),
      .axi_araddr(uart_axi_araddr),
      .axi_arsize(uart_axi_arsize),
      .axi_arprot(uart_axi_arprot),
      .axi_rvalid(uart_axi_rvalid),
      .axi_rready(uart_axi_rready),
      .axi_rid(uart_axi_rid),
      .axi_rdata(uart_axi_rdata),
      .axi_rresp(uart_axi_rresp),
      .axi_rlast(uart_axi_rlast),

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

  i3c_wrapper #(
      .AxiAddrWidth($bits(i3c_axi_awaddr)),
      .AxiDataWidth(64),
      .AxiUserWidth(1),
      .AxiIdWidth(SUB_ID_WIDTH)
  ) i3c_core (
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      .araddr_i(i3c_axi_araddr),
      .arburst_i(i3c_axi_arburst),
      .arsize_i(i3c_axi_arsize),
      .arlen_i(i3c_axi_arlen),
      .aruser_i('0),
      .arid_i(i3c_axi_arid),
      .arlock_i(i3c_axi_arlock),
      .arvalid_i(i3c_axi_arvalid),
      .arready_o(i3c_axi_arready),

      .rdata_o(i3c_axi_rdata),
      .rresp_o(i3c_axi_rresp),
      .rid_o(i3c_axi_rid),
      .ruser_o(i3c_axi_ruser_unused),
      .rlast_o(i3c_axi_rlast),
      .rvalid_o(i3c_axi_rvalid),
      .rready_i(i3c_axi_rready),

      .awaddr_i(i3c_axi_awaddr),
      .awburst_i(i3c_axi_awburst),
      .awsize_i(i3c_axi_awsize),
      .awlen_i(i3c_axi_awlen),
      .awuser_i('0),
      .awid_i(i3c_axi_awid),
      .awlock_i(i3c_axi_awlock),
      .awvalid_i(i3c_axi_awvalid),
      .awready_o(i3c_axi_awready),

      .wdata_i(i3c_axi_wdata),
      .wstrb_i(i3c_axi_wstrb),
      .wuser_i('0),
      .wlast_i(i3c_axi_wlast),
      .wvalid_i(i3c_axi_wvalid),
      .wready_o(i3c_axi_wready),

      .bresp_o(i3c_axi_bresp),
      .bid_o(i3c_axi_bid),
      .buser_o(i3c_axi_buser_unused),
      .bvalid_o(i3c_axi_bvalid),
      .bready_i(i3c_axi_bready),

      .scl_i(scl_i),
      .sda_i(sda_i),
      .scl_o(scl_o),
      .sda_o(sda_o),
      .sel_od_pp_o(sel_od_pp_o),

      .recovery_payload_available_o(i3c_recovery_payload_available_unused),
      .recovery_image_activated_o(i3c_recovery_image_activated_unused),

      .peripheral_reset_o(i3c_peripheral_reset_unused),
      .peripheral_reset_done_i('0),
      .escalated_reset_o(i3c_escalated_reset_unused),

      .irq_o(i3c_irq_unused)
  );

  el2_veer_wrapper rvtop_wrapper (
      .rst_l(rst_ni),
      .dbg_rst_l(),
      .clk      (clk_i),
      .rst_vec  (reset_vector_i),
      .nmi_int  (nmi_int_i),
      .nmi_vec  (nmi_vector_i),
      .jtag_id  (jtag_id_i),

      //-------------------------- LSU AXI signals--------------------------
      // AXI Write Channels
      .lsu_axi_awvalid (lsu_axi_awvalid),
      .lsu_axi_awready (lsu_axi_awready),
      .lsu_axi_awid    (lsu_axi_awid),
      .lsu_axi_awaddr  (lsu_axi_awaddr),
      .lsu_axi_awregion(lsu_axi_awregion),
      .lsu_axi_awlen   (lsu_axi_awlen),
      .lsu_axi_awsize  (lsu_axi_awsize),
      .lsu_axi_awburst (lsu_axi_awburst),
      .lsu_axi_awlock  (lsu_axi_awlock),
      .lsu_axi_awcache (lsu_axi_awcache),
      .lsu_axi_awprot  (lsu_axi_awprot),
      .lsu_axi_awqos   (lsu_axi_awqos),

      .lsu_axi_wvalid(lsu_axi_wvalid),
      .lsu_axi_wready(lsu_axi_wready),
      .lsu_axi_wdata (lsu_axi_wdata),
      .lsu_axi_wstrb (lsu_axi_wstrb),
      .lsu_axi_wlast (lsu_axi_wlast),

      .lsu_axi_bvalid(lsu_axi_bvalid),
      .lsu_axi_bready(lsu_axi_bready),
      .lsu_axi_bresp (lsu_axi_bresp),
      .lsu_axi_bid   (lsu_axi_bid),


      .lsu_axi_arvalid (lsu_axi_arvalid),
      .lsu_axi_arready (lsu_axi_arready),
      .lsu_axi_arid    (lsu_axi_arid),
      .lsu_axi_araddr  (lsu_axi_araddr),
      .lsu_axi_arregion(lsu_axi_arregion),
      .lsu_axi_arlen   (lsu_axi_arlen),
      .lsu_axi_arsize  (lsu_axi_arsize),
      .lsu_axi_arburst (lsu_axi_arburst),
      .lsu_axi_arlock  (lsu_axi_arlock),
      .lsu_axi_arcache (lsu_axi_arcache),
      .lsu_axi_arprot  (lsu_axi_arprot),
      .lsu_axi_arqos   (lsu_axi_arqos),

      .lsu_axi_rvalid(lsu_axi_rvalid),
      .lsu_axi_rready(lsu_axi_rready),
      .lsu_axi_rid   (lsu_axi_rid),
      .lsu_axi_rdata (lsu_axi_rdata),
      .lsu_axi_rresp (lsu_axi_rresp),
      .lsu_axi_rlast (lsu_axi_rlast),

      //-------------------------- IFU AXI signals--------------------------
      // AXI Write Channels
      .ifu_axi_awvalid (ifu_axi_awvalid),
      .ifu_axi_awready (ifu_axi_awready),
      .ifu_axi_awid    (ifu_axi_awid),
      .ifu_axi_awaddr  (ifu_axi_awaddr),
      .ifu_axi_awregion(ifu_axi_awregion),
      .ifu_axi_awlen   (ifu_axi_awlen),
      .ifu_axi_awsize  (ifu_axi_awsize),
      .ifu_axi_awburst (ifu_axi_awburst),
      .ifu_axi_awlock  (ifu_axi_awlock),
      .ifu_axi_awcache (ifu_axi_awcache),
      .ifu_axi_awprot  (ifu_axi_awprot),
      .ifu_axi_awqos   (ifu_axi_awqos),

      .ifu_axi_wvalid(ifu_axi_wvalid),
      .ifu_axi_wready(ifu_axi_wready),
      .ifu_axi_wdata (ifu_axi_wdata),
      .ifu_axi_wstrb (ifu_axi_wstrb),
      .ifu_axi_wlast (ifu_axi_wlast),

      .ifu_axi_bvalid(ifu_axi_bvalid),
      .ifu_axi_bready(ifu_axi_bready),
      .ifu_axi_bresp (ifu_axi_bresp),
      .ifu_axi_bid   (ifu_axi_bid),

      .ifu_axi_arvalid (ifu_axi_arvalid),
      .ifu_axi_arready (ifu_axi_arready),
      .ifu_axi_arid    (ifu_axi_arid),
      .ifu_axi_araddr  (ifu_axi_araddr),
      .ifu_axi_arregion(ifu_axi_arregion),
      .ifu_axi_arlen   (ifu_axi_arlen),
      .ifu_axi_arsize  (ifu_axi_arsize),
      .ifu_axi_arburst (ifu_axi_arburst),
      .ifu_axi_arlock  (ifu_axi_arlock),
      .ifu_axi_arcache (ifu_axi_arcache),
      .ifu_axi_arprot  (ifu_axi_arprot),
      .ifu_axi_arqos   (ifu_axi_arqos),

      .ifu_axi_rvalid(ifu_axi_rvalid),
      .ifu_axi_rready(ifu_axi_rready),
      .ifu_axi_rid   (ifu_axi_rid),
      .ifu_axi_rdata (ifu_axi_rdata),
      .ifu_axi_rresp (ifu_axi_rresp),
      .ifu_axi_rlast (ifu_axi_rlast),

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
      .dma_axi_awvalid(dma_axi_awvalid),
      .dma_axi_awready(dma_axi_awready),
      .dma_axi_awid   ('0),
      .dma_axi_awaddr (lsu_axi_awaddr),
      .dma_axi_awsize (lsu_axi_awsize),
      .dma_axi_awprot (lsu_axi_awprot),
      .dma_axi_awlen  (lsu_axi_awlen),
      .dma_axi_awburst(lsu_axi_awburst),

      .dma_axi_wvalid(dma_axi_wvalid),
      .dma_axi_wready(dma_axi_wready),
      .dma_axi_wdata (lsu_axi_wdata),
      .dma_axi_wstrb (lsu_axi_wstrb),
      .dma_axi_wlast (lsu_axi_wlast),

      .dma_axi_bvalid(dma_axi_bvalid),
      .dma_axi_bready(dma_axi_bready),
      .dma_axi_bresp (dma_axi_bresp),
      .dma_axi_bid   (),

      .dma_axi_arvalid(dma_axi_arvalid),
      .dma_axi_arready(dma_axi_arready),
      .dma_axi_arid   ('0),
      .dma_axi_araddr (lsu_axi_araddr),
      .dma_axi_arsize (lsu_axi_arsize),
      .dma_axi_arprot (lsu_axi_arprot),
      .dma_axi_arlen  (lsu_axi_arlen),
      .dma_axi_arburst(lsu_axi_arburst),

      .dma_axi_rvalid(dma_axi_rvalid),
      .dma_axi_rready(dma_axi_rready),
      .dma_axi_rid   (),
      .dma_axi_rdata (dma_axi_rdata),
      .dma_axi_rresp (dma_axi_rresp),
      .dma_axi_rlast (dma_axi_rlast),

      .timer_int    (timer_int_i),
      .extintsrc_req(),

      .lsu_bus_clk_en(lsu_bus_clk_en_i),  // Clock ratio b/w cpu core clk & AHB master interface
      .ifu_bus_clk_en(1'b1),            // Clock ratio b/w cpu core clk & AHB master interface
      .dbg_bus_clk_en(1'b1),            // Clock ratio b/w cpu core clk & AHB Debug master interface
      .dma_bus_clk_en(1'b1),            // Clock ratio b/w cpu core clk & AHB slave interface

      .trace_rv_i_insn_ip     (trace_rv_i_insn_ip_o),
      .trace_rv_i_address_ip  (trace_rv_i_address_ip_o),
      .trace_rv_i_valid_ip    (trace_rv_i_valid_ip_o),
      .trace_rv_i_exception_ip(trace_rv_i_exception_ip_o),
      .trace_rv_i_ecause_ip   (trace_rv_i_ecause_ip_o),
      .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip_o),
      .trace_rv_i_tval_ip     (trace_rv_i_tval_ip_o),

      .jtag_tck   (),
      .jtag_tms   (),
      .jtag_tdi   (),
      .jtag_trst_n(),
      .jtag_tdo   (),
      .jtag_tdoEn (),

      .mpc_debug_halt_ack(mpc_debug_halt_ack_o),
      .mpc_debug_halt_req(mpc_debug_halt_req_i),
      .mpc_debug_run_ack (mpc_debug_run_ack_o),
      .mpc_debug_run_req (mpc_debug_run_req_i),
      .mpc_reset_run_req (1'b1),                // Start running after reset
      .debug_brkpt_status(),

      .i_cpu_halt_req     (cpu_halt_req_i),       // Async halt req to CPU
      .o_cpu_halt_ack     (cpu_halt_ack_o),       // core response to halt
      .o_cpu_halt_status  (cpu_halt_status_o),    // 1'b1 indicates core is halted
      .i_cpu_run_req      (cpu_run_req_i),        // Async restart req to CPU
      .o_debug_mode_status(debug_mode_status_o),
      .o_cpu_run_ack      (cpu_run_ack_o),        // Core response to run req

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

      .soft_int  (soft_int_i),
      .core_id   ('0),
      .scan_mode (1'b0),      // To enable scan mode
      .mbist_mode(1'b0),      // to enable mbist

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
      .clk_i(clk_i),
      .rst_ni(rst_ni),

      .i_veer_lsu_awid(lsu_axi_awid),
      .i_veer_lsu_awaddr(lsu_axi_awaddr),
      .i_veer_lsu_awlen(lsu_axi_awlen),
      .i_veer_lsu_awsize(lsu_axi_awsize),
      .i_veer_lsu_awburst(lsu_axi_awburst),
      .i_veer_lsu_awlock(lsu_axi_awlock),
      .i_veer_lsu_awcache(lsu_axi_awcache),
      .i_veer_lsu_awprot(lsu_axi_awprot),
      .i_veer_lsu_awregion(lsu_axi_awregion),
      .i_veer_lsu_awqos(lsu_axi_awqos),
      .i_veer_lsu_awvalid(lsu_axi_awvalid),
      .o_veer_lsu_awready(lsu_axi_awready),
      .i_veer_lsu_arid(lsu_axi_arid),
      .i_veer_lsu_araddr(lsu_axi_araddr),
      .i_veer_lsu_arlen(lsu_axi_arlen),
      .i_veer_lsu_arsize(lsu_axi_arsize),
      .i_veer_lsu_arburst(lsu_axi_arburst),
      .i_veer_lsu_arlock(lsu_axi_arlock),
      .i_veer_lsu_arcache(lsu_axi_arcache),
      .i_veer_lsu_arprot(lsu_axi_arprot),
      .i_veer_lsu_arregion(lsu_axi_arregion),
      .i_veer_lsu_arqos(lsu_axi_arqos),
      .i_veer_lsu_arvalid(lsu_axi_arvalid),
      .o_veer_lsu_arready(lsu_axi_arready),
      .i_veer_lsu_wdata(lsu_axi_wdata),
      .i_veer_lsu_wstrb(lsu_axi_wstrb),
      .i_veer_lsu_wlast(lsu_axi_wlast),
      .i_veer_lsu_wvalid(lsu_axi_wvalid),
      .o_veer_lsu_wready(lsu_axi_wready),
      .o_veer_lsu_bid(lsu_axi_bid),
      .o_veer_lsu_bresp(lsu_axi_bresp),
      .o_veer_lsu_bvalid(lsu_axi_bvalid),
      .i_veer_lsu_bready(lsu_axi_bready),
      .o_veer_lsu_rid(lsu_axi_rid),
      .o_veer_lsu_rdata(lsu_axi_rdata),
      .o_veer_lsu_rresp(lsu_axi_rresp),
      .o_veer_lsu_rlast(lsu_axi_rlast),
      .o_veer_lsu_rvalid(lsu_axi_rvalid),
      .i_veer_lsu_rready(lsu_axi_rready),

      .i_veer_ifu_awid(ifu_axi_awid),
      .i_veer_ifu_awaddr(ifu_axi_awaddr),
      .i_veer_ifu_awlen(ifu_axi_awlen),
      .i_veer_ifu_awsize(ifu_axi_awsize),
      .i_veer_ifu_awburst(ifu_axi_awburst),
      .i_veer_ifu_awlock(ifu_axi_awlock),
      .i_veer_ifu_awcache(ifu_axi_awcache),
      .i_veer_ifu_awprot(ifu_axi_awprot),
      .i_veer_ifu_awregion(ifu_axi_awregion),
      .i_veer_ifu_awqos(ifu_axi_awqos),
      .i_veer_ifu_awvalid(ifu_axi_awvalid),
      .o_veer_ifu_awready(ifu_axi_awready),
      .i_veer_ifu_arid(ifu_axi_arid),
      .i_veer_ifu_araddr(ifu_axi_araddr),
      .i_veer_ifu_arlen(ifu_axi_arlen),
      .i_veer_ifu_arsize(ifu_axi_arsize),
      .i_veer_ifu_arburst(ifu_axi_arburst),
      .i_veer_ifu_arlock(ifu_axi_arlock),
      .i_veer_ifu_arcache(ifu_axi_arcache),
      .i_veer_ifu_arprot(ifu_axi_arprot),
      .i_veer_ifu_arregion(ifu_axi_arregion),
      .i_veer_ifu_arqos(ifu_axi_arqos),
      .i_veer_ifu_arvalid(ifu_axi_arvalid),
      .o_veer_ifu_arready(ifu_axi_arready),
      .i_veer_ifu_wdata(ifu_axi_wdata),
      .i_veer_ifu_wstrb(ifu_axi_wstrb),
      .i_veer_ifu_wlast(ifu_axi_wlast),
      .i_veer_ifu_wvalid(ifu_axi_wvalid),
      .o_veer_ifu_wready(ifu_axi_wready),
      .o_veer_ifu_bid(ifu_axi_bid),
      .o_veer_ifu_bresp(ifu_axi_bresp),
      .o_veer_ifu_bvalid(ifu_axi_bvalid),
      .i_veer_ifu_bready(ifu_axi_bready),
      .o_veer_ifu_rid(ifu_axi_rid),
      .o_veer_ifu_rdata(ifu_axi_rdata),
      .o_veer_ifu_rresp(ifu_axi_rresp),
      .o_veer_ifu_rlast(ifu_axi_rlast),
      .o_veer_ifu_rvalid(ifu_axi_rvalid),
      .i_veer_ifu_rready(ifu_axi_rready),

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

      .o_uart_awid(uart_axi_awid),
      .o_uart_awaddr(uart_axi_awaddr),
      .o_uart_awlen(uart_axi_awlen),
      .o_uart_awsize(uart_axi_awsize),
      .o_uart_awburst(uart_axi_awburst),
      .o_uart_awlock(uart_axi_awlock),
      .o_uart_awcache(uart_axi_awcache),
      .o_uart_awprot(uart_axi_awprot),
      .o_uart_awregion(uart_axi_awregion),
      .o_uart_awqos(uart_axi_awqos),
      .o_uart_awvalid(uart_axi_awvalid),
      .i_uart_awready(uart_axi_awready),
      .o_uart_arid(uart_axi_arid),
      .o_uart_araddr(uart_axi_araddr),
      .o_uart_arlen(uart_axi_arlen),
      .o_uart_arsize(uart_axi_arsize),
      .o_uart_arburst(uart_axi_arburst),
      .o_uart_arlock(uart_axi_arlock),
      .o_uart_arcache(uart_axi_arcache),
      .o_uart_arprot(uart_axi_arprot),
      .o_uart_arregion(uart_axi_arregion),
      .o_uart_arqos(uart_axi_arqos),
      .o_uart_arvalid(uart_axi_arvalid),
      .i_uart_arready(uart_axi_arready),
      .o_uart_wdata(uart_axi_wdata),
      .o_uart_wstrb(uart_axi_wstrb),
      .o_uart_wlast(uart_axi_wlast),
      .o_uart_wvalid(uart_axi_wvalid),
      .i_uart_wready(uart_axi_wready),
      .i_uart_bid(uart_axi_bid),
      .i_uart_bresp(uart_axi_bresp),
      .i_uart_bvalid(uart_axi_bvalid),
      .o_uart_bready(uart_axi_bready),
      .i_uart_rid(uart_axi_rid),
      .i_uart_rdata(uart_axi_rdata),
      .i_uart_rresp(uart_axi_rresp),
      .i_uart_rlast(uart_axi_rlast),
      .i_uart_rvalid(uart_axi_rvalid),
      .o_uart_rready(uart_axi_rready),

      .o_i3c_awid(i3c_axi_awid),
      .o_i3c_awaddr(i3c_axi_awaddr),
      .o_i3c_awlen(i3c_axi_awlen),
      .o_i3c_awsize(i3c_axi_awsize),
      .o_i3c_awburst(i3c_axi_awburst),
      .o_i3c_awlock(i3c_axi_awlock),
      .o_i3c_awcache(i3c_axi_awcache),
      .o_i3c_awprot(i3c_axi_awprot),
      .o_i3c_awregion(i3c_axi_awregion),
      .o_i3c_awqos(i3c_axi_awqos),
      .o_i3c_awvalid(i3c_axi_awvalid),
      .i_i3c_awready(i3c_axi_awready),
      .o_i3c_arid(i3c_axi_arid),
      .o_i3c_araddr(i3c_axi_araddr),
      .o_i3c_arlen(i3c_axi_arlen),
      .o_i3c_arsize(i3c_axi_arsize),
      .o_i3c_arburst(i3c_axi_arburst),
      .o_i3c_arlock(i3c_axi_arlock),
      .o_i3c_arcache(i3c_axi_arcache),
      .o_i3c_arprot(i3c_axi_arprot),
      .o_i3c_arregion(i3c_axi_arregion),
      .o_i3c_arqos(i3c_axi_arqos),
      .o_i3c_arvalid(i3c_axi_arvalid),
      .i_i3c_arready(i3c_axi_arready),
      .o_i3c_wdata(i3c_axi_wdata),
      .o_i3c_wstrb(i3c_axi_wstrb),
      .o_i3c_wlast(i3c_axi_wlast),
      .o_i3c_wvalid(i3c_axi_wvalid),
      .i_i3c_wready(i3c_axi_wready),
      .i_i3c_bid(i3c_axi_bid),
      .i_i3c_bresp(i3c_axi_bresp),
      .i_i3c_bvalid(i3c_axi_bvalid),
      .o_i3c_bready(i3c_axi_bready),
      .i_i3c_rid(i3c_axi_rid),
      .i_i3c_rdata(i3c_axi_rdata),
      .i_i3c_rresp(i3c_axi_rresp),
      .i_i3c_rlast(i3c_axi_rlast),
      .i_i3c_rvalid(i3c_axi_rvalid),
      .o_i3c_rready(i3c_axi_rready)
  );

endmodule
