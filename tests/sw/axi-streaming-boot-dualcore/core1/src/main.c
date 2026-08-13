// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>


#include <stdint.h>
#include <stddef.h>
#include "i3c.h"
#include "uart.h"
#include "printf.h"
#include "payload.h"

static void image_provider(const uint8_t *image, size_t len)
{
	I3C_FIELD_WRITE(I3C_EC.SoCMgmtIf.REC_INTF_CFG, 0x1u, SOCMGMTIF, REC_INTF_CFG,
	       REC_INTF_BYPASS);

	while (!I3C_FIELD_EQ(I3C_EC.SecFwRecoveryIf.DEVICE_STATUS_0,
		      I3C_SECFW_DEV_STATUS_RECOVERY_READY,
		      SECFWRECOVERYIF, DEVICE_STATUS_0, DEV_STATUS))
		;

	while (!I3C_FIELD_EQ(I3C_EC.SecFwRecoveryIf.RECOVERY_STATUS,
		      I3C_SECFW_RECOVERY_STATUS_AWAITING,
		      SECFWRECOVERYIF, RECOVERY_STATUS, DEV_REC_STATUS))
		;

	I3C_WRITE(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_CTRL_0, 0);
	I3C_WRITE(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_CTRL_1, 0);

	I3C_FIELD_WRITE(I3C_EC.SoCMgmtIf.REC_INTF_REG_W1C_ACCESS, 0x1u, SOCMGMTIF,
	       REC_INTF_REG_W1C_ACCESS, INDIRECT_FIFO_CTRL_RESET);

	I3C_FIELD_WRITE(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_CTRL_1, len, SECFWRECOVERYIF,
	       INDIRECT_FIFO_CTRL_1, IMAGE_SIZE);

	I3C_FIELD_WRITE(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_CTRL_0, 0xFFu, SECFWRECOVERYIF,
	       INDIRECT_FIFO_CTRL_0, RESET);

	uint32_t max_xfer = I3C_READ(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_STATUS_4);
	if (max_xfer == 0)
		max_xfer = 0x40;

	size_t total_dwords = (len + 3u) / 4u;

	for (size_t data_ptr = 0; data_ptr < total_dwords; data_ptr += max_xfer) {
		size_t dwords_left = total_dwords - data_ptr;
		size_t chunk = max_xfer < dwords_left ? max_xfer : dwords_left;

		for (size_t i = 0; i < chunk; i++) {
			size_t off = (data_ptr + i) * 4u;
			uint32_t data = 0;
			for (size_t b = 0; b < 4u; b++) {
				size_t byte_idx = off + b;
				if (byte_idx < len)
					data |= (uint32_t)image[byte_idx] << (b * 8u);
			}
			I3C_WRITE(I3C_EC.TTI.TX_DATA_PORT, data);
		}

		if (data_ptr + chunk >= total_dwords)
			I3C_FIELD_WRITE(I3C_EC.SoCMgmtIf.REC_INTF_CFG, 0x1u, SOCMGMTIF,
			       REC_INTF_CFG, REC_PAYLOAD_DONE);

		while (!(I3C_READ(I3C_EC.SecFwRecoveryIf.INDIRECT_FIFO_STATUS_0)
			 & I3C_FIELD(SECFWRECOVERYIF, INDIRECT_FIFO_STATUS_0, EMPTY, bm)))
			;
	}

	I3C_FIELD_WRITE(I3C_EC.SoCMgmtIf.REC_INTF_REG_W1C_ACCESS,
	       I3C_SECFW_RECOVERY_CONTROL_ACTIVATE,
	       SOCMGMTIF, REC_INTF_REG_W1C_ACCESS, RECOVERY_CTRL_ACTIVATE_REC_IMG);

	while (!I3C_FIELD_EQ(I3C_EC.SecFwRecoveryIf.RECOVERY_STATUS,
		      I3C_SECFW_RECOVERY_STATUS_PROCESSING,
		      SECFWRECOVERYIF, RECOVERY_STATUS, DEV_REC_STATUS))
		;

	for (;;) {
		uint32_t st;
		st = I3C_READ(I3C_EC.SecFwRecoveryIf.DEVICE_STATUS_0);
		st &= I3C_FIELD(SECFWRECOVERYIF, DEVICE_STATUS_0, DEV_STATUS, bm);
		if (st == ((uint32_t)I3C_SECFW_DEV_STATUS_DEVICE_HEALTHY
			   << I3C_FIELD(SECFWRECOVERYIF, DEVICE_STATUS_0, DEV_STATUS, bp))) {
			//Boot successful
			break;
		}
		if (st == ((uint32_t)I3C_SECFW_DEV_STATUS_ERROR
			   << I3C_FIELD(SECFWRECOVERYIF, DEVICE_STATUS_0, DEV_STATUS, bp))) {
			printf("Boot failed!\r\n");
			break;
		}
	}
}

int main(void)
{
	uart_init(UART_BAUD_RATE);
	image_provider(payload, payload_len);
	return 0;
}
