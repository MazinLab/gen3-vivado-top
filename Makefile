# Makefile

origin_dir := .

all: fccm22_demo opfb_dac_loopback opfb_rfdc_loopback rfdc_test reschan_test gen3_top


fccm22_demo:
	cd $(origin_dir)/tests/fccm22_demo; vivado -mode batch -nojou -nolog -source ./write_prj.tcl
opfb_dac_loopback:
	cd $(origin_dir)/tests/opfb_dac_loopback; vivado -mode batch -nojou -nolog -source ./write_prj.tcl
opfb_rfdc_loopback:
	cd $(origin_dir)/tests/opfb_rfdc_loopback; vivado -mode batch -nojou -nolog -source ./write_prj.tcl
rfdc_test:
	cd $(origin_dir)/tests/rfdc_test; vivado -mode batch -nojou -nolog -source ./write_prj.tcl
reschan_test:
	cd $(origin_dir)/tests/reschan_test; vivado -mode batch -nojou -nolog -source ./write_prj.tcl
gen3_top:
	cd $(origin_dir); vivado -mode batch -nojou -nolog -source ./create_top_level_prj.tcl
