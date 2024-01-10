# MKIDGen3 Firmware - The MazinLab Third Generation Readout Gateware

We suggest starting from [mkidgen3](https://github.com/MazinLab/MKIDGen3) if you are looking at this project for the first time. This repository is for the gateware and some associated test utilities. This document and project are in heavy flux and resource calculations are only partially done. Some linked projects do not yet exist or are untested (especially in the timekeeping/triggering area of the design) and the names and links are suggestive placeholders. In some cases there are alternative/backup approaches that are not described. The principal authors welcome and encourage email inquiry. 

Please see design.md for an overview of the gateware design.

## Building the Project

### Clone the Repo
`git clone --recurse-submodules https://github.com/MazinLab/gen3-vivado-top.git`

### Build the Bitstream
```
source <path/to/vivado/2022.1/settings64.sh>
make
```

This will produce output products in the `build/` directory

By default this will build the `gen3_top` gateware project, as of the time of writing that includes the full hardware design with a 30 tap matched filter. If you would like to build one of the other designs in the `bd/` folder you may do so by running `make DESIGN=mydesign` where mydesign does not include the .tcl extension of the file in the `bd/` folder

If you would like to override the name of the generated project (to test various changes) you may do so with `make PROJECT_NAME=myotherproject_prj` which will produce a correspondingly named folder in `build/`

Various convenience targets are provided for working with the generated projects:

1. `make project` will just generate the project directory allowing you to open it in the vivado gui
2. `make shell` will open a tcl console in the created project
3. `make backup/restore` while backup and restore project folders (But not the generated bitstreams/hwh files in the build folder)
4. `make hwh` will generate just the `.hwh` file (without running through synth and impl)
5. `make bitstream` will generate just the bitstream
6. `make clean` will nuke your current project
7. `make cleanall` will nuke all of your projects
8. `make all` (the default target) will build project, bitstream and hwh

When using a non-defualt project name or design, make sure you pass the PROJECT_NAME directive to make

## Potentially timesaving TCL commands 

#### FIR fix commands

set to speed to fix the column property

`set_property -dict [list CONFIG.Optimization_Goal {Speed} CONFIG.Optimization_Selection {All} CONFIG.Data_Path_Fanout {true} CONFIG.Pre_Adder_Pipeline {true} CONFIG.Coefficient_Fanout {true} CONFIG.Control_Path_Fanout {true} CONFIG.Control_Column_Fanout {true} CONFIG.Control_Broadcast_Fanout {true} CONFIG.Control_LUT_Pipeline {true} CONFIG.No_BRAM_Read_First_Mode {true} CONFIG.Optimal_Column_Lengths {true} CONFIG.Data_Path_Broadcast {false} CONFIG.Disable_Half_Band_Centre_Tap {false} CONFIG.No_SRL_Attributes {false} CONFIG.Other {true} CONFIG.Optimization_List {Data_Path_Fanout,Pre-Adder_Pipeline,Coefficient_Fanout,Control_Path_Fanout,Control_Column_Fanout,Control_Broadcast_Fanout,Control_LUT_Pipeline,No_BRAM_Read_First_Mode,Optimal_Column_Lengths,Other}] [get_bd_cells photon_pipe/opfb/firs/fir_compiler_10]`

set back to area

`set_property -dict [list CONFIG.Optimization_Goal {Area} CONFIG.Optimization_Selection {None} CONFIG.Data_Path_Fanout {false} CONFIG.Pre_Adder_Pipeline {false} CONFIG.Coefficient_Fanout {false} CONFIG.Control_Path_Fanout {false} CONFIG.Control_Column_Fanout {false} CONFIG.Control_Broadcast_Fanout {false} CONFIG.Control_LUT_Pipeline {false} CONFIG.No_BRAM_Read_First_Mode {false} CONFIG.Optimal_Column_Lengths {false} CONFIG.Other {false} CONFIG.Optimization_List {None}] [get_bd_cells photon_pipe/opfb/firs/fir_compiler_10]`


#### Add axis2mm RTL
`add_files -norecurse {./blocks/wb2axip/rtl/axis2mm.v ./blocks/wb2axip/rtl/skidbuffer.v ./blocks/wb2axip/rtl/sfifo.v}`
