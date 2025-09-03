#include <stdint.h>
#include "printf.h"

#define SOC_CLOCK_HZ	(32000000L)

void write32(uint32_t address, uint32_t value)
{
	*(volatile uint32_t *)address = value;
}

uint32_t read32(uint32_t address)
{
	return *(volatile uint32_t *)address;
}

/* ---------- UART ---------- */

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

/* ---------- I3C ---------- */

#define I3C_BASE	(0x30001000)

#define I3C_STBY_CR_CONTROL			(0x184)
#define  I3C_STBY_CR_CONTROL_TARGET_XACT_ENABLE	(1 << 12)
#define  I3C_STBY_CR_CONTROL_DAA_SETDASA_ENABLE	(1 << 14)
#define  I3C_STBY_CR_CONTROL_ENABLE_INIT_MASK	(0xc0000000)
#define  I3C_STBY_CR_CONTROL_ENABLE_INIT_SHIFT	(30)
#define  I3C_STBY_CR_CONTROL_ENABLE_INIT_RUN	(2)
#define I3C_STBY_CR_DEVICE_ADDR			(0x188)
#define  I3C_STBY_CR_DEVICE_ADDR_ADDR_MASK	(0x0000007f)
#define  I3C_STBY_CR_DEVICE_ADDR_STATIC_SHIFT	(0)
#define  I3C_STBY_CR_DEVICE_ADDR_STATIC_VALID	(1 << 15)
#define  I3C_STBY_CR_DEVICE_ADDR_DYNAMIC_SHIFT	(16)
#define  I3C_STBY_CR_DEVICE_ADDR_DYNAMIC_VALID	(1 << 31)

#define I3C_TTI_INTERRUPT_STATUS		(0x1d0)
#define I3C_TTI_INTERRUPT_ENABLE		(0x1d4)
#define  I3C_TTI_INTERRUPT_RX_DESC_STAT		(1 << 0)
#define  I3C_TTI_INTERRUPT_TX_DESC_STAT		(1 << 1)
#define I3C_TTI_RX_DESC_QUEUE_PORT		(0x1dc)
#define I3C_TTI_RX_DATA_PORT			(0x1e0)
#define I3C_TTI_TX_DESC_QUEUE_PORT		(0x1e4)
#define I3C_TTI_TX_DATA_PORT			(0x1e8)
#define I3C_TTI_QUEUE_THLD_CTRL			(0x1f8)
#define  I3C_TTI_QUEUE_THLD_CTRL_RX_DESC_SHIFT	(8)
#define  I3C_TTI_QUEUE_THLD_CTRL_RX_DESC_MASK	(0xff00)
#define  I3C_TTI_QUEUE_THLD_CTRL_RX_DESC_INIT	(0x01)
#define I3C_TTI_BUFFER_THLD_CTRL		(0x1fc)
#define  I3C_TTI_BUFFER_THLD_CTRL_RX_DATA_SHIFT	(8)
#define  I3C_TTI_BUFFER_THLD_CTRL_RX_DATA_MASK	(0x700)

#define STATIC_ADDR (0x5A)


void i3c_init()
{
	/* Program SDA/SCL timings. */
	/* TODO: Leave at 0 for now, as in the i3c-core tests. */

	/* Standby controller init. */
	uint32_t val = read32(I3C_BASE + I3C_STBY_CR_CONTROL);
	val &= ~I3C_STBY_CR_CONTROL_ENABLE_INIT_MASK;
	val |= I3C_STBY_CR_CONTROL_ENABLE_INIT_RUN << I3C_STBY_CR_CONTROL_ENABLE_INIT_SHIFT;
	write32(I3C_BASE + I3C_STBY_CR_CONTROL, val);

	/* Set static address. */
	val = read32(I3C_BASE + I3C_STBY_CR_DEVICE_ADDR);
	val &= ~(I3C_STBY_CR_DEVICE_ADDR_ADDR_MASK << I3C_STBY_CR_DEVICE_ADDR_STATIC_SHIFT);
	val |= STATIC_ADDR << I3C_STBY_CR_DEVICE_ADDR_STATIC_SHIFT;
	val |= I3C_STBY_CR_DEVICE_ADDR_STATIC_VALID;
	write32(I3C_BASE + I3C_STBY_CR_DEVICE_ADDR, val);

	/* Enable target interface and SETDASA for address assignment. */
	val = read32(I3C_BASE + I3C_STBY_CR_CONTROL);
	val |= I3C_STBY_CR_CONTROL_TARGET_XACT_ENABLE;
	val |= I3C_STBY_CR_CONTROL_DAA_SETDASA_ENABLE;
	write32(I3C_BASE + I3C_STBY_CR_CONTROL, val);

	/* Configure TTI thresholds. */
	val = read32(I3C_BASE + I3C_TTI_QUEUE_THLD_CTRL);
	val &= ~I3C_TTI_QUEUE_THLD_CTRL_RX_DESC_MASK;
	val |= I3C_TTI_QUEUE_THLD_CTRL_RX_DESC_INIT << I3C_TTI_QUEUE_THLD_CTRL_RX_DESC_SHIFT;
	write32(I3C_BASE + I3C_TTI_QUEUE_THLD_CTRL, val);

	val = read32(I3C_BASE + I3C_TTI_BUFFER_THLD_CTRL);
	val &= ~I3C_TTI_BUFFER_THLD_CTRL_RX_DATA_MASK;
	write32(I3C_BASE + I3C_TTI_BUFFER_THLD_CTRL, val);

	/* Enable RX and TX interrupts. */
	val = read32(I3C_BASE + I3C_TTI_INTERRUPT_ENABLE);
	val |= I3C_TTI_INTERRUPT_RX_DESC_STAT;
	val |= I3C_TTI_INTERRUPT_TX_DESC_STAT;
	write32(I3C_BASE + I3C_TTI_INTERRUPT_ENABLE, val);
}

