# Copyright (c) 2025 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

TOPLEVEL = guineveer_i3c_dut

HW_DIR = $(abspath ${CURDIR}/../../hw)
BUILD_DIR = $(abspath ${CURDIR}/../../build)
RV_ROOT = $(abspath ${CURDIR}/../../third_party/Cores-VeeR-EL2)
CALIPTRA_ROOT = $(abspath ${CURDIR}/../../third_party/caliptra-rtl)
I3C_ROOT_DIR = $(abspath ${CURDIR}/../../third_party/i3c-core)
AXI_SOURCE_DIR = $(abspath ${CURDIR}/../../third_party/axi)

VEER_SNAPSHOT = $(BUILD_DIR)/snapshots/default
VEER_FLIST = \
	$(VEER_SNAPSHOT)/common_defines.vh \
	$(RV_ROOT)/design/include/el2_def.sv \
	$(VEER_SNAPSHOT)/el2_pdef.vh \
	$(subst -v,,$(subst $$RV_ROOT,${RV_ROOT},$(file < $(RV_ROOT)/design/flist))) \
	+incdir+$(RV_ROOT)/design/lib \
	+incdir+$(RV_ROOT)/design/include \
	+incdir+$(VEER_SNAPSHOT)
UART_FLIST = $(subst $${CALIPTRA_ROOT},${CALIPTRA_ROOT},\
    $(file < ${CALIPTRA_ROOT}/src/uart/config/uart.vf))
I3C_FLIST = $(subst $${CALIPTRA_ROOT},${CALIPTRA_ROOT},\
	$(subst $${I3C_ROOT_DIR},${I3C_ROOT_DIR},\
    $(file < $(I3C_ROOT_DIR)/src/i3c.f)))

AXI_INTERCON_FLIST=$(strip $(file < ${BUILD_DIR}/axi.f))
BENDER_INCLUDE_PATH=$(BUILD_DIR)/axi/.bender/git/checkouts
COMMON_CELLS_INCLUDE_PATH=$(abspath $(wildcard $(BENDER_INCLUDE_PATH)/common_cells-*/include/))
AXI_INCLUDE_PATH = $(abspath $(BUILD_DIR)/axi/include/)

define uniq =
	$(eval seen =)
	$(foreach _,$1,$(if $(filter $_,${seen}),,$(eval seen += $_)))
	$(seen)
endef

VERILOG_SOURCES_RAW=\
	$(CALIPTRA_ROOT)/src/caliptra_prim/rtl/caliptra_prim_count_pkg.sv \
	$(filter-out +incdir+%,$(I3C_FLIST)) \
	$(filter-out +incdir+%,$(UART_FLIST)) \
	$(filter-out +incdir+%,$(VEER_FLIST)) \
	$(AXI_INTERCON_FLIST) \
	$(HW_DIR)/axi_intercon.sv \
	$(HW_DIR)/guineveer_sram.sv \
	$(HW_DIR)/wrapped_uart.sv \
	$(HW_DIR)/guineveer.sv \
	$(CURDIR)/i3c/guineveer_i3c_dut.sv

VERILOG_SOURCES=$(strip $(call uniq,$(VERILOG_SOURCES_RAW)))

VERILOG_INCLUDE_DIRS_RAW=\
	$(subst +incdir+,,$(filter +incdir+%,$(UART_FLIST))) \
	$(subst +incdir+,,$(filter +incdir+%,$(I3C_FLIST))) \
	$(subst +incdir+,,$(filter +incdir+%,$(VEER_FLIST))) \
	$(COMMON_CELLS_INCLUDE_PATH) \
	$(AXI_INCLUDE_PATH)
VERILOG_INCLUDE_DIRS=$(strip $(call uniq,$(VERILOG_INCLUDE_DIRS_RAW)))

COMPILE_ARGS += +define+GUINEVEER_MEMORY_FILE='"'$(abspath ${CURDIR}/../../build/i3c-cocotb.hex)'"'

include $(CURDIR)/../common.mk
