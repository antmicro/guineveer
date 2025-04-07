## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk_i }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -add -name sys_clk_pin -period 20.00 [get_ports { clk_i }];

## USB-UART Interface
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { uart_rx_i }]; #IO_L19N_T3_VREF_16 Sch=uart_rxd_out
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }]; #IO_L14N_T2_SRCC_16 Sch=uart_txd_in

set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { rst_ni }]; #IO_L16P_T2_35 Sch=ck_rst

# I3C
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { i3c_scl_io  }]; #IO_L16P_T2_CSI_B_14          Sch=ck_io[0]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { i3c_sda_io  }]; #IO_L18P_T2_A12_D28_14        Sch=ck_io[1]

set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets { axi_bridge/buf_state_ff/genblock.dffs/genblock.dffs/dout[0]_i_2__220_n_0 }];
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets { axi_bridge/buf_state_ff/genblock.dffs/genblock.dffs/dout[0]_i_2__226_n_0 }];
