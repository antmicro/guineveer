#include <stdint.h>
#include "printf.h"
#include "i3c_registers.h"

#define SOC_CLOCK_HZ	(32000000L)
#define UART_BASE_ADDR	(0x30000000)
#define UART_BAUD_RATE  (115200)
#define I3C_BASE_ADDR	(0x30001000)

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
volatile I3CCSR_t *i3c0 = (I3CCSR_t *)I3C_BASE_ADDR;

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

void _putchar(char character)
{
	while (!uart_tx_rdy())
		;

	uart_regs[UART_WDATA_REG] = character;
}

#define TTI_STRUCT_FIELD(a) i3c0->I3C_EC.TTI.a
#define RDL_GET_TTI_PROP(REG, FIELD, PROP) TARGETTRANSACTIONINTERFACEREGISTERS_RX_DESC_FIFO_SIZE_5_TX_DESC_FIFO_SIZE_5_RX_FIFO_SIZE_5_TX_FIFO_SIZE_5_IBI_FIFO_SIZE_5__##REG##__##FIELD##_##PROP
#define TTI_REG_FIELD_EXPECT(REG, FIELD, VAL) \
	reg_field_expect_value(#REG, #FIELD,\
			*(uint32_t *)(&TTI_STRUCT_FIELD(REG)),\
			RDL_GET_TTI_PROP(REG, FIELD, bm),\
			RDL_GET_TTI_PROP(REG, FIELD, bp),\
			RDL_GET_TTI_PROP(REG, FIELD, bw),\
			VAL\
	)
#define TTI_REG_FIELD_RESET_EXPECT(REG, FIELD) \
	reg_field_expect_value(#REG, #FIELD,\
			*(uint32_t *)(&TTI_STRUCT_FIELD(REG)),\
			RDL_GET_TTI_PROP(REG, FIELD, bm),\
			RDL_GET_TTI_PROP(REG, FIELD, bp),\
			RDL_GET_TTI_PROP(REG, FIELD, bw),\
			RDL_GET_TTI_PROP(REG, FIELD, reset)\
	)
#define TTI_REG_FIELD_TEST_READ_ONLY(REG, FIELD) \
	reg_field_test_read_only(#REG, #FIELD,\
			(uint32_t *)(&TTI_STRUCT_FIELD(REG)),\
			RDL_GET_TTI_PROP(REG, FIELD, bm)\
	)
#define TTI_REG_FIELD_TEST_WRITABLE(REG, FIELD) \
	reg_field_test_writable(#REG, #FIELD,\
			(uint32_t *)(&TTI_STRUCT_FIELD(REG)),\
			RDL_GET_TTI_PROP(REG, FIELD, bm),\
			RDL_GET_TTI_PROP(REG, FIELD, bp),\
			RDL_GET_TTI_PROP(REG, FIELD, bw),\
			RDL_GET_TTI_PROP(REG, FIELD, reset)\
	)

int reg_field_expect_value(const char *reg_name, const char *field_name,
		uint32_t reg, uint32_t bm, uint32_t bp, uint32_t bw,
		uint32_t reset)
{
	uint32_t val = (reg & bm) >> bp;

	printf("Testing the value of %s.%s... ", reg_name, field_name);

	if (val == reset) {
		printf("OK. (0x%x == 0x%x)\r\n", val, reset);
		return 0;
	} else {
		printf("Error! (expected %d; got %d)\r\n", reset, val);
		return 1;
	}
}

int reg_field_test_read_only(const char *reg_name, const char *field_name, uint32_t *reg, uint32_t bm)
{
	uint32_t reg_val = *reg;

	printf("Testing whether %s.%s is read-only... ", reg_name, field_name);
	
	*reg = ~reg_val & bm;
	if (*reg == reg_val) {
		printf("OK.\r\n");
		return 0;
	} else {
		printf("Error! (expected %d; got %d)\r\n", reg_val, *reg);
		return 1;
	}
}

int reg_field_test_writable(const char *reg_name, const char *field_name,
		uint32_t *reg, uint32_t bm, uint32_t bp, uint32_t bw,
		uint32_t reset)
{
	/* test whether we can flip all bits from the reset value */
	uint32_t val = (~reset << bp) & bm;
	*reg = (*reg & ~bm) | val;

	printf("Testing whether %s.%s is writable... ", reg_name, field_name);

	val = (*reg & bm) >> bp;
	if (val != reset) {
		printf("OK.\r\n");
		return 0;
	} else {
		printf("Error! (register value didn't change)\r\n");
		return 1;
	}
}

int test_reset_values(void)
{
	int ret = 0;

	printf("====================\r\n");
	printf("%s\r\n", __func__);
	printf("====================\r\n");

	ret += TTI_REG_FIELD_RESET_EXPECT(EXTCAP_HEADER, CAP_ID);
	ret += TTI_REG_FIELD_RESET_EXPECT(EXTCAP_HEADER, CAP_LENGTH);

	ret += TTI_REG_FIELD_RESET_EXPECT(CONTROL, HJ_EN);
	ret += TTI_REG_FIELD_RESET_EXPECT(CONTROL, CRR_EN);
	ret += TTI_REG_FIELD_RESET_EXPECT(CONTROL, IBI_EN);
	ret += TTI_REG_FIELD_RESET_EXPECT(CONTROL, IBI_RETRY_NUM);

	ret += TTI_REG_FIELD_RESET_EXPECT(RESET_CONTROL, SOFT_RST);
	ret += TTI_REG_FIELD_RESET_EXPECT(RESET_CONTROL, TX_DESC_RST);
	ret += TTI_REG_FIELD_RESET_EXPECT(RESET_CONTROL, RX_DESC_RST);
	ret += TTI_REG_FIELD_RESET_EXPECT(RESET_CONTROL, TX_DATA_RST);
	ret += TTI_REG_FIELD_RESET_EXPECT(RESET_CONTROL, RX_DATA_RST);
	ret += TTI_REG_FIELD_RESET_EXPECT(RESET_CONTROL, IBI_QUEUE_RST);

	return ret;
}

