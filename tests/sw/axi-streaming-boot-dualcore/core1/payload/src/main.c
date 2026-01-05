#include "uart.h"

int main() {
  static const char text[] = "Hello from AXI streaming boot image.\r\n";
  for(int i = 0; text[i] != '\0'; i++) {
    _putchar(text[i]);
  }
}
