#ifndef UTILS_H
#define UTILS_H

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

#define SOC_CLOCK_HZ	(32000000L)

void write32(uint32_t address, uint32_t value);

uint32_t read32(uint32_t address);
#endif
