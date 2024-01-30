ORIGIN_DIR := .
BUILD_DIR := ${ORIGIN_DIR}/build
SIM_DIR := ${ORIGIN_DIR}/sim
SCRIPT_DIR := ${ORIGIN_DIR}/scripts

DESIGN ?= gen3_top
PROJECT_NAME ?= ${DESIGN}_prj
PROJECT_DIR ?= ${BUILD_DIR}/${PROJECT_NAME}
PROJECT_SIM_DIR = ${SIM_DIR}/${PROJECT_NAME}/vcs

VIVADO ?= vivado
VIVADO_ARGS ?= -nojou -nolog
VIVADO_VERSION = $(shell which vivado | xargs dirname | xargs dirname | xargs basename)

VCS ?= vcs
VCS_ARGS ?= -full64
VCS_VERSION = $(shell which ${VCS} | xargs dirname | xargs dirname | xargs basename)

LIBRARY_BASE ?= ${ORIGIN_DIR}/simlibs
LIBRARY = ${LIBRARY_BASE}/xilinx/${VIVADO_VERSION}/vcs/${VCS_VERSION}

all: hwh bitstream

export ORIGIN_DIR

bitstream: ${BUILD_DIR}/${PROJECT_NAME}.bit
hwh: ${BUILD_DIR}/${PROJECT_NAME}.hwh

${BUILD_DIR}/${PROJECT_NAME}.bit: ${PROJECT_DIR}/${PROJECT_NAME}.xpr
	cd ${ORIGIN_DIR}; \
	${VIVADO} -mode batch ${VIVADO_ARGS} \
		-source ${SCRIPT_DIR}/tcl/build_bitstream.tcl ${PROJECT_DIR}/${PROJECT_NAME}.xpr
	cp ${PROJECT_DIR}/${DESIGN}_prj.runs/impl_1/${DESIGN}_wrapper.bit ${BUILD_DIR}/${PROJECT_NAME}.bit

${BUILD_DIR}/${PROJECT_NAME}.hwh: ${PROJECT_DIR}/${PROJECT_NAME}.xpr
	cd ${ORIGIN_DIR}; \
	${VIVADO} -mode batch ${VIVADO_ARGS} \
		-source ${SCRIPT_DIR}/tcl/build_hwh.tcl ${PROJECT_DIR}/${PROJECT_NAME}.xpr \
		-tclargs ${PROJECT_DIR}/${PROJECT_NAME}.srcs/sources_1/bd/${DESIGN}/${DESIGN}.bd
	cp  ${PROJECT_DIR}/${PROJECT_NAME}.gen/sources_1/bd/${DESIGN}/hw_handoff/${DESIGN}.hwh ${BUILD_DIR}/${PROJECT_NAME}.hwh

${PROJECT_DIR}/${PROJECT_NAME}.xpr: ${SCRIPT_DIR}/tcl/create_top_level_prj.tcl ${ORIGIN_DIR}/bd/${DESIGN}.tcl
	cd ${ORIGIN_DIR}; \
	${VIVADO} -mode batch ${VIVADO_ARGS} \
		-source ${SCRIPT_DIR}/tcl/create_top_level_prj.tcl \
		-tclargs ${ORIGIN_DIR}/bd/${DESIGN}.tcl ${PROJECT_NAME} ${PROJECT_DIR}

${SIM_DIR}/${PROJECT_NAME}: ${PROJECT_DIR}/${PROJECT_NAME}.xpr ${LIBRARY}/synopsys_sim.setup
	cd ${ORIGIN_DIR}; \
	${VIVADO} -mode batch ${VIVADO_ARGS} \
		-source ${SCRIPT_DIR}/tcl/build_sim_dir.tcl ${PROJECT_DIR}/${PROJECT_NAME}.xpr \
		-tclargs ${LIBRARY} vcs ${SIM_DIR}/${PROJECT_NAME} \
		${PROJECT_DIR}/${PROJECT_NAME}.srcs/sources_1/bd/${DESIGN}/${DESIGN}.bd

# TODO: Handle rtl dependencies properyly
${PROJECT_SIM_DIR}/${DESIGN}_wrapper.patched.sh: ${SIM_DIR}/${PROJECT_NAME} ${PROJECT_SIM_DIR}/${DESIGN}_wrapper.sh
	cd ${PROJECT_SIM_DIR}; \
	sed '/  elaborate/d;/  simulate/d' ${DESIGN}_wrapper.sh > ${DESIGN}_wrapper.patched.sh

${PROJECT_SIM_DIR}/vcs_lib/: ${PROJECT_SIM_DIR}/${DESIGN}_wrapper.patched.sh
	cd ${PROJECT_SIM_DIR}; \
	chmod 755 ${DESIGN}_wrapper.patched.sh; \
	./${DESIGN}_wrapper.patched.sh

${LIBRARY}/synopsys_sim.setup:
	mkdir -p ${LIBRARY}
	@echo "WARNING: Building simulation libraries from scratch will take ~45 minutes"
	@echo "         On wheatley you may simply set the environment variable:"
	@echo "             LIBRARY_BASE=/work/cudaa/simlibs"
	@echo "         to share a cache with other users"
	sleep 5
	@echo Proceading with compile for Vivado ${VIVADO_VERSION} with VCS ${VCS_VERSION}
	${VIVADO} -mode batch ${VIVADO_ARGS} \
		-source ${SCRIPT_DIR}/tcl/build_sim_libs.tcl ${PROJECT_DIR}/${PROJECT_NAME}.xpr \
		-tclargs ${LIBRARY} vcs $(shell which ${VCS} | xargs dirname)

project: ${PROJECT_DIR}/${PROJECT_NAME}.xpr
simulation_project: ${SIM_DIR}/${PROJECT_NAME}
simulation_compile: ${PROJECT_SIM_DIR}/vcs_lib/

shell: project
	cd ${ORIGIN_DIR}; ${VIVADO} -mode tcl ${VIVADO_ARGS} ${PROJECT_DIR}/${PROJECT_NAME}.xpr

timing: ${BUILD_DIR}/${PROJECT_NAME}.bit
	less ${PROJECT_DIR}/${DESIGN}_prj.runs/impl_1/${DESIGN}_wrapper_timing_summary_postroute_physopted.rpt

backup:
	cd ${BUILD_DIR}; tar czf ${PROJECT_NAME}.tar.gz ${PROJECT_NAME}

restore:
	cd ${BUILD_DIR}; rm -rf ${PROJECT_NAME}; tar zxf ${PROJECT_NAME}.tar.gz

clean:
	rm -rf ${PROJECT_DIR}
	rm -rf ${SIM_DIR}/${PROJECT_NAME}
	rm -rf ${BUILD_DIR}/${PROJECT_NAME}.bit
	rm -rf ${BUILD_DIR}/${PROJECT_NAME}.hwh

cleanall:
	rm -rf ${SIM_DIR}/*_prj
	rm -rf ${BUILD_DIR}/*_prj
	rm -rf ${BUILD_DIR}/*.bit
	rm -rf ${BUILD_DIR}/*.hwh

.PHONY: all clean cleanall backup restore project simulation_project simulation_compile shell hwh bitstream timing
