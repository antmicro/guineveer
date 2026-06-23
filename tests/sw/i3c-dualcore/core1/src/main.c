// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Antmicro <www.antmicro.com>

#include <stdint.h>
#include "printf.h"
#include "i3c_registers.h"
#include "uart.h"
#include "i3c.h"

volatile I3CCSR_t *i3c0 = (I3CCSR_t *)I3C_BASE;

#define TTI_STRUCT_FIELD(a) i3c0->I3C_EC.TTI.a
#define RDL_GET_TTI_PROP(REG, FIELD, PROP) TARGETTRANSACTIONINTERFACEREGISTERS_RX_DESC_FIFO_SIZE_5_TX_DESC_FIFO_SIZE_5_RX_FIFO_SIZE_5_TX_FIFO_SIZE_5_IBI_FIFO_SIZE_5__##REG##__##FIELD##_##PROP


#define TTI_REG_FIELD_SEND_FLIP(REG, FIELD) \
	reg_field_send_flip(\
			(uint32_t *)(&TTI_STRUCT_FIELD(REG)),\
			RDL_GET_TTI_PROP(REG, FIELD, bm),\
			RDL_GET_TTI_PROP(REG, FIELD, bp),\
			RDL_GET_TTI_PROP(REG, FIELD, bw),\
			RDL_GET_TTI_PROP(REG, FIELD, reset)\
	)

#define TTI_REG_FIELD_SEND_FLIP_CUSTOM_MASK(REG, FIELD, mask) \
	reg_field_send_flip(\
			(uint32_t *)(&TTI_STRUCT_FIELD(REG)),\
			mask,\
			RDL_GET_TTI_PROP(REG, FIELD, bp),\
			RDL_GET_TTI_PROP(REG, FIELD, bw),\
			RDL_GET_TTI_PROP(REG, FIELD, reset)\
	)

int reg_field_send_flip(
		uint32_t *reg, uint32_t bm, uint32_t bp, uint32_t bw,
		uint32_t reset)
{
	uint32_t val = (~reset << bp) & bm;
	*reg = (*reg & ~bm) | val;
}

void send_values(void)
{

	TTI_REG_FIELD_SEND_FLIP(CONTROL, HJ_EN);
	TTI_REG_FIELD_SEND_FLIP(CONTROL, CRR_EN);
	TTI_REG_FIELD_SEND_FLIP(CONTROL, IBI_EN);
	TTI_REG_FIELD_SEND_FLIP(CONTROL, IBI_RETRY_NUM);

	TTI_REG_FIELD_SEND_FLIP(RESET_CONTROL, SOFT_RST);

	TTI_REG_FIELD_SEND_FLIP_CUSTOM_MASK(QUEUE_THLD_CTRL, TX_DESC_THLD, 0x3f);
	TTI_REG_FIELD_SEND_FLIP_CUSTOM_MASK(QUEUE_THLD_CTRL, RX_DESC_THLD, 0x3f00);
	TTI_REG_FIELD_SEND_FLIP(QUEUE_THLD_CTRL, IBI_THLD);

  TTI_REG_FIELD_SEND_FLIP(DATA_BUFFER_THLD_CTRL, TX_DATA_THLD);
	TTI_REG_FIELD_SEND_FLIP(DATA_BUFFER_THLD_CTRL, RX_DATA_THLD);
	TTI_REG_FIELD_SEND_FLIP(DATA_BUFFER_THLD_CTRL, TX_START_THLD);
	TTI_REG_FIELD_SEND_FLIP(DATA_BUFFER_THLD_CTRL, RX_START_THLD);
}

int main(void)
{
	send_values();

	return 0;
}
