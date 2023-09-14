## Constraints file for RFSoC4x2 base overlay Vivado project

# Synthesis Guidance
set_property BLOCK_SYNTH.RETIMING 1 [get_cells gen3_top_i/capture/ddr4_0/*]
set_property BLOCK_SYNTH.STRATEGY {PERFORMANCE_OPTIMIZED} [get_cells gen3_top_i/capture/ddr4_0/*]

set_property BLOCK_SYNTH.RETIMING 1 [get_cells {gen3_top_i/rfdc/usp_rf_data_converter_0/*}]
set_property BLOCK_SYNTH.STRATEGY {PERFORMANCE_OPTIMIZED} [get_cells {gen3_top_i/rfdc/usp_rf_data_converter_0/*}]

set_property BLOCK_SYNTH.RETIMING 1 [get_cells {gen3_top_i/DACCDC*/axis_dwidth_converter_0/*}]
set_property BLOCK_SYNTH.STRATEGY {PERFORMANCE_OPTIMIZED} [get_cells {gen3_top_i/DACCDC*/axis_dwidth_converter_0/*}]

# Constrain PL Clock Pins
set_property PACKAGE_PIN AP18 [get_ports {PL_SYSREF_clk_p[0]}]
set_property PACKAGE_PIN AN11 [get_ports {PL_CLK_clk_p[0]}]

set_property IOSTANDARD LVDS [get_ports {PL_CLK_clk_p[0]}]
set_property IOSTANDARD LVDS [get_ports {PL_CLK_clk_n[0]}]
set_property IOSTANDARD LVDS [get_ports {PL_SYSREF_clk_p[0]}]
set_property IOSTANDARD LVDS [get_ports {PL_SYSREF_clk_n[0]}]

set_property PACKAGE_PIN AH13 [get_ports {pps_trig}]
set_property IOSTANDARD LVCMOS18 [get_ports {pps_trig}]

set_property PACKAGE_PIN AJ13 [get_ports {pps_comp}]
set_property IOSTANDARD LVCMOS18 [get_ports {pps_comp}]

# Constrain PL SYSREF and Refclks
create_clock -period 1.953125 -name PL_CLK_clk [get_ports PL_CLK_clk_p]

set_input_delay -clock [get_clocks PL_CLK_clk] -min -add_delay 2.000 [get_ports PL_SYSREF_clk_p]
set_input_delay -clock [get_clocks PL_CLK_clk] -max -add_delay 2.031 [get_ports PL_SYSREF_clk_p]

set_max_delay -from [get_pins {gen3_top_i/Clocktree/SynchronizeSYSREF/inst/xsingle/syncstages_ff_reg[1]/C}] 1.0
set_max_delay -from [get_pins {gen3_top_i/Clocktree/SynchronizeSYSREF/inst/xsingle/src_ff_reg/C}] 1.0
set_max_delay -from [get_ports {pps_trig}] 1.0
set_max_delay -from [get_ports {pps_comp}] 1.0

set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets {gen3_top_i/Clocktree/BUFG_PL_CLK/BUFG_O[0]}]

# Constrain DDR4 Clock
set_property LOC MMCM_X0Y4 [get_cells -hier -filter {NAME =~ */u_ddr4_infrastructure/gen_mmcme*.u_mmcme_adv_inst}]

## PL ddr4
set_property PACKAGE_PIN G13 [get_ports {sys_clk_ddr4_clk_p[0]}]
create_clock -period 5.000 -name sys_clk_ddr4 [get_ports sys_clk_ddr4_clk_p]

