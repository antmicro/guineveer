#ifndef UART_H
#define UART_H

#include "utils.h"
#include <stdint.h>

#define UART_BASE	(0x30000000)
#define UART_BAUD_RATE  (115200)

#define UART_INTR_STATE_REG      (0x0)
#define UART_INTR_ENABLE_REG     (0x4)
#define UART_INTR_TEST_REG       (0x8)
#define UART_ALERT_TEST_REG      (0xc)
#define UART_CTRL_REG            (0x10)
#define UART_STATUS_REG          (0x14)
#define UART_RDATA_REG           (0x18)
#define UART_WDATA_REG           (0x1c)
#define UART_FIFO_CTRL_REG       (0x20)
#define UART_FIFO_STATUS_REG     (0x24)
#define UART_OVRD_REG            (0x28)
#define UART_VAL_REG             (0x2c)
#define UART_TIMEOUT_CTRL_REG    (0x30)

#define UART_CTRL_NCO_OFFSET		(16)
#define UART_CTRL_TX_EN			(1 << 0)
#define UART_CTRL_RX_EN			(1 << 1)
#define UART_STATUS_TX_IDLE		(1 << 3)
#define UART_FIFO_CTRL_RXRST		(1 << 0)
#define UART_FIFO_CTRL_TXRST		(1 << 1)
#define UART_FIFO_STATUS_TXLVL_MASK	(0xff)
#define UART_FIFO_STATUS_RXLVL_MASK 	(0xff0000)

void uart_init(uint64_t);

int uart_tx_rdy(void);

int uart_rx_empty(void);

void _putchar(char);

int getchar();
#endif
