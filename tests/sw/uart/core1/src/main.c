#include <stdint.h>
#include "uart.h"
#include "printf.h"

int main(void)
{
	uart_init(UART_BAUD_RATE);
	printf("Hello from core 1\r\n");

	return 0;
}
