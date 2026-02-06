// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

#include <stdint.h>
#include "uart.h"
#include "printf.h"

int main(void)
{
	uart_init(UART_BAUD_RATE);
	printf("Hello from core 1\r\n");

	return 0;
}
