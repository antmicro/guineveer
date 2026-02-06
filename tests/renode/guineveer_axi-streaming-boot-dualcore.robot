# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

*** Settings ***
Library     Dialogs

*** Test Cases ***
AXI Hello

    Execute Command	      $elf0=@${CURDIR}/../sw/build/core0/axi-streaming-boot-dualcore.elf
    Execute Command	      $elf1=@${CURDIR}/../sw/build/core1/axi-streaming-boot-dualcore.elf
    Execute Command           include "${CURDIR}/guineveer_i3c_cosim.resc"
    Create Terminal Tester    sysbus.uart  timeout=0.01
    Start Emulation

    Wait For Line On Uart     Hello from AXI streaming boot image.
