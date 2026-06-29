# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Antmicro <www.antmicro.com>

*** Test Cases ***
Readable Register From Both Cores
    Execute Command	      $elf0=@${CURDIR}/../sw/build/core0/i3c-dualcore.elf
    Execute Command	      $elf1=@${CURDIR}/../sw/build/core1/i3c-dualcore.elf
    Execute Command           include "${CURDIR}/guineveer.resc"
    Create Terminal Tester    sysbus.uart_core
    Execute Command           start

    Wait For Line On Uart     Testing the value of CONTROL.HJ_EN... OK.
    Wait For Line On Uart     Testing the value of CONTROL.CRR_EN... OK.
    Wait For Line On Uart     Testing the value of CONTROL.IBI_EN... OK.
    Wait For Line On Uart     Testing the value of CONTROL.IBI_RETRY_NUM... OK.
    Wait For Line On Uart     Testing the value of RESET_CONTROL.SOFT_RST... OK.
    Wait For Line On Uart     Testing the value of QUEUE_THLD_CTRL.TX_DESC_THLD... OK.
    Wait For Line On Uart     Testing the value of QUEUE_THLD_CTRL.RX_DESC_THLD... OK.
    Wait For Line On Uart     Testing the value of QUEUE_THLD_CTRL.IBI_THLD... OK.
    Wait For Line On Uart     Testing the value of DATA_BUFFER_THLD_CTRL.TX_DATA_THLD... OK.
    Wait For Line On Uart     Testing the value of DATA_BUFFER_THLD_CTRL.RX_DATA_THLD... OK.
    Wait For Line On Uart     Testing the value of DATA_BUFFER_THLD_CTRL.TX_START_THLD... OK.
    Wait For Line On Uart     Testing the value of DATA_BUFFER_THLD_CTRL.RX_START_THLD... OK.

