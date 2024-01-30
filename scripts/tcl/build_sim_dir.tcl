set library_dir [lindex $argv 0]
set sim [lindex $argv 1]
set sim_dir [lindex $argv 2]
set bd_file [lindex $argv 3]

generate_target simulation [get_files ${bd_file}]

export_simulation -simulator ${sim} -directory ${sim_dir} -lib_map_path ${library_dir} -use_ip_compiled_libs
