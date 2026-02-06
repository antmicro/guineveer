# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

.set MAILBOX, 0x80f80000

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

        # Map exit code: == 0 - success, != 0 - failure
        mv  a1, a0
        li  a0, 0xff # ok
        beq a1, x0, _finish
        li  a0, 1 # fail

.global _finish
_finish:
        la t0, MAILBOX
        sb a0, 0(t0) # Signal testbench termination
        beq x0, x0, _finish
        .rept 10
        nop
        .endr
