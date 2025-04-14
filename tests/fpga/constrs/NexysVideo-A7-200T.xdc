# Clock signal
set_property -dict { PACKAGE_PIN R4    IOSTANDARD LVCMOS33 } [get_ports { clk100_i }];
create_clock -add -name sys_clk_pin -period 10.00 [get_ports { clk100_i }];

# Buttons & LEDs
set_property -dict { PACKAGE_PIN B22    IOSTANDARD LVCMOS33 } [get_ports { btn_i[0] }]; # SoC reset (BTNC)
set_property -dict { PACKAGE_PIN D14    IOSTANDARD LVCMOS33 } [get_ports { btn_i[1] }]; # CPU reset (BTNR)
set_property -dict { PACKAGE_PIN F15    IOSTANDARD LVCMOS33 } [get_ports { btn_i[2] }]; # (BTNU)
set_property -dict { PACKAGE_PIN D22    IOSTANDARD LVCMOS33 } [get_ports { btn_i[3] }]; # (BTND)

set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS25 } [get_ports { led_o[0] }]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS25 } [get_ports { led_o[1] }]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS25 } [get_ports { led_o[2] }]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS25 } [get_ports { led_o[3] }]

# USB-UART Interface
set_property -dict { PACKAGE_PIN V18    IOSTANDARD LVCMOS33 } [get_ports { uart_rx_i }];
set_property -dict { PACKAGE_PIN AA19   IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }];

# I3C
set_property -dict { PACKAGE_PIN AB22   IOSTANDARD LVCMOS33 } [get_ports { i3c_scl_io  }];
set_property -dict { PACKAGE_PIN AB21   IOSTANDARD LVCMOS33 } [get_ports { i3c_sda_io  }];

# Other
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets { u_guineveer/axi_bridge/buf_state_ff/genblock.dffs/genblock.dffs/dout[0]_i_2__0_n_0 }];
