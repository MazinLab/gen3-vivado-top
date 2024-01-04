ORIGIN_DIR := .
DESIGN ?= gen3_top
DESIGN_DIR ?= ${DESIGN}_prj

VIVADO ?= vivado
VIVADO_ARGS ?= -nojou -nolog

all: ${DESIGN}

${DESIGN}: ${DESIGN}.bit

${DESIGN_DIR}/${DESIGN}.xpr: ${ORIGIN_DIR}/create_top_level_prj.tcl ${ORIGIN_DIR}/bd/${DESIGN}.tcl ${ORIGIN_DIR}/${DESIGN}.
	cd ${ORIGIN_DIR}; ${VIVADO} -mode batch ${VIVADO_ARGS} -source ./create_top_level_prj.tcl