set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_pl_adr[?]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_pl_ba[?]}]
set_property IOSTANDARD POD12_DCI [get_ports {ddr4_pl_dm_n[?]}]
set_property IOSTANDARD POD12_DCI [get_ports {ddr4_pl_dq[?]}]
set_property IOSTANDARD DIFF_POD12_DCI [get_ports {ddr4_pl_dqs_c[?]}]
set_property IOSTANDARD DIFF_POD12_DCI [get_ports {ddr4_pl_dqs_t[?]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_pl_odt[?]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_pl_adr[?]}]
set_property IOSTANDARD SSTL12_DCI [get_ports ddr4_pl_act_n]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_pl_ba[?]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_pl_bg[0]}]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports {ddr4_pl_ck_c[0]}]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports {ddr4_pl_ck_t[0]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_pl_cke[0]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_pl_cs_n[0]}]
set_property IOSTANDARD POD12_DCI [get_ports {ddr4_pl_dm_n[?]}]
set_property IOSTANDARD POD12_DCI [get_ports {ddr4_pl_dq[?]}]
set_property IOSTANDARD DIFF_POD12_DCI [get_ports {ddr4_pl_dqs_c[?]}]
set_property IOSTANDARD DIFF_POD12_DCI [get_ports {ddr4_pl_dqs_t[?]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_pl_odt[?]}]
set_property IOSTANDARD LVCMOS12 [get_ports ddr4_pl_reset_n]

