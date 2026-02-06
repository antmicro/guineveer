// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>
// SPDX-License-Identifier: Apache-2.0

// This is a wrapper over Caliptra's UART where AHB haddr and hsize signals are
// directly modified in order to offset the read address 32-bit forward.
// The reason for doing that is caused by this UART core using 32-bit registers
// and allowing only 32-bit wide accesses, while the AXI-to-AHB bridge connected
// before supports only 64-bit transactions on adresses aligned to 64-bits as well.

module uart_wrapper (
    input wire clk_i,
    input wire rst_ni,
    input wire uart_rx_i,
    output wire uart_tx_o,

    input wire [31:0] haddr_i,
    input wire [2:0] hsize_i,
    input wire [1:0] htrans_i,
    input wire [63:0] hwdata_i,
    input wire hwrite_i,
    output wire [63:0] hrdata_o,
    output wire hresp_o
);

  uart #(
    .AHBAddrWidth(32),
    .AHBDataWidth(64)
  ) uart_core (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .cio_rx_i(uart_rx_i),
    .cio_tx_o(uart_tx_o),

    .hsel_i(1),
    .hready_i(uart_core.hreadyout_o),
    .haddr_i(haddr_i + (hsize_i == 'b11 ? 'h4 : 0)),
    .hsize_i(hsize_i & 'b10),
    .htrans_i(htrans_i),
    .hwdata_i(hwdata_i),
    .hwrite_i(hwrite_i),
    .hrdata_o(hrdata_o),
    .hresp_o(hresp_o),
    .hreadyout_o(),

    .alert_rx_i(),
    .intr_rx_break_err_o(),
    .intr_tx_empty_o(),
    .intr_tx_watermark_o(),
    .cio_tx_en_o(),
    .intr_rx_frame_err_o(),
    .intr_rx_parity_err_o(),
    .intr_rx_watermark_o(),
    .alert_tx_o(),
    .intr_rx_timeout_o(),
    .intr_rx_overflow_o()
  );

endmodule
