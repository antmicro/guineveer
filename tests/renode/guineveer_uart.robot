# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

*** Test Cases ***
Should Transmit And Receive UART data
    Execute Command           include "${CURDIR}/guineveer.resc"
    Create Terminal Tester    sysbus.uart
    Execute Command           start
    Wait For Line On Uart     Hello from core 1
    Wait For Line On Uart     Hello from core 0
