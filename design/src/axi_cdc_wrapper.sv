// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

`include "axi/assign.svh"
`include "axi/port.svh"
`include "axi/typedef.svh"

module axi_cdc_wrapper #(
    parameter int ID_WIDTH
    ) (
    `AXI_S_PORT(src, logic [31:0], logic [63:0], logic [7:0], logic [ID_WIDTH-1:0], logic, logic, logic,
                logic, logic)
    `AXI_M_PORT(dst, logic [31:0], logic [63:0], logic [7:0], logic [ID_WIDTH-1:0], logic, logic, logic,
                logic, logic)
    input wire src_clk_i,
    input wire src_rst_ni,
    input wire dst_clk_i,
    input wire dst_rst_ni
);
  `AXI_TYPEDEF_ALL(src, logic [31:0], logic [ID_WIDTH-1:0], logic [63:0], logic [7:0], logic)
  `AXI_TYPEDEF_ALL(dst, logic [31:0], logic [ID_WIDTH-1:0], logic [63:0], logic [7:0], logic)
  src_req_t  src_req;
  src_resp_t src_resp;
  dst_req_t  dst_req;
  dst_resp_t dst_resp;
  `AXI_ASSIGN_SLAVE_TO_FLAT(src, src_req, src_resp)
  `AXI_ASSIGN_MASTER_TO_FLAT(dst, dst_req, dst_resp)

  axi_cdc #(
      .aw_chan_t (src_aw_chan_t),
      .w_chan_t  (src_w_chan_t),
      .b_chan_t  (src_b_chan_t),
      .ar_chan_t (src_ar_chan_t),
      .r_chan_t  (src_r_chan_t),
      .axi_req_t (src_req_t),
      .axi_resp_t(src_resp_t)
  ) xaxi_cdc (
      .src_clk_i,
      .src_rst_ni,
      .src_req_i (src_req),
      .src_resp_o(src_resp),
      .dst_clk_i,
      .dst_rst_ni,
      .dst_req_o (dst_req),
      .dst_resp_i(dst_resp)
  );

endmodule
