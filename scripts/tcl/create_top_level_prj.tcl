# BD to source and project name
set bd_to_src [lindex $argv 0]
set _xil_proj_name_ [lindex $argv 1]
set _xil_proj_dir_ [lindex $argv 2]

# Set project origin
set origin_dir $::env(ORIGIN_DIR)

# Set IP Repo
set ip_repo "${origin_dir}/blocks"

# Create project
create_project ${_xil_proj_name_} ${_xil_proj_dir_} -part xczu48dr-ffvg1517-2-e

# Set project properties
set obj [current_project]
set_property -name "board_part_repo_paths" -value "[file normalize "$origin_dir/rfsoc4x2_board_files/board_files/rfsoc4x2"]" -objects $obj
set_property -name "board_part" -value "realdigital.org:rfsoc4x2:part0:1.0" -objects $obj

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "${ip_repo}"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
 set files [list \
  [file normalize "${origin_dir}/rtl/lfsr_div.v"] \
  [file normalize "${ip_repo}/wb2axip/rtl/sfifo.v"] \
  [file normalize "${ip_repo}/wb2axip/rtl/axis2mm.v"] \
  [file normalize "${ip_repo}/wb2axip/rtl/skidbuffer.v"] \
  [file normalize "${ip_repo}/pps-synchronizer/src/verilog/pps_synch.v"] \
]
add_files -norecurse -fileset $obj $files

# Build block design
source ${bd_to_src}

# Add all base overlay 4x2 constraints
update_compile_order -fileset sources_1

# Add Constraints
add_files -fileset constrs_1 ${origin_dir}/constraints/

# Generate HDL Wrapper
make_wrapper -files [get_files ${origin_dir}/${_xil_proj_dir_}/${_xil_proj_name_}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top
add_files -norecurse ${origin_dir}/${_xil_proj_dir_}/${_xil_proj_name_}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v

set_property top ${design_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Change Synth and Imp Settings for phys-opt (helps axigmem in capture)
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]

update_compile_order -fileset sources_1
