# Set project origin
set origin_dir "."

# BD to source (relative to ${origin_dir})
set bd_to_src "iqtest.tcl"

# Set project name
set _xil_proj_name_ "reschantest"

# Set IP Repo
set ip_repo "./blocks"

# Create project
 create_project ${_xil_proj_name_} ./${_xil_proj_name_} -part xczu28dr-ffvg1517-2-e

# Set project properties
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:zcu111:part0:1.2" -objects $obj

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "${ip_repo}"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
 set files [list \
  [file normalize "${ip_repo}/wb2axip/rtl/sfifo.v"] \
  [file normalize "${ip_repo}/wb2axip/rtl/axis2mm.v"] \
  [file normalize "${ip_repo}/wb2axip/rtl/skidbuffer.v"] \
    ]
add_files -norecurse -fileset $obj $files


# Build block design
source ${origin_dir}/bd/${bd_to_src}

# Generate HDL Wrapper
make_wrapper -files [get_files ${origin_dir}/${_xil_proj_name_}/${_xil_proj_name_}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ${origin_dir}/${_xil_proj_name_}/${_xil_proj_name_}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v

set_property top dac_replay_volatile_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Change Synth and Imp Settings for phys-opt (helps axigmem in capture)
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]


#Uncomment below to run through bitstream generation
#update_compile_order -fileset sources_1
#launch_runs impl_1 -to_step write_bitstream -jobs 4 
#wait_on_run impl_1
