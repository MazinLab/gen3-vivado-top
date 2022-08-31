#LED 0

#set_property PACKAGE_PIN AR13 [get_ports dac_clk_act_o_0]

#set_property IOSTANDARD LVCMOS18 [get_ports dac_clk_act_o_0]

#LED1

#set_property PACKAGE_PIN AP13 [get_ports test_o_0[0]]

#set_property IOSTANDARD LVCMOS18 [get_ports test_o_0[0]]

#LED2

#set_property PACKAGE_PIN AR16 [get_ports test_o_0[1]]

#set_property IOSTANDARD LVCMOS18 [get_ports test_o_0[1]]

#LED3

#set_property PACKAGE_PIN AP16 [get_ports time_sync_act]

#set_property IOSTANDARD LVCMOS18 [get_ports time_sync_act]

#set_property BOARD_PIN {CPU_RESET} [get_ports reset]

#Grab ACT LED (4)

#set_property PACKAGE_PIN AP15 [get_ports  grab_act_o]

#set_property IOSTANDARD LVCMOS18 [get_ports  grab_act_o]

#Grab LED 0 (5)

#set_property PACKAGE_PIN AN16 [get_ports  grab_test_o[0]]

#set_property IOSTANDARD LVCMOS18 [get_ports  grab_test_o[0]]

#Grab LED 1 (6)

#set_property PACKAGE_PIN AN17 [get_ports  grab_test_o[1]]

#set_property IOSTANDARD LVCMOS18 [get_ports  grab_test_o[1]]

#Grab LED 2 (7)

#set_property PACKAGE_PIN AV15 [get_ports  grab_test_o[2]]

#set_property IOSTANDARD LVCMOS18 [get_ports  grab_test_o[2]]

#RF UART F2M DACIO_18

set_property PACKAGE_PIN D6 [get_ports  emio_uart1_txd]

set_property IOSTANDARD LVCMOS18 [get_ports  emio_uart1_txd]

#RF UART M2F DACIO_19

set_property PACKAGE_PIN E7 [get_ports  emio_uart1_rxd]

set_property IOSTANDARD LVCMOS18 [get_ports  emio_uart1_rxd]
