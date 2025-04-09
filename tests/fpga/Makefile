FPGA_SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
include $(FPGA_SCRIPT_DIR)/../../Makefile
TCL_FILE := $(FPGA_SCRIPT_DIR)/guineveer.tcl

generate_block_design: $(TCL_FILE)

$(TCL_FILE): $(FPGA_SCRIPT_DIR)/generate_project.sh
	HDL_SOURCES="$(VERILOG_SOURCES)" INCLUDE_DIRS="$(VERILOG_INCLUDE_DIRS)" RV_ROOT=$(RV_ROOT) HEX_FILE=$(HEX_FILE) $< > $(TCL_FILE)

.PHONY: generate_block_design
