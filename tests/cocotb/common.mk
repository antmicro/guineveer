# Copyright (c) 2025 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

$(info $(shell cocotb-config --makefiles))

TOPLEVEL_LANG    = verilog
SIM             ?= verilator
WAVES           ?= 1

# Paths
CURDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

TEST_FILES   = $(sort $(wildcard test_*.py))
MODULE      ?= $(subst $(space),$(comma),$(subst .py,,$(TEST_FILES)))

# Set pythonpath so that tests can access common modules
export PYTHONPATH := $(CURDIR)/common

# Coverage reporting
COVERAGE_TYPE ?= ""
ifeq ("$(COVERAGE_TYPE)", "all")
    VERILATOR_COVERAGE = --coverage
else ifeq ("$(COVERAGE_TYPE)", "branch")
    VERILATOR_COVERAGE = --coverage-line
else ifeq ("$(COVERAGE_TYPE)", "toggle")
    VERILATOR_COVERAGE = --coverage-toggle
else ifeq ("$(COVERAGE_TYPE)", "functional")
    VERILATOR_COVERAGE = --coverage-user
else
    VERILATOR_COVERAGE = ""
endif

ifeq ($(SIM), verilator)
    COMPILE_ARGS += --coverage-max-width 20000
    COMPILE_ARGS += --timing
    COMPILE_ARGS += -Wall -Wno-fatal

    EXTRA_ARGS   += --trace --trace-fst --trace-structs
    EXTRA_ARGS   += $(VERILATOR_COVERAGE)
    EXTRA_ARGS   += -I$(CFGDIR) -Wno-DECLFILENAME
endif

COCOTB_HDL_TIMEUNIT         = 1ns
COCOTB_HDL_TIMEPRECISION    = 10ps

# Build directory
ifneq ($(COVERAGE_TYPE),)
    SIM_BUILD := sim-build-$(COVERAGE_TYPE)
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
