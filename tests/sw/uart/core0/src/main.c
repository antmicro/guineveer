// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

#include <stdint.h>
#include "uart.h"
#include "printf.h"

int main(void)
{
	int i = 0;
	while(i <= 5000) {
		i++;
	} //Wait for second core to print
	uart_init(UART_BAUD_RATE);
	printf("Hello from core 0\r\n");

	return 0;
}
