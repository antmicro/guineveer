# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

*** Test Cases ***
Should Read Reset Values
    Execute Command	      $elf0=@${CURDIR}/../sw/build/core0/i3c.elf
    Execute Command	      $elf1=@${CURDIR}/../sw/build/core1/i3c.elf
    Execute Command           include "${CURDIR}/guineveer.resc"
    Create Terminal Tester    sysbus.uart
    Execute Command           start

    Wait For Line On Uart     Testing the value of EXTCAP_HEADER.CAP_ID... OK. (0xc4 == 0xc4)
    Wait For Line On Uart     Testing the value of EXTCAP_HEADER.CAP_LENGTH... OK. (0x10 == 0x10)
    Wait For Line On Uart     Testing the value of CONTROL.HJ_EN... OK. (0x1 == 0x1)
    Wait For Line On Uart     Testing the value of CONTROL.CRR_EN... OK. (0x0 == 0x0)
    Wait For Line On Uart     Testing the value of CONTROL.IBI_EN... OK. (0x1 == 0x1)
    Wait For Line On Uart     Testing the value of CONTROL.IBI_RETRY_NUM... OK. (0x0 == 0x0)
    Wait For Line On Uart     Testing the value of RESET_CONTROL.SOFT_RST... OK. (0x0 == 0x0)
    Wait For Line On Uart     Testing the value of RESET_CONTROL.TX_DESC_RST... OK. (0x0 == 0x0)
    Wait For Line On Uart     Testing the value of RESET_CONTROL.RX_DESC_RST... OK. (0x0 == 0x0)
    Wait For Line On Uart     Testing the value of RESET_CONTROL.TX_DATA_RST... OK. (0x0 == 0x0)
    Wait For Line On Uart     Testing the value of RESET_CONTROL.RX_DATA_RST... OK. (0x0 == 0x0)
    Wait For Line On Uart     Testing the value of RESET_CONTROL.IBI_QUEUE_RST... OK. (0x0 == 0x0)

Should Test Read Only
    Execute Command	      $elf0=@${CURDIR}/../sw/build/core0/i3c.elf
    Execute Command	      $elf1=@${CURDIR}/../sw/build/core1/i3c.elf
    Execute Command           include "${CURDIR}/guineveer.resc"
    Create Terminal Tester    sysbus.uart
    Execute Command           start

    Wait For Line On Uart     Testing whether EXTCAP_HEADER.CAP_ID is read-only... OK.
    Wait For Line On Uart     Testing whether EXTCAP_HEADER.CAP_LENGTH is read-only... OK.
    Wait For Line On Uart     Testing whether STATUS.PROTOCOL_ERROR is read-only... OK.
    Wait For Line On Uart     Testing whether STATUS.LAST_IBI_STATUS is read-only... OK.
    Wait For Line On Uart     Testing whether IBI_QUEUE_SIZE.IBI_QUEUE_SIZE is read-only... OK.
    Wait For Line On Uart     Testing whether QUEUE_SIZE.RX_DESC_BUFFER_SIZE is read-only... OK.
    Wait For Line On Uart     Testing whether QUEUE_SIZE.TX_DESC_BUFFER_SIZE is read-only... OK.
    Wait For Line On Uart     Testing whether QUEUE_SIZE.RX_DATA_BUFFER_SIZE is read-only... OK.
    Wait For Line On Uart     Testing whether QUEUE_SIZE.TX_DATA_BUFFER_SIZE is read-only... OK.

Should Test Writable
    Execute Command	      $elf0=@${CURDIR}/../sw/build/core0/i3c.elf
    Execute Command	      $elf1=@${CURDIR}/../sw/build/core1/i3c.elf
    Execute Command           include "${CURDIR}/guineveer.resc"
    Create Terminal Tester    sysbus.uart
    Execute Command           start

    Wait For Line On Uart     Testing whether CONTROL.HJ_EN is writable... OK.
    Wait For Line On Uart     Testing whether CONTROL.CRR_EN is writable... OK.
    Wait For Line On Uart     Testing whether CONTROL.IBI_EN is writable... OK.
    Wait For Line On Uart     Testing whether CONTROL.IBI_RETRY_NUM is writable... OK.
    Wait For Line On Uart     Testing whether RESET_CONTROL.SOFT_RST is writable... OK.
    Wait For Line On Uart     Testing whether QUEUE_THLD_CTRL.TX_DESC_THLD is writable... OK.
    Wait For Line On Uart     Testing whether QUEUE_THLD_CTRL.RX_DESC_THLD is writable... OK.
    Wait For Line On Uart     Testing whether QUEUE_THLD_CTRL.IBI_THLD is writable... OK.
    Wait For Line On Uart     Testing whether DATA_BUFFER_THLD_CTRL.TX_DATA_THLD is writable... OK.
    Wait For Line On Uart     Testing whether DATA_BUFFER_THLD_CTRL.RX_DATA_THLD is writable... OK.
    Wait For Line On Uart     Testing whether DATA_BUFFER_THLD_CTRL.TX_START_THLD is writable... OK.
    Wait For Line On Uart     Testing whether DATA_BUFFER_THLD_CTRL.RX_START_THLD is writable... OK.

Should Force Interrupts
    Execute Command	      $elf0=@${CURDIR}/../sw/build/core0/i3c.elf
    Execute Command	      $elf1=@${CURDIR}/../sw/build/core1/i3c.elf
    Execute Command           include "${CURDIR}/guineveer.resc"
    Create Terminal Tester    sysbus.uart
    Execute Command           start

    Wait For Line On Uart     Testing the value of INTR_STATUS.ALL... OK. (0x0 == 0x0)
    Wait For Line On Uart     Testing the value of INTR_STATUS.ALL... OK. (0x2a03 == 0x2a03)
