// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

`timescale 1ns / 10ps

module guineveer_cocotb_dut #(
    parameter int MAX_CYCLES = 100_000_000
) (
    output logic core_clk_o,
    input  logic rst_ni,
    input  logic i3c_scl_i,
    input  logic i3c_sda_i,
    output logic i3c_scl_o,
    output logic i3c_sda_o,
    output logic i3c_scl_oe,
    output logic i3c_sda_oe,
    output logic i3c_sel_od_pp_o,
    input  logic uart_rx_i,
    output logic uart_tx_o
);
  int   cycle_cnt;
  logic core_clk;
  logic i3c_clk;
  logic porst_ni;

  always #(15) core_clk = ~core_clk;  // 33.33MHz
  always #(2) i3c_clk = ~i3c_clk;  // 250MHz

  assign core_clk_o = core_clk;

  always @(negedge core_clk or negedge rst_ni) begin
    if (!rst_ni) cycle_cnt <= 0;
    else cycle_cnt <= cycle_cnt + 1;
  end
  assign porst_ni = cycle_cnt > 2;


  always @(negedge core_clk or negedge rst_ni) begin
    if (cycle_cnt == MAX_CYCLES) begin
      $display("Hit max cycle count (%0d) .. stopping", cycle_cnt);
      $display("TEST_FAILED");
      $fatal;
    end
  end

  guineveer top_guineveer (
      .clk_i(core_clk),
      .rst_ni(porst_ni),
      .cpu_rst_ni(porst_ni),

      .i3c_clk_i (i3c_clk),
      .i3c_rst_ni(porst_ni),
      .i3c_scl_i,
      .i3c_sda_i,
      .i3c_scl_o,
      .i3c_sda_o,
      .i3c_scl_oe,
      .i3c_sda_oe,
      .i3c_sel_od_pp_o,

      .uart_rx_i,
      .uart_tx_o
  );
endmodule
