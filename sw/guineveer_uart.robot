*** Test Cases ***
Should Transmit And Receive UART data
    Execute Command           include "${CURDIR}/guineveer.resc"
    Create Terminal Tester    sysbus.uart
    Execute Command           start
    Wait For Line On Uart     Hello UART