int test_read_only(void)
{
	int ret = 0;

	printf("====================\r\n");
	printf("%s\r\n", __func__);
	printf("====================\r\n");

	ret += TTI_REG_FIELD_TEST_READ_ONLY(EXTCAP_HEADER, CAP_ID);
	ret += TTI_REG_FIELD_TEST_READ_ONLY(EXTCAP_HEADER, CAP_LENGTH);

	ret += TTI_REG_FIELD_TEST_READ_ONLY(STATUS, PROTOCOL_ERROR);
	ret += TTI_REG_FIELD_TEST_READ_ONLY(STATUS, LAST_IBI_STATUS);

	ret += TTI_REG_FIELD_TEST_READ_ONLY(IBI_QUEUE_SIZE, IBI_QUEUE_SIZE);

	ret += TTI_REG_FIELD_TEST_READ_ONLY(QUEUE_SIZE, RX_DESC_BUFFER_SIZE);
	ret += TTI_REG_FIELD_TEST_READ_ONLY(QUEUE_SIZE, TX_DESC_BUFFER_SIZE);
	ret += TTI_REG_FIELD_TEST_READ_ONLY(QUEUE_SIZE, RX_DATA_BUFFER_SIZE);
	ret += TTI_REG_FIELD_TEST_READ_ONLY(QUEUE_SIZE, TX_DATA_BUFFER_SIZE);

	return ret;
}

int test_writable(void)
{
	int ret = 0;

	printf("====================\r\n");
	printf("%s\r\n", __func__);
	printf("====================\r\n");

	ret += TTI_REG_FIELD_TEST_WRITABLE(CONTROL, HJ_EN);
	ret += TTI_REG_FIELD_TEST_WRITABLE(CONTROL, CRR_EN);
	ret += TTI_REG_FIELD_TEST_WRITABLE(CONTROL, IBI_EN);
	ret += TTI_REG_FIELD_TEST_WRITABLE(CONTROL, IBI_RETRY_NUM);

	ret += TTI_REG_FIELD_TEST_WRITABLE(RESET_CONTROL, SOFT_RST);

	ret += TTI_REG_FIELD_TEST_WRITABLE(QUEUE_THLD_CTRL, TX_DESC_THLD);
	ret += TTI_REG_FIELD_TEST_WRITABLE(QUEUE_THLD_CTRL, RX_DESC_THLD);
	ret += TTI_REG_FIELD_TEST_WRITABLE(QUEUE_THLD_CTRL, IBI_THLD);

	ret += TTI_REG_FIELD_TEST_WRITABLE(DATA_BUFFER_THLD_CTRL, TX_DATA_THLD);
	ret += TTI_REG_FIELD_TEST_WRITABLE(DATA_BUFFER_THLD_CTRL, RX_DATA_THLD);
	ret += TTI_REG_FIELD_TEST_WRITABLE(DATA_BUFFER_THLD_CTRL, TX_START_THLD);
	ret += TTI_REG_FIELD_TEST_WRITABLE(DATA_BUFFER_THLD_CTRL, RX_START_THLD);

	return ret;
}

int test_intr_force(void)
{
	int ret = 0;

	printf("====================\r\n");
	printf("%s\r\n", __func__);
	printf("====================\r\n");

	printf("Enabling status and signal...\r\n");
	*(uint32_t *)&TTI_STRUCT_FIELD(INTERRUPT_ENABLE) = 0x82003f0f;

	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, TRANSFER_ERR_STAT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, TRANSFER_ABORT_STAT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, IBI_DONE_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, IBI_THLD_STAT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, RX_DESC_THLD_STAT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, TX_DESC_THLD_STAT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, RX_DATA_THLD_STAT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, TX_DATA_THLD_STAT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, TX_DESC_TIMEOUT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, RX_DESC_TIMEOUT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, TX_DESC_STAT_EN, 0x1);
	ret += TTI_REG_FIELD_EXPECT(INTERRUPT_ENABLE, RX_DESC_STAT_EN, 0x1);

	printf("Checking status...\r\n");
	ret += reg_field_expect_value("INTR_STATUS", "ALL", *(uint32_t *)&TTI_STRUCT_FIELD(INTERRUPT_STATUS), 0xffffffff, 0, 32, 0x0);

	printf("Forcing interrupts and verifying status...\r\n");
	*(uint32_t *)&TTI_STRUCT_FIELD(INTERRUPT_FORCE) = 0x82003f0f;
	// Only a subset of TTI interrupts are supported
	ret += reg_field_expect_value("INTR_STATUS", "ALL", *(uint32_t *)&TTI_STRUCT_FIELD(INTERRUPT_STATUS), 0xffffffff, 0, 32, 0x00002a03);

	return ret;
}

int main(void)
{
	int ret = 0;

	uart_init(UART_BAUD_RATE);
	printf("Hello I3C core test\r\n");

	ret += test_reset_values();
	ret += test_read_only();
	ret += test_writable();
	ret += test_intr_force();

	if (ret > 0)
		printf("Some test cases have failed: %d!\r\n", ret);

	printf("\r\n");

	return ret;
}
