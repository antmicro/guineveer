#include <stdint.h>

#define SOC_CLOCK_HZ	(32000000L)
#define UART_BASE_ADDR	(0x30000000)
#define UART_BAUD_RATE  (115200)

#define UART_INTR_STATE_REG      (0x0  / 4)
#define UART_INTR_ENABLE_REG     (0x4  / 4)
#define UART_INTR_TEST_REG       (0x8  / 4)
#define UART_ALERT_TEST_REG      (0xc  / 4)
#define UART_CTRL_REG            (0x10 / 4)
#define UART_STATUS_REG          (0x14 / 4)
#define UART_RDATA_REG           (0x18 / 4)
#define UART_WDATA_REG           (0x1c / 4)
#define UART_FIFO_CTRL_REG       (0x20 / 4)
#define UART_FIFO_STATUS_REG     (0x24 / 4)
#define UART_OVRD_REG            (0x28 / 4)
#define UART_VAL_REG             (0x2c / 4)
#define UART_TIMEOUT_CTRL_REG    (0x30 / 4)

#define UART_CTRL_NCO_OFFSET		(16)
#define UART_CTRL_TX_EN			(1 << 0)
#define UART_CTRL_RX_EN			(1 << 1)
#define UART_STATUS_TX_IDLE		(1 << 3)
#define UART_FIFO_CTRL_RXRST		(1 << 0)
#define UART_FIFO_CTRL_TXRST		(1 << 1)
#define UART_FIFO_STATUS_TXLVL_MASK	(0xff)
#define UART_FIFO_STATUS_RXLVL_MASK 	(0xff0000)

/* Base address of the UART peripheral */
volatile uint32_t* uart_regs = (uint32_t*)UART_BASE_ADDR;

void uart_init(uint64_t baud)
{
	uint64_t nco = (baud << 20) / SOC_CLOCK_HZ;

	/* Set baudrate, enable TX, RX */
	uart_regs[UART_CTRL_REG] = (nco << UART_CTRL_NCO_OFFSET) | UART_CTRL_TX_EN | UART_CTRL_RX_EN;
	/* Reset FIFOs */
	uart_regs[UART_FIFO_CTRL_REG] = UART_FIFO_CTRL_RXRST | UART_FIFO_CTRL_TXRST;
}

int uart_tx_rdy(void)
{
	return (uart_regs[UART_STATUS_REG] & UART_STATUS_TX_IDLE) > 0;
}

int uart_rx_empty(void)
{
	return (uart_regs[UART_FIFO_STATUS_REG] & UART_FIFO_STATUS_RXLVL_MASK) == 0;
}

void uart_putc(char chr)
{
	while (!uart_tx_rdy())
		;

	uart_regs[UART_WDATA_REG] = chr;
}

void uart_puts(const char* str)
{
	while (*str)
		uart_putc(*str++);
}

int main(void)
{
	int i = 0;
	while(i <= 5000) {
		i++;
	} //Wait for second core to print
	uart_init(UART_BAUD_RATE);
	uart_puts("Hello from core 0\r\n");

	return 0;
}
