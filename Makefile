ORIGIN_DIR := .
BUILD_DIR := ${ORIGIN_DIR}/build
SCRIPT_DIR := ${ORIGIN_DIR}/scripts

DESIGN ?= gen3_top
PROJECT_NAME ?= ${DESIGN}_prj
PROJECT_DIR ?= ${BUILD_DIR}/${PROJECT_NAME}

VIVADO ?= vivado
VIVADO_ARGS ?= -nojou -nolog

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

project: ${PROJECT_DIR}/${PROJECT_NAME}.xpr

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
	rm -rf ${BUILD_DIR}/${PROJECT_NAME}.bit
	rm -rf ${BUILD_DIR}/${PROJECT_NAME}.hwh

cleanall:
	rm -rf ${BUILD_DIR}/*_prj
	rm -rf ${BUILD_DIR}/*.bit
	rm -rf ${BUILD_DIR}/*.hwh

.PHONY: all clean cleanall backup restore project shell hwh bitstream timing
