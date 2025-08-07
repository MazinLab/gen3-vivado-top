set bd_file [lindex $argv 0]
generate_target all [get_files ${bd_file}]
