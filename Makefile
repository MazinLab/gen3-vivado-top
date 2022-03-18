# Makefile

origin_dir := .

all: rfdc_test opfb_test reschan_test gen3_top

rfdc_test:
	cd $(origin_dir)/tests/rfdc_test; vivado -mode batch -nojou -nolog -source ./write_prj.tcl
opfb_test:
	cd $(origin_dir)/tests/opfb_test; vivado -mode batch -nojou -nolog -source ./write_prj.tcl
reschan_test:
	cd $(origin_dir)/tests/reschan_test; vivado -mode batch -nojou -nolog -source ./write_prj.tcl
gen3_top:
	cd $(origin_dir); vivado -mode batch -nojou -nolog -source ./create_top_level_prj.tcl
