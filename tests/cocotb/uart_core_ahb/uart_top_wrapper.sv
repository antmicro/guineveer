// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

localparam AHBAddrWidth = 32;
localparam AHBDataWidth = 32;

module uart_top_wrapper (
    input logic clk,
    input logic rst,

    input logic uart_rx,
    output logic uart_tx,

    input logic [AHBAddrWidth-1:0]  sub_haddr,
    input logic [AHBDataWidth-1:0]  sub_hwdata,
    input logic                     sub_hsel,
    input logic                     sub_hwrite,
    input logic                     sub_hready,
    input logic [1:0]               sub_htrans,
    input logic [2:0]               sub_hsize,

    output logic                    sub_hresp,
    output logic                    sub_hreadyout,
    output logic [AHBDataWidth-1:0] sub_hrdata,

    output logic intr_tx_watermark_o,
    output logic intr_rx_watermark_o,
    output logic intr_tx_empty_o,
    output logic intr_rx_overflow_o,
    output logic intr_rx_frame_err_o,
    output logic intr_rx_break_err_o,
    output logic intr_rx_timeout_o,
    output logic intr_rx_parity_err_o
);

uart #(
    .AHBAddrWidth(AHBAddrWidth),
    .AHBDataWidth(AHBDataWidth)
) uart_core (
    .clk_i         (clk),
    .rst_ni        (rst),

    .cio_rx_i      (uart_rx),
    .cio_tx_o      (uart_tx),

    .haddr_i       (sub_haddr),
    .hwdata_i      (sub_hwdata),
    .hsel_i        (sub_hsel),
    .hwrite_i      (sub_hwrite),
    .hready_i      (sub_hready),
    .htrans_i      (sub_htrans),
    .hsize_i       (sub_hsize),
    .hresp_o       (sub_hresp),
    .hreadyout_o   (sub_hreadyout),
    .hrdata_o      (sub_hrdata),

    .alert_rx_i(),
    .alert_tx_o(),

    .cio_tx_en_o(),

    .intr_tx_watermark_o (intr_tx_watermark_o),
    .intr_rx_watermark_o (intr_rx_watermark_o),
    .intr_tx_empty_o     (intr_tx_empty_o),
    .intr_rx_overflow_o  (intr_rx_overflow_o),
    .intr_rx_frame_err_o (intr_rx_frame_err_o),
    .intr_rx_break_err_o (intr_rx_break_err_o),
    .intr_rx_timeout_o   (intr_rx_timeout_o),
    .intr_rx_parity_err_o(intr_rx_parity_err_o)
);

endmodule
