#include <stdint.h>
#include <setjmp.h>
#include "printf.h"
#include "i3c.h"
#include "utils.h"
#include "uart.h"

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

void test_i3c_getpid()
{
	(void)getchar();

	/* Write PID abccef012345. */

	uint32_t val = read32(I3C_BASE + I3C_STBY_CR_DEVICE_CHAR);
	val &= ~ I3C_STBY_CR_DEVICE_CHAR_PID_HI_MASK;
	val |= 0xabcc;
	write32(I3C_BASE + I3C_STBY_CR_DEVICE_CHAR, val);

	write32(I3C_BASE + I3C_STBY_CR_DEVICE_PID_LO, 0xef012345);

	printf("ok\r\n");
}

void test_i3c_getbcr()
{
	(void)getchar();

	uint32_t val = read32(I3C_BASE + I3C_STBY_CR_DEVICE_CHAR);
	val &= ~(I3C_STBY_CR_DEVICE_CHAR_BCR_MASK << I3C_STBY_CR_DEVICE_CHAR_BCR_SHIFT);
	val |= 0xd9 << I3C_STBY_CR_DEVICE_CHAR_BCR_SHIFT; /* Bitwise inverse of reset value. */
	write32(I3C_BASE + I3C_STBY_CR_DEVICE_CHAR, val);

	printf("ok\r\n");
}

void test_i3c_getdcr()
{
	(void)getchar();

	uint32_t val = read32(I3C_BASE + I3C_STBY_CR_DEVICE_CHAR);
	val &= ~(I3C_STBY_CR_DEVICE_CHAR_DCR_MASK << I3C_STBY_CR_DEVICE_CHAR_DCR_SHIFT);
	val |= 0x42 << I3C_STBY_CR_DEVICE_CHAR_DCR_SHIFT; /* Bitwise inverse of reset value. */
	write32(I3C_BASE + I3C_STBY_CR_DEVICE_CHAR, val);

	printf("ok\r\n");
}

#define MAX_STREAMING_BOOT_SIZE 0x1000
extern uint8_t streaming_boot_buffer[MAX_STREAMING_BOOT_SIZE];

int cur_task = -1;
jmp_buf task_jmpbufs[2];

void yield()
{
	if (cur_task == -1)
		return;

	if (setjmp(task_jmpbufs[cur_task]))
		return;

	cur_task = (cur_task + 1) % 2;
	longjmp(task_jmpbufs[cur_task], 1);
}


void test_i3c_streaming_boot()
{
	/* Wait for RA to request management interface reset. */
	while (1) {
		uint32_t val = read32(I3C_BASE + I3C_SECFW_DEVICE_RESET);
		uint32_t reset = val & I3C_SECFW_DEVICE_RESET_CTRL_MASK;

		if (reset)
			break;
		yield();
	}

	uint32_t val = read32(I3C_BASE + I3C_SECFW_DEVICE_RESET);
	uint32_t reset = val & I3C_SECFW_DEVICE_RESET_CTRL_MASK;
	uint32_t forced = (val >> I3C_SECFW_DEVICE_RESET_FORCED_SHIFT) & I3C_SECFW_DEVICE_RESET_FORCED_MASK;

	yield();

	/* Enter streaming boot mode if requested. */
	if (forced == I3C_SECFW_DEVICE_RESET_FORCED_STREAMING_BOOT) {
		write32(I3C_BASE + I3C_SECFW_DEVICE_STATUS_0,
			I3C_SECFW_DEV_STATUS_RECOVERY_READY | I3C_SECFW_REC_REASON_STREAMING_BOOT);

		write32(I3C_BASE + I3C_SECFW_RECOVERY_STATUS, I3C_SECFW_RECOVERY_STATUS_AWAITING);
	}

	yield();

	/* Clear reset. */
	write32(I3C_BASE + I3C_SECFW_DEVICE_RESET, val);

	yield();

	/* Wait for image size to be set. */
	size_t image_size = 0;
	while (!(image_size = read32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_CTRL_1)))
		yield();
	image_size *= 4;  /* INDIRECT_FIFO_CTRL_1 is in 4B word units. */

	yield();

	/* Bail out if the image is too large. */
	if (image_size > MAX_STREAMING_BOOT_SIZE) {
		write32(I3C_BASE + I3C_SECFW_RECOVERY_STATUS, I3C_SECFW_RECOVERY_STATUS_FAILED);
		return;
	}

	yield();

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
			yield();
		}

		yield();
	}

	yield();

	/* Wait for boot request. */
	while (1) {
		uint32_t val = read32(I3C_BASE + I3C_SECFW_RECOVERY_CONTROL);
		if (val & I3C_SECFW_RECOVERY_CONTROL_ACTIVATE)
			break;

		yield();
	}

	/* Clear image activation. */
	write32(I3C_BASE + I3C_SECFW_RECOVERY_CONTROL, I3C_SECFW_RECOVERY_CONTROL_ACTIVATE);

	/* Notify sender of success. */
	write32(I3C_BASE + I3C_SECFW_RECOVERY_STATUS, I3C_SECFW_RECOVERY_STATUS_SUCCESSFUL);

	yield();

	((void(*)(void))streaming_boot_buffer)();
}

