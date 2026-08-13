// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

#include "i3c.h"

uint8_t streaming_boot_buffer[MAX_STREAMING_BOOT_SIZE] __attribute__((aligned(0x1000)));

void i3c_wait_for_payload_available()
{
	/* We don't have access to the out-of-band recovery_payload_available_o signal, so
	   synthesize it out of the events that cause it to be set. */
	while (1) {
		uint32_t val = I3C_READ(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_STATUS_0);
		if (val & I3C_FIELD(SECFWRECOVERYIF, INDIRECT_FIFO_STATUS_0, FULL, bm))
			return;

		val = I3C_READ(I3C_EC.SecFwRecoveryIf.RECOVERY_CTRL);
		if (val & (I3C_SECFW_RECOVERY_CONTROL_ACTIVATE <<
			I3C_FIELD(SECFWRECOVERYIF, RECOVERY_CTRL, ACTIVATE_REC_IMG, bp)))
			return;

	}
}

void start_streaming_boot_reciver()
{
	/* Wait for RA to request management interface reset. */
	while (1) {
		uint32_t val = I3C_READ(I3C_EC.SecFwRecoveryIf.DEVICE_RESET);
		uint32_t reset = I3C_FIELD_GET(val, SECFWRECOVERYIF, DEVICE_RESET, RESET_CTRL);

		if (reset)
			break;
	}

	uint32_t val = I3C_READ(I3C_EC.SecFwRecoveryIf.DEVICE_RESET);
	uint32_t reset = I3C_FIELD_GET(val, SECFWRECOVERYIF, DEVICE_RESET, RESET_CTRL);
	uint32_t forced = I3C_FIELD_GET(val, SECFWRECOVERYIF, DEVICE_RESET, FORCED_RECOVERY);

	/* Enter streaming boot mode if requested. */
	if (forced == I3C_SECFW_DEVICE_RESET_FORCED_STREAMING_BOOT) {
		I3C_WRITE(I3C_EC.SecFwRecoveryIf.RECOVERY_STATUS,
			I3C_SECFW_RECOVERY_STATUS_AWAITING);

		I3C_WRITE(I3C_EC.SecFwRecoveryIf.DEVICE_STATUS_0,
			I3C_SECFW_DEV_STATUS_RECOVERY_READY |
			(I3C_SECFW_REC_REASON_STREAMING_BOOT <<
			 I3C_FIELD(SECFWRECOVERYIF, DEVICE_STATUS_0, REC_REASON_CODE, bp)));
	}

	/* Clear reset. */
	I3C_WRITE(I3C_EC.SecFwRecoveryIf.DEVICE_RESET, val);

	/* Wait for image size to be set. */
	size_t image_size = 0;
	while (!(image_size = I3C_READ(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_CTRL_1)))
		;
	image_size *= 4;  /* INDIRECT_FIFO_CTRL_1 is in 4B word units. */

	/* Bail out if the image is too large. */
	if (image_size > MAX_STREAMING_BOOT_SIZE) {
		I3C_WRITE(I3C_EC.SecFwRecoveryIf.RECOVERY_STATUS,
			I3C_SECFW_RECOVERY_STATUS_FAILED);
		return;
	}

	/* Receive recovery image. */
	size_t progress = 0;
	while (progress < image_size) {
		i3c_wait_for_payload_available();

		while (!(I3C_READ(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_STATUS_0)
			& I3C_FIELD(SECFWRECOVERYIF, INDIRECT_FIFO_STATUS_0, EMPTY, bm))) {
			uint32_t data = I3C_READ(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_DATA);

			for (size_t i = 0; i < 4; i++) {
				streaming_boot_buffer[progress++] = data & 0xFF;
				data >>= 8;
			}
		}

	}

	/* Wait for boot request. */
	while (1) {
		uint32_t val = I3C_READ(I3C_EC.SecFwRecoveryIf.RECOVERY_CTRL);
		if (val & (I3C_SECFW_RECOVERY_CONTROL_ACTIVATE <<
			I3C_FIELD(SECFWRECOVERYIF, RECOVERY_CTRL, ACTIVATE_REC_IMG, bp)))
			break;
	}

	/* Clear image activation. */
	I3C_WRITE(I3C_EC.SecFwRecoveryIf.RECOVERY_CTRL,
		I3C_SECFW_RECOVERY_CONTROL_ACTIVATE <<
		I3C_FIELD(SECFWRECOVERYIF, RECOVERY_CTRL, ACTIVATE_REC_IMG, bp));

	/* Notify sender of success. */
	I3C_WRITE(I3C_EC.SecFwRecoveryIf.RECOVERY_STATUS,
		I3C_SECFW_RECOVERY_STATUS_SUCCESSFUL);

	((void(*)(void))streaming_boot_buffer)();
}

