ORIGIN_DIR := .
BUILD_DIR := ${ORIGIN_DIR}/build/
SCRIPT_DIR := ${ORIGIN_DIR}/scripts/

DESIGN ?= gen3_top
PROJECT_NAME ?= ${DESIGN}_prj
PROJECT_DIR ?= ${BUILD_DIR}/${PROJECT_NAME}

VIVADO ?= vivado
VIVADO_ARGS ?= -nojou -nolog

all: ${BUILD_DIR}/${DESIGN}.bit

export ORIGIN_DIR

${BUILD_DIR}/${DESIGN}.bit: ${PROJECT_DIR}/${PROJECT_NAME}.xpr
	cd ${ORIGIN_DIR}; ${VIVADO} -mode batch ${VIVADO_ARGS} -source ${SCRIPT_DIR}/tcl/build_bitstream.tcl ${PROJECT_DIR}/${PROJECT_NAME}.xpr
	cp ${PROJECT_DIR}/${DESIGN}_prj.runs/impl_1/${DESIGN}_wrapper.bit ${BUILD_DIR}/${DESIGN}.bit

${PROJECT_DIR}/${PROJECT_NAME}.xpr: ${SCRIPT_DIR}/tcl/create_top_level_prj.tcl ${ORIGIN_DIR}/bd/${DESIGN}.tcl
	echo ${PROJECT_DIR}
	cd ${ORIGIN_DIR}; ${VIVADO} -mode batch ${VIVADO_ARGS} -source ${SCRIPT_DIR}/tcl/create_top_level_prj.tcl -tclargs ${ORIGIN_DIR}/bd/${DESIGN}.tcl ${PROJECT_NAME} ${PROJECT_DIR}

project: ${PROJECT_DIR}/${PROJECT_NAME}.xpr

clean:
	rm -rf ${BUILD_DIR}/*_prj
	rm -rf ${BUILD_DIR}/*.bit
	rm -rf ${BUILD_DIR}/*.hwh

.PHONY: project clean all
