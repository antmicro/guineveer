# Copyright (c) 2025 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

TOPLEVEL = guineveer_cocotb_dut

SCRIPT_DIR := $(abspath ${CURDIR}/../../../)

include $(SCRIPT_DIR)/design/src/rtl.mk

VERILOG_SOURCES += $(abspath $(SCRIPT_DIR)/design/testbench/guineveer_cocotb_dut.sv)


COMPILE_ARGS += +define+HEX_FILE0='"'$(abspath ${CURDIR}/../sw/build/core0/axi-streaming-boot-dualcore.hex)'"'
COMPILE_ARGS += +define+HEX_FILE1='"'$(abspath ${CURDIR}/../sw/build/core1/axi-streaming-boot-dualcore.hex)'"'

VERILATOR_SKIP_WARNINGS = -Wno-REDEFMACRO

include $(CURDIR)/../common.mk
