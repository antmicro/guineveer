#include "utils.h"

void write32(uint32_t address, uint32_t value)
{
	*(volatile uint32_t *)address = value;
}

uint32_t read32(uint32_t address)
{
	return *(volatile uint32_t *)address;
}