const uint8_t axi_recovery_image[] = {
	/* _start: */
	/*   lui a5, 0x30000 */
	0xb7, 0x07, 0x00, 0x30,
	/* 1:auipc a4, %pcrel_hi(_str) */
	0x17, 0x07, 0x00, 0x00,
	/*   addi a4, a4, %pcrel_lo(1b) */
	0x13, 0x07, 0x87, 0x03,
	/* _print: */
	/*   lb a0, 0(a4) */
	0x03, 0x05, 0x07, 0x00,
	/*   beqz a0, _halt */
	0x63, 0x02, 0x05, 0x02,
	/*   addi a4, a4, 1 */
	0x13, 0x07, 0x17, 0x00,
	/*   jal _putchar */
	0xef, 0x00, 0x80, 0x00,
	/*   j _print */
	0x6f, 0xf0, 0x1f, 0xff,
	/* _putchar: */
	/*   lw a1, 20(a5) */
	0x83, 0xa5, 0x47, 0x01,
	/*   andi a1, a1, 8 */
	0x93, 0xf5, 0x85, 0x00,
	/*   beqz a1, _putchar */
	0xe3, 0x8c, 0x05, 0xfe,
	/*   sw a0, 28(a5) */
	0x23, 0xae, 0xa7, 0x00,
	/*   ret */
	0x67, 0x80, 0x00, 0x00,
	/* _halt: */
	/*   wfi */
	0x73, 0x00, 0x50, 0x10,
	/*   j _halt */
	0x6f, 0xf0, 0xdf, 0xff,
	/* _str: */
	/*   .asciz "Hello from AXI streaming boot image.\r\n" */
	'H', 'e', 'l', 'l', 'o', ' ', 'f', 'r', 'o', 'm', ' ', 'A', 'X', 'I', ' ', 's', 't', 'r', 'e',
	'a', 'm', 'i', 'n', 'g', ' ', 'b', 'o', 'o', 't', ' ', 'i', 'm', 'a', 'g', 'e', '.', '\r', '\n',
	0x00, 0x00
};

uint8_t axi_streaming_boot_writer_stack[0x1000] __attribute__((aligned(0x1000)));
void axi_streaming_boot_writer()
{
	const size_t len = sizeof(axi_recovery_image);

	yield();

	/* Enable AXI bypass. */
	uint32_t val = read32(I3C_BASE + I3C_SOCMGMT_REC_INTF_CFG);
	val |= I3C_SOCMGMT_REC_INTF_CFG_BYPASS;
	write32(I3C_BASE + I3C_SOCMGMT_REC_INTF_CFG, val);

	yield();

	/* Enter streaming boot on next reset. */
	write32(I3C_BASE + I3C_SECFW_DEVICE_RESET,
		I3C_SECFW_DEVICE_RESET_FORCED_STREAMING_BOOT << I3C_SECFW_DEVICE_RESET_FORCED_SHIFT);

	yield();

	/* Perform a management reset. */
	write32(I3C_BASE + I3C_SOCMGMT_REC_INTF_REG_W1C_ACCESS,
		I3C_SOCMGMT_REC_INTF_REG_DEVICE_MGMT_RESET);

	yield();

	/* Wait for device to enter recovery mode. */
	while (1) {
		uint32_t val = read32(I3C_BASE + I3C_SECFW_DEVICE_STATUS_0);

		if (val == I3C_SECFW_DEV_STATUS_RECOVERY_READY | I3C_SECFW_REC_REASON_STREAMING_BOOT)
			break;
		yield();
	}

	yield();

	write32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_CTRL_1, (len + 3) / 4);

	yield();

	/* Send the image. */
	size_t progress = 0;
	while (progress < len) {
		while (!(read32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_STATUS_0)
			& I3C_SECFW_INDIRECT_FIFO_EMPTY))
			yield();

		while (progress < len && !(read32(I3C_BASE + I3C_SECFW_INDIRECT_FIFO_STATUS_0)
				& I3C_SECFW_INDIRECT_FIFO_FULL)) {
			size_t chunk = len - progress > 4 ? 4 : len - progress;

			uint32_t data = 0;
			for (size_t i = 0; i < chunk; i++) {
				data |= (uint32_t)(axi_recovery_image[progress++]) << (i * 8);
			}

			write32(I3C_BASE + I3C_TTI_TX_DATA_PORT, data);
		}
	}

	yield();

	/* Boot the written image. */
	write32(I3C_BASE + I3C_SOCMGMT_REC_INTF_REG_W1C_ACCESS,
		I3C_SOCMGMT_REC_INTF_REG_ACTIVATE_IMAGE);

	yield();

	/* Wait for the image to be booted. */
	while (1) {
		uint32_t val = read32(I3C_BASE + I3C_SECFW_RECOVERY_STATUS);

		if (val == I3C_SECFW_RECOVERY_STATUS_FAILED) {
			printf("Boot failed!\r\n");
			break;
		} else if (val == I3C_SECFW_RECOVERY_STATUS_SUCCESSFUL) {
			break;
		}

		yield();
	}

	/* Hang forever, just in case the other side yields again. */
	while (1) {
		yield();
	}
}

void test_axi_streaming_boot()
{
	cur_task = 0;

	/* Set up the AXI streaming boot writer. */
	if(!setjmp(task_jmpbufs[cur_task])) {
		cur_task = 1;
		/* Run on separate stack. */
		asm volatile (
			     "mv sp, %0" "\n"
			"\t" "jalr %1"   "\n"
			"\t" "unimp"
			     :
			     : "r"(axi_streaming_boot_writer_stack),
			       "r"(axi_streaming_boot_writer)
			     : "memory");
		__builtin_unreachable();
	}

	/* Use the same receiver code as the I3C streaming boot test. */
	test_i3c_streaming_boot();
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
	case 'p': test_i3c_getpid(); break;
	case 'b': test_i3c_getbcr(); break;
	case 'd': test_i3c_getdcr(); break;
	case 'B': test_i3c_streaming_boot(); break;
	case 'A': test_axi_streaming_boot(); break;
	default: printf("?\r\n"); break;
	}

	return 0;
}
