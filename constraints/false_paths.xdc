# Set False Paths
set_false_path -from [get_pins {gen3_top_i/Clocktree/AXI_100_RESET/U0/BSR_OUT_DFF[*].*/C}]

set_false_path -from [get_ports {pps_trig}]
set_false_path -from [get_ports {pps_comp}]


