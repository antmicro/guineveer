
.set MAILBOX, 0x80f80000

.global _start
.text

_start: 
       lui a5, 0x30000 
	 1:auipc a4, %pcrel_hi(_str) 
	   addi a4, a4, %pcrel_lo(1b) 
	 _print: 
	   lb a0, 0(a4) 
	   beqz a0, _halt 
	   addi a4, a4, 1 
	   jal _putchar 
	   j _print 
	 _putchar: 
	   lw a1, 20(a5) 
	   andi a1, a1, 8 
	   beqz a1, _putchar 
	   sw a0, 28(a5) 
	   ret 
	 _halt: 
          li  t0, 0xff
	   la t1, MAILBOX
	   sw t0, 0(t1)
	   wfi 
	   j _halt 
	 _str: 
	   .asciz "Hello from AXI streaming boot image.\r\n" 

                    
