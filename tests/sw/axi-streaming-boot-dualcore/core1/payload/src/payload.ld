/* SPDX-License-Identifier: Apache-2.0 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
	ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x1f400
}

STACK_SIZE = 0x1000;

SECTIONS
{
	.text : ALIGN(8)
	{
		*(.text.init)
		*(.text*)
	} > ram

	.bss (NOLOAD) : ALIGN(8)
	{
		*(.bss)
		*(COMMON)
	} > ram

	.stack (NOLOAD) : ALIGN(8)
	{
		__stack_end = .;
		. += STACK_SIZE;
		__stack_start = .;
	} > ram

	.data : ALIGN(8)
	{
		*(.*data)
		*(.rodata*)
		*(.sbss)
	} > ram
}
