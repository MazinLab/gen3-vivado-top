# gen3-vivado-top

place scripts (1clock & 2clock.tcl) in a directory
place both bd.tcl in dir/bd
checkout mkidgen2_blocks into dir/ip/ (use commit 9b8750a)
run desired script.

1clock uses an interconnect with axilite on 512mhz. iq_cap will show upgradable to 1.34, this switches from register_all_io to scalarout on config_interface. It didn't make much difference
If the FIR files use 8 taps then the pair of commands below may need to be run on each fir (or it may fail to create)

2clock uses dual clocked hls blocks it never worked as well, but then there are other enhancements that were never tried (e.g. 4 taps, tying off tready, forcing the interconnect to use axilite)
If the FIR files use 4 taps then the pair of commands below may need to be run on each fir (or it may fail to create)

#FIR fix commands
#set to speed to fix the column porperty
set_property -dict [list CONFIG.Optimization_Goal {Speed} CONFIG.Optimization_Selection {All} CONFIG.Data_Path_Fanout {true} CONFIG.Pre_Adder_Pipeline {true} CONFIG.Coefficient_Fanout {true} CONFIG.Control_Path_Fanout {true} CONFIG.Control_Column_Fanout {true} CONFIG.Control_Broadcast_Fanout {true} CONFIG.Control_LUT_Pipeline {true} CONFIG.No_BRAM_Read_First_Mode {true} CONFIG.Optimal_Column_Lengths {true} CONFIG.Data_Path_Broadcast {false} CONFIG.Disable_Half_Band_Centre_Tap {false} CONFIG.No_SRL_Attributes {false} CONFIG.Other {true} CONFIG.Optimization_List {Data_Path_Fanout,Pre-Adder_Pipeline,Coefficient_Fanout,Control_Path_Fanout,Control_Column_Fanout,Control_Broadcast_Fanout,Control_LUT_Pipeline,No_BRAM_Read_First_Mode,Optimal_Column_Lengths,Other}] [get_bd_cells photon_pipe/opfb/firs/fir_compiler_10]
#set back to area
set_property -dict [list CONFIG.Optimization_Goal {Area} CONFIG.Optimization_Selection {None} CONFIG.Data_Path_Fanout {false} CONFIG.Pre_Adder_Pipeline {false} CONFIG.Coefficient_Fanout {false} CONFIG.Control_Path_Fanout {false} CONFIG.Control_Column_Fanout {false} CONFIG.Control_Broadcast_Fanout {false} CONFIG.Control_LUT_Pipeline {false} CONFIG.No_BRAM_Read_First_Mode {false} CONFIG.Optimal_Column_Lengths {false} CONFIG.Other {false} CONFIG.Optimization_List {None}] [get_bd_cells photon_pipe/opfb/firs/fir_compiler_10]


Will need to do for each fir _0 - _15


The file does not include the new dac uram version (1.32)

Best timing I saw was WNS=-0.092 TNS = -15.389 with 1clkc. Implementation was slightly different than the script with Post-place, rout, and post-route all set to AgressiveExplore (but I'm not sure this was making the difference)
Several runs were in the ~WNS~-0.150/TNS=-75. I also attained WNS~-0.092 once with 8 taps. 