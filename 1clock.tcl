set origin_dir "."
set iprepo_dir $origin_dir/ip
set prj_name "gen3_1clk" 
set
create_project $prj_name $origin_dir/$prj_name -part xczu28dr-ffvg1517-2-e
set_property board_part xilinx.com:zcu111:part0:1.4 [current_project]
set_property ip_repo_paths $iprepo_dir [current_project]
set_property target_language Verilog [current_project]
update_ip_catalog

set bd_name "gen3_512"
source $origin_dir/bd/$bd_name.tcl

make_wrapper -files [get_files $origin_dir/$prj_name/$prj_name.srcs/sources_1/bd/$bd_name/$bd_name.bd] -top
add_files -norecurse $origin_dir/$prj_name/$prj_name.srcs/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v
update_compile_order -fileset sources_1


set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
set_property strategy Performance_ExploreWithRemap [get_runs impl_1]

set_property synth_checkpoint_mode None [get_files  $origin_dir/$prj_name/$prj_name.srcs/sources_1/bd/$bd_name/$bd_name.bd]

#generate_target all [get_files  c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.srcs/sources_1/bd/gen3dev/gen3dev.bd]
#export_ip_user_files -of_objects [get_files c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.srcs/sources_1/bd/gen3dev/gen3dev.bd] -no_script -sync -force -quiet
#export_simulation -of_objects [get_files c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.srcs/sources_1/bd/gen3dev/gen3dev.bd] -directory c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.ip_user_files/sim_scripts -ip_user_files_dir c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.ip_user_files -ipstatic_source_dir c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.ip_user_files/ipstatic -lib_map_path [list {modelsim=c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.cache/compile_simlib/modelsim} {questa=c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.cache/compile_simlib/questa} {riviera=c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.cache/compile_simlib/riviera} {activehdl=c:/Users/one/xilinx_projects/garb/jbpjr/jbpjr.cache/compile_simlib/activehdl}] -use_ip_compiled_libs -force -quiet


#launch_runs impl_1 -jobs 8 -to_step write_bitstream
#wait_on_run impl_1