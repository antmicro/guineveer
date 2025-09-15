// Copyright (c) 2025 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

module guineveer_sram #(
    parameter int  ADDR_WIDTH = 32,
    parameter int  DATA_WIDTH = 64,
    parameter int  ID_WIDTH   = 1,
    parameter type AXI_REQ_T  = logic,
    parameter type AXI_RESP_T = logic
) (
    input clk_i,
    input rst_ni,
    input AXI_REQ_T axi_req_i,
    output AXI_RESP_T axi_resp_o
);
  localparam int WORD_BYTE_WIDTH = $clog2(DATA_WIDTH) - 3;
  localparam int WORD_ADDR_COUNT = (1 << ADDR_WIDTH) >> WORD_BYTE_WIDTH;
  localparam int WORD_ADDR_WIDTH = $clog2(WORD_ADDR_COUNT);

  logic mem_rvalid;
  logic [DATA_WIDTH-1:0] mem_rdata;
  bit [DATA_WIDTH-1:0] mem[WORD_ADDR_COUNT];

  axi_to_mem #(
      .axi_req_t(AXI_REQ_T),
      .axi_resp_t(AXI_RESP_T),
      .AddrWidth(ADDR_WIDTH),
      .DataWidth(DATA_WIDTH),
      .IdWidth(ID_WIDTH),
      .NumBanks(1)
  ) xaxi_to_mem (
      .clk_i,
      .rst_ni,
      .busy_o(),
      .axi_req_i,
      .axi_resp_o,

      .mem_req_o(),
      .mem_gnt_i('1),
      .mem_addr_o(),
      .mem_wdata_o(),
      .mem_strb_o(),
      .mem_atop_o(),
      .mem_we_o(),
      .mem_rvalid_i(mem_rvalid),
      .mem_rdata_i(mem_rdata)
  );


  always_ff @(posedge clk_i) begin
    if (!xaxi_to_mem.mem_req_o) begin
      mem_rvalid <= '0;
    end else if (xaxi_to_mem.mem_req_o) begin
      automatic logic [WORD_ADDR_WIDTH-1:0] cell_addr = {xaxi_to_mem.mem_addr_o[0] >> WORD_BYTE_WIDTH}[WORD_ADDR_WIDTH-1:0];

      mem_rvalid <= '1;
      mem_rdata  <= mem[cell_addr];

      if (xaxi_to_mem.mem_we_o[0])
        for (int i = 0; i < 8; i++)
        if (xaxi_to_mem.mem_strb_o[0][i])
          mem[cell_addr][8*i+:8] <= xaxi_to_mem.mem_wdata_o[0][8*i+:8];
    end
  end

`ifdef GUINEVEER_MEMORY_FILE
  initial $readmemh(`GUINEVEER_MEMORY_FILE, mem);
`endif

endmodule
