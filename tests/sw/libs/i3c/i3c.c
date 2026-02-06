// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

#include "i3c.h"

uint8_t streaming_boot_buffer[MAX_STREAMING_BOOT_SIZE] __attribute__((aligned(0x1000)));

void i3c_wait_for_payload_available()
{
	/* We don't have access to the out-of-band recovery_payload_available_o signal, so
	   synthesize it out of the events that cause it to be set. */
	while (1) {
		uint32_t val = read32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_STATUS_0);
		if (val & I3C_SECFW_INDIRECT_FIFO_FULL)
			return;

		val = read32(I3C_BASE + I3C_SECFW_RECOVERY_CONTROL);
		if (val & I3C_SECFW_RECOVERY_CONTROL_ACTIVATE)
			return;

	}
}

void start_streaming_boot_reciver()
{
	/* Wait for RA to request management interface reset. */
	while (1) {
		uint32_t val = read32(I3C_BASE + I3C_SECFW_DEVICE_RESET);
		uint32_t reset = val & I3C_SECFW_DEVICE_RESET_CTRL_MASK;

		if (reset)
			break;
	}

	uint32_t val = read32(I3C_BASE + I3C_SECFW_DEVICE_RESET);
	uint32_t reset = val & I3C_SECFW_DEVICE_RESET_CTRL_MASK;
	uint32_t forced = (val >> I3C_SECFW_DEVICE_RESET_FORCED_SHIFT) & I3C_SECFW_DEVICE_RESET_FORCED_MASK;

	/* Enter streaming boot mode if requested. */
	if (forced == I3C_SECFW_DEVICE_RESET_FORCED_STREAMING_BOOT) {
		write32(I3C_BASE + I3C_SECFW_RECOVERY_STATUS, I3C_SECFW_RECOVERY_STATUS_AWAITING);

		write32(I3C_BASE + I3C_SECFW_DEVICE_STATUS_0,
			I3C_SECFW_DEV_STATUS_RECOVERY_READY | I3C_SECFW_REC_REASON_STREAMING_BOOT);
	}

	/* Clear reset. */
	write32(I3C_BASE + I3C_SECFW_DEVICE_RESET, val);

	/* Wait for image size to be set. */
	size_t image_size = 0;
	while (!(image_size = read32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_CTRL_1)))
		;
	image_size *= 4;  /* INDIRECT_FIFO_CTRL_1 is in 4B word units. */

	/* Bail out if the image is too large. */
	if (image_size > MAX_STREAMING_BOOT_SIZE) {
		write32(I3C_BASE + I3C_SECFW_RECOVERY_STATUS, I3C_SECFW_RECOVERY_STATUS_FAILED);
		return;
	}

	/* Receive recovery image. */
	size_t progress = 0;
	while (progress < image_size) {
		i3c_wait_for_payload_available();

		while (!(read32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_STATUS_0)
			& I3C_SECFW_INDIRECT_FIFO_EMPTY)) {
			uint32_t data = read32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_DATA);

			for (size_t i = 0; i < 4; i++) {
				streaming_boot_buffer[progress++] = data & 0xFF;
				data >>= 8;
			}
		}

	}

	/* Wait for boot request. */
	while (1) {
		uint32_t val = read32(I3C_BASE + I3C_SECFW_RECOVERY_CONTROL);
		if (val & I3C_SECFW_RECOVERY_CONTROL_ACTIVATE)
			break;
	}

	/* Clear image activation. */
	write32(I3C_BASE + I3C_SECFW_RECOVERY_CONTROL, I3C_SECFW_RECOVERY_CONTROL_ACTIVATE);

	/* Notify sender of success. */
	write32(I3C_BASE + I3C_SECFW_RECOVERY_STATUS, I3C_SECFW_RECOVERY_STATUS_SUCCESSFUL);

	((void(*)(void))streaming_boot_buffer)();
}

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

	/* Set virtual static address. */
	val = read32(I3C_BASE + I3C_STBY_CR_VIRT_DEVICE_ADDR);
	val &= ~(I3C_STBY_CR_DEVICE_ADDR_ADDR_MASK << I3C_STBY_CR_DEVICE_ADDR_STATIC_SHIFT);
	val |= VIRT_STATIC_ADDR << I3C_STBY_CR_DEVICE_ADDR_STATIC_SHIFT;
	val |= I3C_STBY_CR_DEVICE_ADDR_STATIC_VALID;
	write32(I3C_BASE + I3C_STBY_CR_VIRT_DEVICE_ADDR, val);

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

	/* Program recovery interface capabilities. */
	val = 0;
	val |= I3C_SECFW_PROT_CAP_VERSION_1p1;
	val |= I3C_SECFW_PROT_CAP_DEVICE_ID;
	val |= I3C_SECFW_PROT_CAP_FORCED_RECOVERY;
	val |= I3C_SECFW_PROT_CAP_MGMT_RESET;
	val |= I3C_SECFW_PROT_CAP_DEVICE_STATUS;
	val |= I3C_SECFW_PROT_CAP_INDIRECT_CTRL;
	val |= I3C_SECFW_PROT_CAP_PUSH_CIMAGE_SUPPORT;
	val |= I3C_SECFW_PROT_CAP_FLASHLESS_BOOT;
	write32(I3C_BASE + I3C_SECFW_PROT_CAP_2, val);
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