void i3c_clear_dynamic_addr()
{
	uint32_t val = read32(I3C_BASE + I3C_STBY_CR_DEVICE_ADDR);
	val &= ~I3C_STBY_CR_DEVICE_ADDR_DYNAMIC_VALID;
	val &= ~(I3C_STBY_CR_DEVICE_ADDR_ADDR_MASK << I3C_STBY_CR_DEVICE_ADDR_DYNAMIC_SHIFT);
	write32(I3C_BASE + I3C_STBY_CR_DEVICE_ADDR, val);
}

int i3c_has_dynamic_addr()
{
	return (read32(I3C_BASE + I3C_STBY_CR_DEVICE_ADDR) & I3C_STBY_CR_DEVICE_ADDR_DYNAMIC_VALID) > 0;
}

uint8_t i3c_dynamic_addr()
{
	uint32_t val = read32(I3C_BASE + I3C_STBY_CR_DEVICE_ADDR);
	val >>= I3C_STBY_CR_DEVICE_ADDR_DYNAMIC_SHIFT;
	val &= I3C_STBY_CR_DEVICE_ADDR_ADDR_MASK;
	return val;
}

void i3c_wait_for_rx()
{
	while (!(read32(I3C_BASE + I3C_TTI_INTERRUPT_STATUS) & I3C_TTI_INTERRUPT_RX_DESC_STAT))
		;
}

void i3c_wait_for_tx()
{
	while (!(read32(I3C_BASE + I3C_TTI_INTERRUPT_STATUS) & I3C_TTI_INTERRUPT_TX_DESC_STAT))
		;
}

uint32_t i3c_pop_rx_desc()
{
	return read32(I3C_BASE + I3C_TTI_RX_DESC_QUEUE_PORT);
}

void i3c_push_tx_desc(uint32_t desc)
{
	return write32(I3C_BASE + I3C_TTI_TX_DESC_QUEUE_PORT, desc);
}

void i3c_read_rx_data(void *buf, size_t len)
{
	char *wr = buf;

	size_t progress = 0;
	while (progress < len) {
		size_t chunk = len - progress > 4 ? 4 : len - progress;
		uint32_t data = read32(I3C_BASE + I3C_TTI_RX_DATA_PORT);

		for (size_t i = 0; i < chunk; i++) {
			*wr++ = data & 0xFF;
			data >>= 8;
		}

		progress += chunk;
	}
}

void i3c_write_tx_data(const void *buf, size_t len)
{
	const char *rd = buf;

	size_t progress = 0;
	while (progress < len) {
		size_t chunk = len - progress > 4 ? 4 : len - progress;

		uint32_t data = 0;
		for (size_t i = 0; i < chunk; i++) {
			data |= (uint32_t)(*rd++) << (i * 8);
		}

		write32(I3C_BASE + I3C_TTI_TX_DATA_PORT, data);

		progress += chunk;
	}
}


/* ---------- Tests ---------- */

void test_i3c_setdasa()
{
	i3c_clear_dynamic_addr();

	printf("%02x\r\n", i3c_dynamic_addr());

	while(!i3c_has_dynamic_addr())
		;

	printf("%02x\r\n", i3c_dynamic_addr());
}

void test_i3c_read_write()
{
	i3c_wait_for_rx();

	uint32_t desc = i3c_pop_rx_desc();
	size_t len = desc & 0xFFFF;

	printf("%zd\r\n", len);

	char buf[16];
	i3c_read_rx_data(buf, len);

	for (size_t i = 0; i < len; i++)
		printf("%02x ", buf[i]);
	printf("\r\n");

	i3c_write_tx_data(buf, len);
	i3c_push_tx_desc(len);
}


int main(void)
{
	uart_init(UART_BAUD_RATE);
	i3c_init();

	printf("Hi Cocotb\r\n");

	int test = getchar();

	switch (test) {
	case '1': test_i3c_setdasa(); break;
	case '2': test_i3c_read_write(); break;
	default: printf("?\r\n"); break;
	}

	return 0;
}
