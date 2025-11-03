# Copyright (c) 2025 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

# Makefile fragment that provides variables with all the Verilog sources.
# Requires SCRIPT_DIR to be set to the path of the root of the repository.

HW_DIR := $(SCRIPT_DIR)/design/src
TB_DIR := $(SCRIPT_DIR)/design/testbench
TW_DIR := $(SCRIPT_DIR)/topwrap
BUILD_DIR := $(SCRIPT_DIR)/build
RV_ROOT := $(SCRIPT_DIR)/third_party/Cores-VeeR-EL2
CALIPTRA_ROOT := $(SCRIPT_DIR)/third_party/caliptra-rtl
I3C_ROOT_DIR := $(SCRIPT_DIR)/third_party/i3c-core
PICOLIBC_DIR := $(BUILD_DIR)/picolibc
PICOLIBC_SPECS :=  $(PICOLIBC_DIR)/install/picolibc.specs

VEER_SNAPSHOT := $(BUILD_DIR)/snapshots/default
VEER_FLIST := \
	$(VEER_SNAPSHOT)/common_defines.vh \
	$(RV_ROOT)/design/include/el2_def.sv \
	$(VEER_SNAPSHOT)/el2_pdef.vh \
	$(RV_ROOT)/verification/block/config.vlt \
	$(subst -v,,$(subst $$RV_ROOT,${RV_ROOT},$(file < $(RV_ROOT)/design/flist))) \
	+incdir+$(RV_ROOT)/design/lib \
	+incdir+$(RV_ROOT)/design/include \
	+incdir+$(VEER_SNAPSHOT)
UART_FLIST := $(subst $${CALIPTRA_ROOT},${CALIPTRA_ROOT},\
    $(file < ${CALIPTRA_ROOT}/src/uart/config/uart.vf))
I3C_FLIST := $(subst $${CALIPTRA_ROOT},${CALIPTRA_ROOT},\
	$(subst $${I3C_ROOT_DIR},${I3C_ROOT_DIR},\
    $(file < $(I3C_ROOT_DIR)/src/i3c.f)))

AXI_SOURCE_DIR = $(abspath $(SCRIPT_DIR)/third_party/axi)

AXI_INTERCON_FLIST=$(strip $(file < ${BUILD_DIR}/axi.f))
BENDER_INCLUDE_PATH=$(BUILD_DIR)/axi/.bender/git/checkouts
COMMON_CELLS_INCLUDE_PATH=$(abspath $(wildcard $(BENDER_INCLUDE_PATH)/common_cells-*/include/))
AXI_INCLUDE_PATH = $(abspath $(BUILD_DIR)/axi/include/)

define uniq =
	$(eval seen =)
	$(foreach _,$1,$(if $(filter $_,${seen}),,$(eval seen += $_)))
	$(seen)
endef

VERILOG_CORE_SOURCES_RAW=\
    $(CALIPTRA_ROOT)/src/caliptra_prim/rtl/caliptra_prim_count_pkg.sv \
	$(filter-out +incdir+%,$(I3C_FLIST)) \
	$(filter-out +incdir+%,$(UART_FLIST)) \
	$(filter-out +incdir+%,$(VEER_FLIST)) \
	$(AXI_INTERCON_FLIST) \
	$(HW_DIR)/waivers.vlt \
	$(HW_DIR)/axi_intercon.sv \
	$(HW_DIR)/guineveer_sram.sv \
	$(HW_DIR)/sram_wrapper.sv \
	$(HW_DIR)/uart_wrapper.sv \
	$(HW_DIR)/axi_cdc_wrapper.sv

VERILOG_CORE_SOURCES=$(strip $(call uniq,$(VERILOG_CORE_SOURCES_RAW)))
VERILOG_SOURCES=$(VERILOG_CORE_SOURCES) $(HW_DIR)/guineveer.sv

VERILOG_INCLUDE_DIRS_RAW=\
    $(subst +incdir+,,$(filter +incdir+%,$(UART_FLIST))) \
	$(subst +incdir+,,$(filter +incdir+%,$(I3C_FLIST))) \
	$(subst +incdir+,,$(filter +incdir+%,$(VEER_FLIST))) \
	$(COMMON_CELLS_INCLUDE_PATH) \
	$(AXI_INCLUDE_PATH)
VERILOG_INCLUDE_DIRS=$(strip $(call uniq,$(VERILOG_INCLUDE_DIRS_RAW)))
