# MKIDGen3 - The Mazinlab Third Generation Readout Gateware

We suggest starting from mkidgen if you are looking at this project for the first time. This repository focuses on the gateware. This document and project are in heavy flux and resource calculations are only partially done. Some of the linked projects do not yet exist or are untested (especially in the timekeeping/triggering area of the design) and the names and links are suggestive placeholders. In some cases there are alternative/backup approaches that are not described.

## Creating the latest testbench

_*The create_project script is presently broken so use option 2*_

Recursively clone this repository and either edit the first two lines of `create_project.tcl` as desired, then source that script 
from within that directory in vivado or use two following steps. Either should result in a project with a block design
of the desired firmware/test design.

1. Open vivado, create a new project with the ZCU111 board in a subdirectory of the folder containing this repo, (adding it to gitignore).
2. cd to the repo directory
3. Run `add_files -norecurse {./blocks/wb2axip/rtl/axis2mm.v ./blocks/wb2axip/rtl/skidbuffer.v ./blocks/wb2axip/rtl/sfifo.v}`
4. source ./bd/<desired_bd_tcl>

The present best design is iqtest.tcl on branch 2021.2.

## Potentially timesaving TCL commands 

#### FIR fix commands

set to speed to fix the column porperty

`set_property -dict [list CONFIG.Optimization_Goal {Speed} CONFIG.Optimization_Selection {All} CONFIG.Data_Path_Fanout {true} CONFIG.Pre_Adder_Pipeline {true} CONFIG.Coefficient_Fanout {true} CONFIG.Control_Path_Fanout {true} CONFIG.Control_Column_Fanout {true} CONFIG.Control_Broadcast_Fanout {true} CONFIG.Control_LUT_Pipeline {true} CONFIG.No_BRAM_Read_First_Mode {true} CONFIG.Optimal_Column_Lengths {true} CONFIG.Data_Path_Broadcast {false} CONFIG.Disable_Half_Band_Centre_Tap {false} CONFIG.No_SRL_Attributes {false} CONFIG.Other {true} CONFIG.Optimization_List {Data_Path_Fanout,Pre-Adder_Pipeline,Coefficient_Fanout,Control_Path_Fanout,Control_Column_Fanout,Control_Broadcast_Fanout,Control_LUT_Pipeline,No_BRAM_Read_First_Mode,Optimal_Column_Lengths,Other}] [get_bd_cells photon_pipe/opfb/firs/fir_compiler_10]`

set back to area

`set_property -dict [list CONFIG.Optimization_Goal {Area} CONFIG.Optimization_Selection {None} CONFIG.Data_Path_Fanout {false} CONFIG.Pre_Adder_Pipeline {false} CONFIG.Coefficient_Fanout {false} CONFIG.Control_Path_Fanout {false} CONFIG.Control_Column_Fanout {false} CONFIG.Control_Broadcast_Fanout {false} CONFIG.Control_LUT_Pipeline {false} CONFIG.No_BRAM_Read_First_Mode {false} CONFIG.Optimal_Column_Lengths {false} CONFIG.Other {false} CONFIG.Optimization_List {None}] [get_bd_cells photon_pipe/opfb/firs/fir_compiler_10]`


#### Add axis2mm RTL
`add_files -norecurse {./blocks/wb2axip/rtl/axis2mm.v ./blocks/wb2axip/rtl/skidbuffer.v ./blocks/wb2axip/rtl/sfifo.v}`
