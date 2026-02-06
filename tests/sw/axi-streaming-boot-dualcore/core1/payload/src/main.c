// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

#include "uart.h"

int main() {
  static const char text[] = "Hello from AXI streaming boot image.\r\n";
  for(int i = 0; text[i] != '\0'; i++) {
    _putchar(text[i]);
  }
}