void i3c_init()
{
	/* Program SDA/SCL timings. */
	/* TODO: Leave at 0 for now, as in the i3c-core tests. */

	/* Standby controller init. */
	uint32_t val = I3C_READ(I3C_EC.StdbyCtrlMode.STBY_CR_CONTROL);
	I3C_FIELD_SET(val, 2, STDBYCTRLMODE, STBY_CR_CONTROL, STBY_CR_ENABLE_INIT);
	I3C_WRITE(I3C_EC.StdbyCtrlMode.STBY_CR_CONTROL, val);

	/* Set static address. */
	val = I3C_READ(I3C_EC.StdbyCtrlMode.STBY_CR_DEVICE_ADDR);
	I3C_FIELD_SET(val, STATIC_ADDR, STDBYCTRLMODE, STBY_CR_DEVICE_ADDR, STATIC_ADDR);
	I3C_FIELD_SET(val, 1, STDBYCTRLMODE, STBY_CR_DEVICE_ADDR, STATIC_ADDR_VALID);
	I3C_WRITE(I3C_EC.StdbyCtrlMode.STBY_CR_DEVICE_ADDR, val);

	/* Set virtual static address. */
	val = I3C_READ(I3C_EC.StdbyCtrlMode.STBY_CR_VIRT_DEVICE_ADDR);
	I3C_FIELD_SET(val, VIRT_STATIC_ADDR, STDBYCTRLMODE, STBY_CR_VIRT_DEVICE_ADDR, VIRT_STATIC_ADDR);
	I3C_FIELD_SET(val, 1, STDBYCTRLMODE, STBY_CR_VIRT_DEVICE_ADDR, VIRT_STATIC_ADDR_VALID);
	I3C_WRITE(I3C_EC.StdbyCtrlMode.STBY_CR_VIRT_DEVICE_ADDR, val);

	/* Enable target interface and SETDASA for address assignment. */
	val = I3C_READ(I3C_EC.StdbyCtrlMode.STBY_CR_CONTROL);
	val |= I3C_FIELD(STDBYCTRLMODE, STBY_CR_CONTROL, TARGET_XACT_ENABLE, bm);
	val |= I3C_FIELD(STDBYCTRLMODE, STBY_CR_CONTROL, DAA_SETDASA_ENABLE, bm);
	I3C_WRITE(I3C_EC.StdbyCtrlMode.STBY_CR_CONTROL, val);

	/* Configure TTI thresholds. */
	val = I3C_READ(I3C_EC.TTI.QUEUE_THLD_CTRL);
	I3C_FIELD_SET(val, 1, TTI, QUEUE_THLD_CTRL, RX_DESC_THLD);
	I3C_WRITE(I3C_EC.TTI.QUEUE_THLD_CTRL, val);

	val = I3C_READ(I3C_EC.TTI.DATA_BUFFER_THLD_CTRL);
	val &= ~I3C_FIELD(TTI, DATA_BUFFER_THLD_CTRL, RX_DATA_THLD, bm);
	I3C_WRITE(I3C_EC.TTI.DATA_BUFFER_THLD_CTRL, val);

	/* Enable RX and TX interrupts. */
	val = I3C_READ(I3C_EC.TTI.INTERRUPT_ENABLE);
	val |= I3C_FIELD(TTI, INTERRUPT_ENABLE, RX_DESC_STAT_EN, bm);
	val |= I3C_FIELD(TTI, INTERRUPT_ENABLE, TX_DESC_STAT_EN, bm);
	I3C_WRITE(I3C_EC.TTI.INTERRUPT_ENABLE, val);

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
	I3C_WRITE(I3C_EC.SecFwRecoveryIf.PROT_CAP_2, val);
}

void i3c_clear_dynamic_addr()
{
	uint32_t val = I3C_READ(I3C_EC.StdbyCtrlMode.STBY_CR_DEVICE_ADDR);
	I3C_FIELD_SET(val, 0, STDBYCTRLMODE, STBY_CR_DEVICE_ADDR, DYNAMIC_ADDR_VALID);
	I3C_FIELD_SET(val, 0, STDBYCTRLMODE, STBY_CR_DEVICE_ADDR, DYNAMIC_ADDR);
	I3C_WRITE(I3C_EC.StdbyCtrlMode.STBY_CR_DEVICE_ADDR, val);
}

int i3c_has_dynamic_addr()
{
	return (I3C_READ(I3C_EC.StdbyCtrlMode.STBY_CR_DEVICE_ADDR) & I3C_FIELD(STDBYCTRLMODE, STBY_CR_DEVICE_ADDR, DYNAMIC_ADDR_VALID, bm)) > 0;
}

uint8_t i3c_dynamic_addr()
{
	uint32_t val = I3C_READ(I3C_EC.StdbyCtrlMode.STBY_CR_DEVICE_ADDR);
	return I3C_FIELD_GET(val, STDBYCTRLMODE, STBY_CR_DEVICE_ADDR, DYNAMIC_ADDR);
}

void i3c_wait_for_rx()
{
	while (!(I3C_READ(I3C_EC.TTI.INTERRUPT_STATUS) & I3C_FIELD(TTI, INTERRUPT_STATUS, RX_DESC_STAT, bm)))
		;
}

void i3c_wait_for_tx()
{
	while (!(I3C_READ(I3C_EC.TTI.INTERRUPT_STATUS) & I3C_FIELD(TTI, INTERRUPT_STATUS, TX_DESC_STAT, bm)))
		;
}

uint32_t i3c_pop_rx_desc()
{
	return I3C_READ(I3C_EC.TTI.RX_DESC_QUEUE_PORT);
}

void i3c_push_tx_desc(uint32_t desc)
{
	return I3C_WRITE(I3C_EC.TTI.TX_DESC_QUEUE_PORT, desc);
}

void i3c_read_rx_data(void *buf, size_t len)
{
	char *wr = buf;

	size_t progress = 0;
	while (progress < len) {
		size_t chunk = len - progress > 4 ? 4 : len - progress;
		uint32_t data = I3C_READ(I3C_EC.TTI.RX_DATA_PORT);

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

		I3C_WRITE(I3C_EC.TTI.TX_DATA_PORT, data);

		progress += chunk;
	}
}
