# Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk100_i }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -add -name sys_clk_pin -period 10.00 [get_ports { clk100_i }];

# Buttons & LEDs
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { btn_i[0] }]
set_property -dict { PACKAGE_PIN C9    IOSTANDARD LVCMOS33 } [get_ports { btn_i[1] }]
set_property -dict { PACKAGE_PIN B9    IOSTANDARD LVCMOS33 } [get_ports { btn_i[2] }]
set_property -dict { PACKAGE_PIN B8    IOSTANDARD LVCMOS33 } [get_ports { btn_i[3] }]

set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led_o[0] }]
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { led_o[1] }]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { led_o[2] }]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { led_o[3] }]

# USB-UART Interface
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { uart_rx_i }]; #IO_L14N_T2_SRCC_16 Sch=uart_txd_in
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }]; #IO_L19N_T3_VREF_16 Sch=uart_rxd_out

# I3C
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { i3c_scl_io  }]; #IO_L16P_T2_CSI_B_14          Sch=ck_io[0]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { i3c_sda_io  }]; #IO_L18P_T2_A12_D28_14        Sch=ck_io[1]

# Other
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets { u_guineveer/axi_bridge/buf_state_ff/genblock.dffs/genblock.dffs/dout[0]_i_2__0_n_0 }];
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets { u_guineveer/axi_bridge/buf_state_ff/genblock.dffs/genblock.dffs/dout[0]_i_2__5_n_0 }];
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets { u_guineveer/axi_bridge/buf_state_ff/genblock.dffs/genblock.dffs/dout_reg[0]_10 }];
