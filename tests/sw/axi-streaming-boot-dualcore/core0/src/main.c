#include <stdint.h>
#include <setjmp.h>
#include "i3c.h"
#include "utils.h"
#include "uart.h"
#include "printf.h"

int main(void)
{
	uart_init(UART_BAUD_RATE);
	i3c_init();
	
	start_streaming_boot_reciver();

	return 0;
}