set_property PACKAGE_PIN B13 [get_ports {ddr4_pl_adr[0]}]
set_property PACKAGE_PIN G6 [get_ports {ddr4_pl_adr[1]}]
set_property PACKAGE_PIN A14 [get_ports {ddr4_pl_adr[2]}]
set_property PACKAGE_PIN F10 [get_ports {ddr4_pl_adr[3]}]
set_property PACKAGE_PIN D14 [get_ports {ddr4_pl_adr[4]}]
set_property PACKAGE_PIN F11 [get_ports {ddr4_pl_adr[5]}]
set_property PACKAGE_PIN J7 [get_ports {ddr4_pl_adr[6]}]
set_property PACKAGE_PIN H13 [get_ports {ddr4_pl_adr[7]}]
set_property PACKAGE_PIN A11 [get_ports {ddr4_pl_adr[8]}]
set_property PACKAGE_PIN H6 [get_ports {ddr4_pl_adr[9]}]
set_property PACKAGE_PIN C15 [get_ports {ddr4_pl_adr[10]}]
set_property PACKAGE_PIN G7 [get_ports {ddr4_pl_adr[11]}]
set_property PACKAGE_PIN D13 [get_ports {ddr4_pl_adr[12]}]
set_property PACKAGE_PIN H11 [get_ports {ddr4_pl_adr[13]}]
set_property PACKAGE_PIN K13 [get_ports {ddr4_pl_adr[14]}]
set_property PACKAGE_PIN F14 [get_ports {ddr4_pl_adr[15]}]
set_property PACKAGE_PIN E13 [get_ports {ddr4_pl_adr[16]}]
set_property PACKAGE_PIN B14 [get_ports ddr4_pl_act_n]
set_property PACKAGE_PIN A12 [get_ports {ddr4_pl_ba[0]}]
set_property PACKAGE_PIN H10 [get_ports {ddr4_pl_ba[1]}]
set_property PACKAGE_PIN H12 [get_ports {ddr4_pl_bg[0]}]
set_property PACKAGE_PIN J11 [get_ports {ddr4_pl_ck_t[0]}]
set_property PACKAGE_PIN J10 [get_ports {ddr4_pl_ck_c[0]}]
set_property PACKAGE_PIN F12 [get_ports {ddr4_pl_cke[0]}]
set_property PACKAGE_PIN E11 [get_ports {ddr4_pl_cs_n[0]}]
set_property PACKAGE_PIN J15 [get_ports {ddr4_pl_dm_n[0]}]
set_property PACKAGE_PIN N14 [get_ports {ddr4_pl_dm_n[1]}]
set_property PACKAGE_PIN D18 [get_ports {ddr4_pl_dm_n[2]}]
set_property PACKAGE_PIN G17 [get_ports {ddr4_pl_dm_n[3]}]
set_property PACKAGE_PIN F21 [get_ports {ddr4_pl_dm_n[4]}]
set_property PACKAGE_PIN J23 [get_ports {ddr4_pl_dm_n[5]}]
set_property PACKAGE_PIN C23 [get_ports {ddr4_pl_dm_n[6]}]
set_property PACKAGE_PIN N20 [get_ports {ddr4_pl_dm_n[7]}]
set_property PACKAGE_PIN K17 [get_ports {ddr4_pl_dq[0]}]
set_property PACKAGE_PIN J16 [get_ports {ddr4_pl_dq[1]}]
set_property PACKAGE_PIN H17 [get_ports {ddr4_pl_dq[2]}]
set_property PACKAGE_PIN H16 [get_ports {ddr4_pl_dq[3]}]
set_property PACKAGE_PIN J18 [get_ports {ddr4_pl_dq[4]}]
set_property PACKAGE_PIN K16 [get_ports {ddr4_pl_dq[5]}]
set_property PACKAGE_PIN J19 [get_ports {ddr4_pl_dq[6]}]
set_property PACKAGE_PIN L17 [get_ports {ddr4_pl_dq[7]}]
set_property PACKAGE_PIN N17 [get_ports {ddr4_pl_dq[8]}]
set_property PACKAGE_PIN N13 [get_ports {ddr4_pl_dq[9]}]
set_property PACKAGE_PIN N15 [get_ports {ddr4_pl_dq[10]}]
set_property PACKAGE_PIN L12 [get_ports {ddr4_pl_dq[11]}]
set_property PACKAGE_PIN M17 [get_ports {ddr4_pl_dq[12]}]
set_property PACKAGE_PIN M13 [get_ports {ddr4_pl_dq[13]}]
set_property PACKAGE_PIN M15 [get_ports {ddr4_pl_dq[14]}]
set_property PACKAGE_PIN M12 [get_ports {ddr4_pl_dq[15]}]
set_property PACKAGE_PIN D16 [get_ports {ddr4_pl_dq[16]}]
set_property PACKAGE_PIN A17 [get_ports {ddr4_pl_dq[17]}]
set_property PACKAGE_PIN C17 [get_ports {ddr4_pl_dq[18]}]
set_property PACKAGE_PIN A19 [get_ports {ddr4_pl_dq[19]}]
set_property PACKAGE_PIN D15 [get_ports {ddr4_pl_dq[20]}]
set_property PACKAGE_PIN C16 [get_ports {ddr4_pl_dq[21]}]
set_property PACKAGE_PIN B19 [get_ports {ddr4_pl_dq[22]}]
set_property PACKAGE_PIN A16 [get_ports {ddr4_pl_dq[23]}]
set_property PACKAGE_PIN G18 [get_ports {ddr4_pl_dq[24]}]
set_property PACKAGE_PIN E16 [get_ports {ddr4_pl_dq[25]}]
set_property PACKAGE_PIN F16 [get_ports {ddr4_pl_dq[26]}]
set_property PACKAGE_PIN G15 [get_ports {ddr4_pl_dq[27]}]
set_property PACKAGE_PIN H18 [get_ports {ddr4_pl_dq[28]}]
set_property PACKAGE_PIN E17 [get_ports {ddr4_pl_dq[29]}]
set_property PACKAGE_PIN E18 [get_ports {ddr4_pl_dq[30]}]
set_property PACKAGE_PIN F15 [get_ports {ddr4_pl_dq[31]}]
set_property PACKAGE_PIN E24 [get_ports {ddr4_pl_dq[32]}]
set_property PACKAGE_PIN D21 [get_ports {ddr4_pl_dq[33]}]
set_property PACKAGE_PIN E22 [get_ports {ddr4_pl_dq[34]}]
set_property PACKAGE_PIN E21 [get_ports {ddr4_pl_dq[35]}]
set_property PACKAGE_PIN E23 [get_ports {ddr4_pl_dq[36]}]
set_property PACKAGE_PIN F20 [get_ports {ddr4_pl_dq[37]}]
set_property PACKAGE_PIN F24 [get_ports {ddr4_pl_dq[38]}]
set_property PACKAGE_PIN G20 [get_ports {ddr4_pl_dq[39]}]
set_property PACKAGE_PIN J21 [get_ports {ddr4_pl_dq[40]}]
set_property PACKAGE_PIN G22 [get_ports {ddr4_pl_dq[41]}]
set_property PACKAGE_PIN K24 [get_ports {ddr4_pl_dq[42]}]
set_property PACKAGE_PIN G23 [get_ports {ddr4_pl_dq[43]}]
set_property PACKAGE_PIN L24 [get_ports {ddr4_pl_dq[44]}]
set_property PACKAGE_PIN H22 [get_ports {ddr4_pl_dq[45]}]
set_property PACKAGE_PIN H23 [get_ports {ddr4_pl_dq[46]}]
set_property PACKAGE_PIN H21 [get_ports {ddr4_pl_dq[47]}]
set_property PACKAGE_PIN C21 [get_ports {ddr4_pl_dq[48]}]
set_property PACKAGE_PIN A24 [get_ports {ddr4_pl_dq[49]}]
set_property PACKAGE_PIN B24 [get_ports {ddr4_pl_dq[50]}]
set_property PACKAGE_PIN A20 [get_ports {ddr4_pl_dq[51]}]
set_property PACKAGE_PIN C22 [get_ports {ddr4_pl_dq[52]}]
set_property PACKAGE_PIN A21 [get_ports {ddr4_pl_dq[53]}]
set_property PACKAGE_PIN C20 [get_ports {ddr4_pl_dq[54]}]
set_property PACKAGE_PIN B20 [get_ports {ddr4_pl_dq[55]}]
set_property PACKAGE_PIN M20 [get_ports {ddr4_pl_dq[56]}]
set_property PACKAGE_PIN L20 [get_ports {ddr4_pl_dq[57]}]
set_property PACKAGE_PIN L22 [get_ports {ddr4_pl_dq[58]}]
set_property PACKAGE_PIN L21 [get_ports {ddr4_pl_dq[59]}]
set_property PACKAGE_PIN N19 [get_ports {ddr4_pl_dq[60]}]
set_property PACKAGE_PIN M19 [get_ports {ddr4_pl_dq[61]}]
set_property PACKAGE_PIN L23 [get_ports {ddr4_pl_dq[62]}]
set_property PACKAGE_PIN L19 [get_ports {ddr4_pl_dq[63]}]
set_property PACKAGE_PIN K19 [get_ports {ddr4_pl_dqs_t[0]}]
set_property PACKAGE_PIN K18 [get_ports {ddr4_pl_dqs_c[0]}]
set_property PACKAGE_PIN L15 [get_ports {ddr4_pl_dqs_t[1]}]
set_property PACKAGE_PIN L14 [get_ports {ddr4_pl_dqs_c[1]}]
set_property PACKAGE_PIN B18 [get_ports {ddr4_pl_dqs_t[2]}]
set_property PACKAGE_PIN B17 [get_ports {ddr4_pl_dqs_c[2]}]
set_property PACKAGE_PIN G19 [get_ports {ddr4_pl_dqs_t[3]}]
set_property PACKAGE_PIN F19 [get_ports {ddr4_pl_dqs_c[3]}]
set_property PACKAGE_PIN D23 [get_ports {ddr4_pl_dqs_t[4]}]
set_property PACKAGE_PIN D24 [get_ports {ddr4_pl_dqs_c[4]}]
set_property PACKAGE_PIN J20 [get_ports {ddr4_pl_dqs_t[5]}]
set_property PACKAGE_PIN H20 [get_ports {ddr4_pl_dqs_c[5]}]
set_property PACKAGE_PIN B22 [get_ports {ddr4_pl_dqs_t[6]}]
set_property PACKAGE_PIN A22 [get_ports {ddr4_pl_dqs_c[6]}]
set_property PACKAGE_PIN K21 [get_ports {ddr4_pl_dqs_t[7]}]
set_property PACKAGE_PIN K22 [get_ports {ddr4_pl_dqs_c[7]}]
set_property PACKAGE_PIN A15 [get_ports {ddr4_pl_odt[0]}]
set_property PACKAGE_PIN E14 [get_ports ddr4_pl_reset_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports {sys_clk_ddr4_clk_p[0]}]


