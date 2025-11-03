FPGA_SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
include $(FPGA_SCRIPT_DIR)/../../Makefile
TCL_FILE := $(FPGA_SCRIPT_DIR)/guineveer.tcl
BOARD ?= Arty-A7-100T

TEST ?= uart

HEX_FILE0 ?= $(FPGA_SCRIPT_DIR)/../../tests/sw/build/core0/$(TEST).hex
HEX_FILE1 ?= $(FPGA_SCRIPT_DIR)/../../tests/sw/build/core1/$(TEST).hex

generate_block_design: $(TCL_FILE)

$(TCL_FILE): $(FPGA_SCRIPT_DIR)/generate_project.sh
	HDL_SOURCES="$(VERILOG_SOURCES)" INCLUDE_DIRS="$(VERILOG_INCLUDE_DIRS)" RV_ROOT=$(RV_ROOT) HEX_FILE0=$(HEX_FILE0) HEX_FILE1=$(HEX_FILE1) BOARD=$(BOARD) $< > $(TCL_FILE)

clean:
	rm $(TCL_FILE)

.PHONY: generate_block_design clean
