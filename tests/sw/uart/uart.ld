/* SPDX-License-Identifier: Apache-2.0 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
	ram (rwx) : ORIGIN = 0x80000000, LENGTH = 0x1000000
	mailbox (rw) : ORIGIN = 0x80f80000, LENGTH = 0x8
}

STACK_SIZE = 0x1000;

SECTIONS
{
	.text :
	{
		*(.text.init)
		*(.text*)
	} > ram

	.bss (NOLOAD) :
	{
		*(.bss)
		*(COMMON)
	} > ram

	.stack (NOLOAD) :
	{
		__stack_end = .;
		. += STACK_SIZE;
		__stack_start = .;
	} > ram

	.data :
	{
		*(.*data)
		*(.rodata*)
		*(.sbss)
	} > ram

	.data.mailbox :
	{
		*(.data.mailbox)
	} > mailbox
}