## rgbleds
set_property PACKAGE_PIN AN8 [get_ports {rgbleds_6bits[0]}]
set_property PACKAGE_PIN AM7 [get_ports {rgbleds_6bits[1]}]
set_property PACKAGE_PIN AM8 [get_ports {rgbleds_6bits[2]}]
set_property PACKAGE_PIN AT10 [get_ports {rgbleds_6bits[3]}]
set_property PACKAGE_PIN AP8 [get_ports {rgbleds_6bits[4]}]
set_property PACKAGE_PIN AR12 [get_ports {rgbleds_6bits[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgbleds_6bits[?]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rgbleds_6bits[?]}]

set_false_path -to [get_ports {rgbleds_6bits[?]}]

set_false_path -from [get_pins {gen3_top_i/Clocktree/AXI_100_RESET/U0/BSR_OUT_DFF[*].*/C}]
set_property CLOCK_BUFFER_TYPE BUFG [get_nets {gen3_top_i/Clocktree/AXI_100_RESET/interconnect_aresetn[0]}]
set_property CLOCK_BUFFER_TYPE BUFG [get_nets {gen3_top_i/Clocktree/PL_RF_256_Reset/interconnect_aresetn[0]}]
set_property CLOCK_BUFFER_TYPE BUFG [get_nets {gen3_top_i/Clocktree/PL_RF_512_Reset/interconnect_aresetn[0]}]
set_property CLOCK_BUFFER_TYPE BUFG [get_nets {gen3_top_i/photon_pipe/opfb/adc_to_opfb_0/inst/process_lanes_U0/regslice_both_lanes_V_data_V_U/even_delay_Array_ce0}]
set_property CLOCK_BUFFER_TYPE BUFG [get_nets {gen3_top_i/photon_pipe/opfb/adc_to_opfb_0/inst/process_lanes_U0/regslice_both_lanes_V_data_V_U/odd_delay_Array_ce0}]
#set_property CLOCK_BUFFER_TYPE BUFG [get_nets {gen3_top_i/photon_pipe/reschan/dds_ddc_center/inst/grp_phase_sincos_LUT_*/accumulator_TVALID_0}]

#set_false_path -from [get_ports {pps_trig}]
#set_false_path -from [get_ports {pps_comp}]


# Placement Guidance
create_pblock daccdc_spineleft
resize_pblock [get_pblocks daccdc_spineleft] -add {CLOCKREGION_X2Y4:CLOCKREGION_X3Y5}
add_cells_to_pblock [get_pblocks daccdc_spineleft] [get_cells -quiet [list gen3_top_i/DACCDC0/axis_clock_converter_0 gen3_top_i/DACCDC1/axis_clock_converter_0]]

create_pblock daccdc_spineright
resize_pblock [get_pblocks daccdc_spineright] -add {CLOCKREGION_X4Y4:CLOCKREGION_X5Y5}
add_cells_to_pblock [get_pblocks daccdc_spineright] [get_cells -quiet [list gen3_top_i/DACCDC0/axis_dwidth_converter_0 gen3_top_i/DACCDC1/axis_dwidth_converter_0]]

create_pblock ddr4_pblock
add_cells_to_pblock [get_pblocks ddr4_pblock] [get_cells -quiet [list gen3_top_i/capture/ddr4_0]]
resize_pblock [get_pblocks ddr4_pblock] -add {SLICE_X86Y240:SLICE_X89Y359 SLICE_X38Y180:SLICE_X85Y359}
resize_pblock [get_pblocks ddr4_pblock] -add {DSP48E2_X16Y96:DSP48E2_X17Y143 DSP48E2_X6Y72:DSP48E2_X15Y143}
resize_pblock [get_pblocks ddr4_pblock] -add {RAMB18_X4Y72:RAMB18_X8Y143}
resize_pblock [get_pblocks ddr4_pblock] -add {RAMB36_X4Y36:RAMB36_X8Y71}

# Debug Hub
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
