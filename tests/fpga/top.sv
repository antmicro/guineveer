// Copyright (c) 2025 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

/*
    Top-level wrapper for Guineveer SoC for Digilent Arty A7 (Artix 100T) platform
*/
module top (

    // 100MHz clock
    input  logic clk100_i,

    // Buttons & LEDs
    input  logic [3:0] btn_i,
    output logic [3:0] led_o,

    // UART IO
    input  logic uart_rx_i,
    output logic uart_tx_o,

    // I3C bus IO
    inout wire i3c_scl_io,
    inout wire i3c_sda_io
);

    // PLL
    logic clk_soc;
    logic rstn_soc;

    logic clk_i3c;
    logic rstn_i3c;

    logic pll_clkfb;
    logic pll_clkout0;
    logic pll_locked;

    PLLE2_BASE # (
        .CLKIN1_PERIOD  (10.0), // 100MHz
        .CLKFBOUT_MULT  (16),
        .CLKOUT0_DIVIDE (50),
        .CLKOUT1_DIVIDE (8)

    ) u_pll (
        .RST            (btn_i[0]),
        .CLKIN1         (clk100_i),

        .CLKFBIN        (pll_clkfb),
        .CLKFBOUT       (pll_clkfb),

        .LOCKED         (pll_locked),
        .CLKOUT0        (pll_clkout0),  // 32MHz
        .CLKOUT1        (pll_clkout1)   // 200MHz
    );

    BUFG u_bufg0 (.I(pll_clkout0), .O(clk_soc));

    // Reset synchronizer
    always_ff @(posedge clk_soc or negedge pll_locked)
        if (!pll_locked) rstn_soc <= '0;
        else             rstn_soc <= '1;

    // CPU reset
    logic [3:0] rstn_cpu_sr;
    logic rstn_cpu;

    always_ff @(posedge clk_soc or negedge rstn_soc)
        if (!rstn_soc) begin
            rstn_cpu_sr <= '0;
        end else begin
            rstn_cpu_sr <= (rstn_cpu_sr << 1) | !btn_i[1];
        end

    assign rstn_cpu = rstn_cpu_sr[3];

    BUFG u_bufg1 (.I(pll_clkout1), .O(clk_i3c));

    // Reset synchronizer
    always_ff @(posedge clk_i3c or negedge pll_locked)
        if (!pll_locked) rstn_i3c <= '0;
        else             rstn_i3c <= '1;

    // Guineveer SoC
    guineveer u_guineveer (
        .clk_i      (clk_soc),
        .rst_ni     (rstn_soc),
        .cpu_rst_ni (rstn_cpu),

        .i3c_clk_i  (clk_i3c),
        .i3c_rst_ni (rstn_i3c),

        .uart_rx_i  (uart_rx_i),
        .uart_tx_o  (uart_tx_o),

        .i3c_scl_io (i3c_scl_io),
        .i3c_sda_io (i3c_sda_io)
    );

    // LEDs (debugging)

    logic [23:0] blinky_cnt;
    always_ff @(posedge clk_soc or negedge rstn_soc)
        if (!rstn_soc)
            blinky_cnt <= '0;
        else
            blinky_cnt <= blinky_cnt + 1;

    always_comb begin
        led_o[0]    = rstn_soc;
        led_o[1]    = blinky_cnt[20];
        led_o[2]    = rstn_cpu;
        led_o[3]    = rstn_i3c;
    end

endmodule
