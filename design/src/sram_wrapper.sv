// Copyright (c) 2025 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

`include "axi/assign.svh"
`include "axi/port.svh"
`include "axi/typedef.svh"

module sram_wrapper #(
    parameter string GUINEVEER_MEMORY_FILE = ""
) (
    `AXI_S_PORT(sram, logic [31:0], logic [63:0], logic [7:0], logic [4:0], logic, logic, logic,
                logic, logic)
    input wire clk_i,
    input wire rst_ni
);
  `AXI_TYPEDEF_ALL(axi, logic [16:0], logic [4:0], logic [63:0], logic [7:0], logic)
  axi_req_t  axi_req;
  axi_resp_t axi_resp;
  `AXI_ASSIGN_SLAVE_TO_FLAT(sram, axi_req, axi_resp)

  guineveer_sram #(
      .ADDR_WIDTH($bits(axi_req.aw.addr)),
      .DATA_WIDTH($bits(axi_req.w.data)),
      .ID_WIDTH  ($bits(axi_req.aw.id)),
      .AXI_REQ_T (axi_req_t),
      .AXI_RESP_T(axi_resp_t),
      .GUINEVEER_MEMORY_FILE(GUINEVEER_MEMORY_FILE)
  ) xguineveer_sram (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .axi_req_i(axi_req),
      .axi_resp_o(axi_resp)
  );

endmodule
