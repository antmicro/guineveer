# SPDX-License-Identifier: Apache-2.0

.section .text.init
.global _start
_start:
        # enable caching starting from region 0x8
        # put side effect in region 0x3
        li t0, 0x00010090
        csrw 0x7c0, t0
        # Setup stack
        la sp, __stack_start

        # Call main()
        call main

.global _finish
_finish:
        nop
        beq x0, x0, _finish
        .rept 10
        nop
        .endr
