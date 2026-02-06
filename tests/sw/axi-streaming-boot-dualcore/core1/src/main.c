// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

#include "printf.h"
#include "payload.h"
#include <stdint.h>
#include <setjmp.h>
#include "i3c.h"

#include "utils.h"
#include "uart.h"

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
