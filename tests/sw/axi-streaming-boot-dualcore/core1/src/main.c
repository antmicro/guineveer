#include "printf.h"
#include <stdint.h>
#include "payload.h"

#include <stdint.h>
#include <setjmp.h>
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
#define I3C_STBY_CR_VIRT_DEVICE_ADDR		(0x1b8)
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

#define I3C_SECFW_PROT_CAP_2			(0x10c)
#define  I3C_SECFW_PROT_CAP_VERSION_1p1		(0x0101)
#define  I3C_SECFW_PROT_CAP_DEVICE_ID		(1 << 16)
#define  I3C_SECFW_PROT_CAP_FORCED_RECOVERY	(1 << 17)
#define  I3C_SECFW_PROT_CAP_MGMT_RESET		(1 << 18)
#define  I3C_SECFW_PROT_CAP_DEVICE_STATUS	(1 << 20)
#define  I3C_SECFW_PROT_CAP_INDIRECT_CTRL	(1 << 21)
#define  I3C_SECFW_PROT_CAP_PUSH_CIMAGE_SUPPORT	(1 << 23)
#define  I3C_SECFW_PROT_CAP_FLASHLESS_BOOT	(1 << 27)
#define I3C_SECFW_DEVICE_STATUS_0		(0x130)
#define  I3C_SECFW_DEV_STATUS_RECOVERY_READY	(0x03)
#define  I3C_SECFW_REC_REASON_STREAMING_BOOT	(0x0012 << 16)
#define I3C_SECFW_DEVICE_RESET			(0x138)
#define  I3C_SECFW_DEVICE_RESET_CTRL_MASK	(0xff)
#define  I3C_SECFW_DEVICE_RESET_CTRL_SHIFT	(0)
#define  I3C_SECFW_DEVICE_RESET_FORCED_MASK	(0xff)
#define  I3C_SECFW_DEVICE_RESET_FORCED_SHIFT	(8)
#define  I3C_SECFW_DEVICE_RESET_FORCED_STREAMING_BOOT	(0x0e)
#define I3C_SECFW_RECOVERY_CONTROL		(0x13c)
#define  I3C_SECFW_RECOVERY_CONTROL_ACTIVATE	(0x0f << 16)
#define I3C_SECFW_RECOVERY_STATUS		(0x140)
#define  I3C_SECFW_RECOVERY_STATUS_AWAITING	(0x01)
#define  I3C_SECFW_RECOVERY_STATUS_SUCCESSFUL	(0x03)
#define  I3C_SECFW_RECOVERY_STATUS_FAILED	(0x0c)
#define I3C_SECFW_INDIRECT_FIFO_CTRL_1		(0x14c)
#define I3C_SECFW_INDIRECT_FIFO_STATUS_0	(0x150)
#define  I3C_SECFW_INDIRECT_FIFO_EMPTY		(1 << 0)
#define  I3C_SECFW_INDIRECT_FIFO_FULL		(1 << 1)
#define I3C_SECFW_INDIRECT_FIFO_DATA		(0x168)

#define I3C_SOCMGMT_REC_INTF_CFG		(0x20c)
#define  I3C_SOCMGMT_REC_INTF_CFG_BYPASS	(1 << 0)
#define  I3C_SOCMGMT_REC_INTF_CFG_PAYLOAD_DONE	(1 << 1)
#define I3C_SOCMGMT_REC_INTF_REG_W1C_ACCESS	(0x210)
#define  I3C_SOCMGMT_REC_INTF_REG_DEVICE_MGMT_RESET	(0x02 << 0)
#define  I3C_SOCMGMT_REC_INTF_REG_ACTIVATE_IMAGE	(0x0f << 8)


#define STATIC_ADDR (0x5A)
#define VIRT_STATIC_ADDR (0x6A)

void axi_streaming_boot_writer()
{
	const size_t len = sizeof(payload);

	/* Enable AXI bypass. */
	// i3c-core docs: (1) - Set the I3C block to the "direct AXI" mode
	uint32_t val = read32(I3C_BASE + I3C_SOCMGMT_REC_INTF_CFG);
	val |= I3C_SOCMGMT_REC_INTF_CFG_BYPASS;
	write32(I3C_BASE + I3C_SOCMGMT_REC_INTF_CFG, val);

	/* Enter streaming boot on next reset. */
	// i3c-core docs: Cant find
	write32(I3C_BASE + I3C_SECFW_DEVICE_RESET,
		I3C_SECFW_DEVICE_RESET_FORCED_STREAMING_BOOT << I3C_SECFW_DEVICE_RESET_FORCED_SHIFT);

	/* Perform a management reset. */
	// i3c-core docs: Cant find
	write32(I3C_BASE + I3C_SOCMGMT_REC_INTF_REG_W1C_ACCESS,
		I3C_SOCMGMT_REC_INTF_REG_DEVICE_MGMT_RESET);

	/* Wait for device to enter recovery mode. */
	// i3c-core docs: (2) - Pool the DEVICE_STATUS_0 register
	while (1) {
		uint32_t val = read32(I3C_BASE + I3C_SECFW_DEVICE_STATUS_0);

		if (val == (I3C_SECFW_DEV_STATUS_RECOVERY_READY | I3C_SECFW_REC_REASON_STREAMING_BOOT))
			break;
	}
	
	// i3c-core docs: (3) - read RECOVERY_STATUS register and check if recovery flow stared

	// i3c-core docs: (4) - Write to the RECOVERY_CTRL register to set the recovery image configuration
	// it is 0 as default, so there is no need to write to it

	// i3c-core docs: (5) - Write to the INDIRECT_FIFO_CTRL_0 register to reset the FIFO
	// it is 0 as default, so there is no need to write to it
	
	// i3c-core docs: (6) - Write to the INDIRECT_FIFO_CTRL_1 register to set the recovery image size
	write32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_CTRL_1, (len + 3) / 4);
	
	/* Send the image. */
	size_t progress = 0;
	while (progress < len) {
		while (!(read32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_STATUS_0)
			& I3C_SECFW_INDIRECT_FIFO_EMPTY))
			;

		while (progress < len && !(read32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_STATUS_0)
				& I3C_SECFW_INDIRECT_FIFO_FULL)) {
			size_t chunk = len - progress > 4 ? 4 : len - progress;

			uint32_t data = 0;
			for (size_t i = 0; i < chunk; i++) {
				data |= (uint32_t)(payload[progress++]) << (i * 8);
			}

			write32(I3C_BASE + I3C_TTI_TX_DATA_PORT, data);
		}
	}

	/* Boot the written image. */
	write32(I3C_BASE + I3C_SOCMGMT_REC_INTF_REG_W1C_ACCESS,
		I3C_SOCMGMT_REC_INTF_REG_ACTIVATE_IMAGE);

	/* Wait for the image to be booted. */
	while (1) {
		uint32_t val = read32(I3C_BASE + I3C_SECFW_RECOVERY_STATUS);

		if (val == I3C_SECFW_RECOVERY_STATUS_FAILED) {
			printf("Boot failed!\r\n");
			break;
		} else if (val == I3C_SECFW_RECOVERY_STATUS_SUCCESSFUL) {
			break;
		}
	}
}


int main(void)
{
	uart_init(UART_BAUD_RATE);
	axi_streaming_boot_writer();
	return 0;
}
