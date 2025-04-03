*** Settings ***
Library     Dialogs

*** Test Cases ***
Should Read Reset Values
    Execute Command           $elf=@${CURDIR}/../i3c.elf
    Execute Command           include "${CURDIR}/guineveer_i3c_cosim.resc"
    Create Terminal Tester    sysbus.uart  timeout=0.01
    Start Emulation

    Wait For Line On Uart     HCI_VERSION.VERSION... OK.
    Wait For Line On Uart     HC_CONTROL.IBA_INCLUDE... OK.
    Wait For Line On Uart     HC_CONTROL.AUTOCMD_DATA_RPT... OK.
    Wait For Line On Uart     HC_CONTROL.DATA_BYTE_ORDER_MODE... OK.
    Wait For Line On Uart     HC_CONTROL.MODE_SELECTOR... OK.
    Wait For Line On Uart     HC_CONTROL.I2C_DEV_PRESENT... OK.
    Wait For Line On Uart     HC_CONTROL.HOT_JOIN_CTRL... OK.
    Wait For Line On Uart     HC_CONTROL.HALT_ON_CMD_SEQ_TIMEOUT... OK.
    Wait For Line On Uart     HC_CONTROL.ABORT... OK.
    Wait For Line On Uart     HC_CONTROL.RESUME... OK.
    Wait For Line On Uart     HC_CONTROL.BUS_ENABLE... OK.
    Wait For Line On Uart     CONTROLLER_DEVICE_ADDR.DYNAMIC_ADDR... OK.
    Wait For Line On Uart     CONTROLLER_DEVICE_ADDR.DYNAMIC_ADDR_VALID... OK.
    Wait For Line On Uart     HC_CAPABILITIES.COMBO_COMMAND... OK.
    Wait For Line On Uart     HC_CAPABILITIES.AUTO_COMMAND... OK.
    Wait For Line On Uart     HC_CAPABILITIES.STANDBY_CR_CAP... OK.
    Wait For Line On Uart     HC_CAPABILITIES.CMD_SIZE... OK.
    Wait For Line On Uart     HC_CAPABILITIES.SG_CAPABILITY_CR_EN... OK.
    Wait For Line On Uart     HC_CAPABILITIES.SG_CAPABILITY_DC_EN... OK.
    Wait For Line On Uart     RESET_CONTROL.SOFT_RST... OK.
    Wait For Line On Uart     PRESENT_STATE.AC_CURRENT_OWN... OK.
    Wait For Line On Uart     DCT_SECTION_OFFSET.TABLE_OFFSET... OK.
    Wait For Line On Uart     DCT_SECTION_OFFSET.TABLE_SIZE... OK.
    Wait For Line On Uart     DCT_SECTION_OFFSET.TABLE_INDEX... OK.
    Wait For Line On Uart     DCT_SECTION_OFFSET.ENTRY_SIZE... OK.

 Should Test Read Only
     Execute Command           $elf=@${CURDIR}/../i3c.elf
     Execute Command           include "${CURDIR}/guineveer_i3c_cosim.resc"
     Create Terminal Tester    sysbus.uart  timeout=0.01
     Start Emulation
 
     Wait For Line On Uart     Testing whether HCI_VERSION.VERSION is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CONTROL.AUTOCMD_DATA_RPT is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CONTROL.DATA_BYTE_ORDER_MODE is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CONTROL.MODE_SELECTOR is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.COMBO_COMMAND is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.AUTO_COMMAND is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.STANDBY_CR_CAP is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.HDR_DDR_EN is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.HDR_TS_EN is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.CMD_CCC_DEFBYTE is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.IBI_DATA_ABORT_EN is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.IBI_CREDIT_COUNT_EN is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.SCHEDULED_COMMANDS_EN is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.CMD_SIZE is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.SG_CAPABILITY_CR_EN is read-only... OK.
     Wait For Line On Uart     Testing whether HC_CAPABILITIES.SG_CAPABILITY_DC_EN is read-only... OK.
     Wait For Line On Uart     Testing whether PRESENT_STATE.AC_CURRENT_OWN is read-only... OK.
     Wait For Line On Uart     Testing whether DCT_SECTION_OFFSET.TABLE_OFFSET is read-only... OK.
     Wait For Line On Uart     Testing whether DCT_SECTION_OFFSET.TABLE_SIZE is read-only... OK.
     Wait For Line On Uart     Testing whether DCT_SECTION_OFFSET.ENTRY_SIZE is read-only... OK.
 
 Should Test Writable
     Execute Command           $elf=@${CURDIR}/../i3c.elf
     Execute Command           include "${CURDIR}/guineveer_i3c_cosim.resc"
     Create Terminal Tester    sysbus.uart  timeout=0.01
     Start Emulation
 
     Wait For Line On Uart     Testing whether HC_CONTROL.I2C_DEV_PRESENT is writable... OK.
     Wait For Line On Uart     Testing whether HC_CONTROL.HOT_JOIN_CTRL is writable... OK.
     Wait For Line On Uart     Testing whether HC_CONTROL.HALT_ON_CMD_SEQ_TIMEOUT is writable... OK.
     Wait For Line On Uart     Testing whether HC_CONTROL.ABORT is writable... OK.
     Wait For Line On Uart     Testing whether HC_CONTROL.BUS_ENABLE is writable... OK.
     Wait For Line On Uart     Testing whether CONTROLLER_DEVICE_ADDR.DYNAMIC_ADDR is writable... OK.
     Wait For Line On Uart     Testing whether CONTROLLER_DEVICE_ADDR.DYNAMIC_ADDR_VALID is writable... OK.
     Wait For Line On Uart     Testing whether RESET_CONTROL.SOFT_RST is writable... OK.
