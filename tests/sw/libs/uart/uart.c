#include "uart.h"

void uart_init(uint64_t baud)
{
	uint64_t nco = (baud << 20) / SOC_CLOCK_HZ;

	/* Set baudrate, enable TX, RX */
	write32(UART_BASE + UART_CTRL_REG,
		(nco << UART_CTRL_NCO_OFFSET) | UART_CTRL_TX_EN | UART_CTRL_RX_EN);
	/* Reset FIFOs */
	write32(UART_BASE + UART_FIFO_CTRL_REG,
		UART_FIFO_CTRL_RXRST | UART_FIFO_CTRL_TXRST);
}

int uart_tx_rdy(void)
{
	return (read32(UART_BASE + UART_STATUS_REG) & UART_STATUS_TX_IDLE) > 0;
}

int uart_rx_empty(void)
{
	return (read32(UART_BASE + UART_FIFO_STATUS_REG) & UART_FIFO_STATUS_RXLVL_MASK) == 0;
}

void _putchar(char character)
{
	while (!uart_tx_rdy())
		;

	write32(UART_BASE + UART_WDATA_REG, character);
}

int getchar()
{
	while (uart_rx_empty())
		;

	return read32(UART_BASE + UART_RDATA_REG) & 0xFF;
}
