# Makefile

origin_dir := .

all: 2021_2 2022_1 2022_2 2022_2_ilas


2021_2:
	cd $(origin_dir); vivado -mode batch -nojou -nolog -source ./create_vivado_2021_2_prj.tcl

2022_1:
	cd $(origin_dir); vivado -mode batch -nojou -nolog -source ./create_vivado_2022_1_prj.tcl

2022_2:
	cd $(origin_dir); vivado -mode batch -nojou -nolog -source ./create_vivado_2022_2_prj.tcl

2022_2_ilas: 
	cd $(origin_dir); vivado -mode batch -nojou -nolog -source ./create_vivado_2022_2_ilas_prj.tcl
