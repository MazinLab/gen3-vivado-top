set library_dir [lindex $argv 0]
set sim [lindex $argv 1]
set sim_path [lindex $argv 2]

compile_simlib -simulator ${sim} -simulator_exec_path ${sim_path} -family zynquplusrfsoc -language all -library all -dir ${library_dir} -quiet
