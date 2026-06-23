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

#define TTI_REG_FIELD_AWAIT_FLIP(REG, FIELD) \
	reg_field_await_flip(#REG, #FIELD,\
			(uint32_t *)(&TTI_STRUCT_FIELD(REG)),\
			RDL_GET_TTI_PROP(REG, FIELD, bm),\
			RDL_GET_TTI_PROP(REG, FIELD, bp),\
			RDL_GET_TTI_PROP(REG, FIELD, bw),\
			RDL_GET_TTI_PROP(REG, FIELD, reset)\
	)

#define TTI_REG_FIELD_AWAIT_FLIP_CUSTOM_MASK(REG, FIELD, mask) \
	reg_field_await_flip(#REG, #FIELD,\
			(uint32_t *)(&TTI_STRUCT_FIELD(REG)),\
			mask,\
			RDL_GET_TTI_PROP(REG, FIELD, bp),\
			RDL_GET_TTI_PROP(REG, FIELD, bw),\
			RDL_GET_TTI_PROP(REG, FIELD, reset)\
	)

int reg_field_await_flip(const char *reg_name, const char *field_name,
		uint32_t *reg, uint32_t bm, uint32_t bp, uint32_t bw,
		uint32_t reset)
{
	uint32_t expect = (~reset << bp) & bm;
	uint32_t reset_val = (reset << bp) & bm;

	printf("Testing the value of %s.%s... ", reg_name, field_name);

	uint32_t val;
	while ((val = (*reg & bm)) == reset_val) {}

	if (val == expect) {
		printf("OK.\r\n");
		return 0;
	} else {
		printf("Error! (expected %d; got %d)\r\n", expect >> bp, val >> bp);
		return 1;
	}
}

int test_recv_value(void)
{
	int ret = 0;

	printf("====================\r\n");
	printf("%s\r\n", __func__);
	printf("====================\r\n");

	ret += TTI_REG_FIELD_AWAIT_FLIP(CONTROL, HJ_EN);
	ret += TTI_REG_FIELD_AWAIT_FLIP(CONTROL, CRR_EN);
	ret += TTI_REG_FIELD_AWAIT_FLIP(CONTROL, IBI_EN);
	ret += TTI_REG_FIELD_AWAIT_FLIP(CONTROL, IBI_RETRY_NUM);

	ret += TTI_REG_FIELD_AWAIT_FLIP(RESET_CONTROL, SOFT_RST);

	ret += TTI_REG_FIELD_AWAIT_FLIP_CUSTOM_MASK(QUEUE_THLD_CTRL, TX_DESC_THLD, 0x3f);
	ret += TTI_REG_FIELD_AWAIT_FLIP_CUSTOM_MASK(QUEUE_THLD_CTRL, RX_DESC_THLD, 0x3f00);
	ret += TTI_REG_FIELD_AWAIT_FLIP(QUEUE_THLD_CTRL, IBI_THLD);

	ret += TTI_REG_FIELD_AWAIT_FLIP(DATA_BUFFER_THLD_CTRL, TX_DATA_THLD);
	ret += TTI_REG_FIELD_AWAIT_FLIP(DATA_BUFFER_THLD_CTRL, RX_DATA_THLD);
	ret += TTI_REG_FIELD_AWAIT_FLIP(DATA_BUFFER_THLD_CTRL, TX_START_THLD);
	ret += TTI_REG_FIELD_AWAIT_FLIP(DATA_BUFFER_THLD_CTRL, RX_START_THLD);

	return ret;
}

int main(void)
{
	int ret = 0;

	uart_init(UART_BAUD_RATE);

	ret += test_recv_value();

	if (ret > 0)
		printf("Some test cases have failed: %d!\r\n", ret);

	printf("\r\n");

	return ret;
}

