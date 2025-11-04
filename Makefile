# Copyright (c) 2025 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

VEER_CONFIGURATION_FLAGS ?= \
    -fpga_optimize=1 \
    -unset=assert_on \
    -set=reset_vec=0x80000000 \
    -set=ret_stack_size=2 \
    -set=btb_enable=0 \
    -set=btb_size=8 \
    -set=bht_size=32 \
    -set=dccm_size=16 \
    -set=dccm_num_banks=2 \
    -set=iccm_enable=0 \
    -set=icache_enable=0 \
    -set=dccm_enable=0 \
    -set=dma_buf_depth=2 \
    -set=div_bit=1 \
    -set=pic_total_int=8 \

SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
HW_DIR := $(SCRIPT_DIR)/hw
TB_DIR := $(SCRIPT_DIR)/testbench
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

VERILOG_SOURCES_RAW=\
    $(CALIPTRA_ROOT)/src/caliptra_prim/rtl/caliptra_prim_count_pkg.sv \
	$(filter-out +incdir+%,$(I3C_FLIST)) \
	$(filter-out +incdir+%,$(UART_FLIST)) \
	$(filter-out +incdir+%,$(VEER_FLIST)) \
	$(AXI_INTERCON_FLIST) \
	$(HW_DIR)/waivers.vlt \
	$(HW_DIR)/axi_intercon.sv \
	$(HW_DIR)/guineveer_sram.sv \
	$(HW_DIR)/wrapped_uart.sv \
	$(HW_DIR)/guineveer.sv

VERILOG_SOURCES=$(strip $(call uniq,$(VERILOG_SOURCES_RAW)))

VERILOG_INCLUDE_DIRS_RAW=\
    $(subst +incdir+,,$(filter +incdir+%,$(UART_FLIST))) \
	$(subst +incdir+,,$(filter +incdir+%,$(I3C_FLIST))) \
	$(subst +incdir+,,$(filter +incdir+%,$(VEER_FLIST))) \
	$(COMMON_CELLS_INCLUDE_PATH) \
	$(AXI_INCLUDE_PATH)
VERILOG_INCLUDE_DIRS=$(strip $(call uniq,$(VERILOG_INCLUDE_DIRS_RAW)))

LD_ABI := -mabi=ilp32 -march=rv32imac
CC_ABI := -mabi=ilp32 -march=rv32imc_zicsr_zifencei
GCC_PREFIX := riscv64-unknown-elf

EXT_HEX := $(if $(HEX_FILE),1,)
EXT_ELF := $(if $(ELF_FILE),1,)
TEST ?= uart
TEST_DIR := $(SCRIPT_DIR)/tests/sw/$(TEST)
TEST_SRCS := $(wildcard $(TEST_DIR)/*.c $(TEST_DIR)/*.s)
TEST_OBJS := $(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(notdir $(basename $(TEST_SRCS)))))
LINK := $(TEST_DIR)/$(TEST).ld
HEX_FILE := $(BUILD_DIR)/$(TEST).hex
ELF_FILE := $(BUILD_DIR)/$(TEST).elf
-include $(TEST_DIR)/$(TEST).mki

TB_FILES = $(VERILOG_SOURCES) $(TB_DIR)/guineveer_tb.sv
TB_INCLS = $(VERILOG_INCLUDE_DIRS) $(TB_DIR) $(RV_ROOT)/testbench

# -Wno-REDEFMACRO is needed because RV_TOP is first defined in some header in caliptra-rtl,
# and then is redefined (to the correct value) in the VeeR config header.
VERILATOR_SKIP_WARNINGS = -Wno-REDEFMACRO

VERILATOR_DEBUG := --trace-fst --trace-structs

SOC_WRAPPER_DEPS := \
	$(wildcard $(TW_DIR)/ipcores/*) \
	$(wildcard $(TW_DIR)/repo/interfaces/*) \
	$(TW_DIR)/design.yaml \
	$(TW_DIR)/topwrap.yaml \
	$(TW_DIR)/topwrap_script.py


all: testbench

clean: | $(BUILD_DIR)
	rm -rf $(BUILD_DIR) $(HW_DIR)/axi_intercon.sv $(HW_DIR)/guineveer.sv

hw: $(HW_DIR)/axi_intercon.sv $(VEER_SNAPSHOT) $(BUILD_DIR)/axi.f $(HW_DIR)/guineveer.sv

testbench: $(BUILD_DIR)/obj_dir/Vguineveer_tb | $(BUILD_DIR)

sim: $(BUILD_DIR)/sim.vcd

build_test: $(HEX_FILE)

renode_test: $(BUILD_DIR)/report.html

$(HW_DIR)/guineveer.sv: $(SOC_WRAPPER_DEPS)
	mkdir -p $(TW_DIR)/repo/cores
	cd $(TW_DIR) && python3 topwrap_script.py

$(VEER_SNAPSHOT): $(VEER_SNAPSHOT)/common_defines.vh
$(VEER_SNAPSHOT)/%: | $(BUILD_DIR)
	export RV_ROOT=$(RV_ROOT) && \
	cd $(BUILD_DIR) && \
	$(RV_ROOT)/configs/veer.config $(VEER_CONFIGURATION_FLAGS)

$(AXI_INCLUDE_PATH): $(BUILD_DIR)/axi.f
$(COMMON_CELLS_INCLUDE_PATH): $(BUILD_DIR)/axi.f
$(BUILD_DIR)/axi.f: $(HW_DIR)/gen_flist.sh | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/axi
	cp $(AXI_SOURCE_DIR)/Bender.yml $(BUILD_DIR)/axi
	cp -r $(AXI_SOURCE_DIR)/src $(BUILD_DIR)/axi
	cp -r $(AXI_SOURCE_DIR)/include $(BUILD_DIR)/axi
	export OUTPUT_FILE_LOCATION=$@ && export BENDER_MANIFEST_DIR=$(BUILD_DIR)/axi && $<
# Replace axi_pkg with axi_axi_pkg in axi submodule due to package collision with caliptra-rtl
	find $(BUILD_DIR) -type f -name "*.sv" -exec sed -i 's/axi_pkg/axi_axi_pkg/g' {} +
	find $(BUILD_DIR) -type f -name "*.svh" -exec sed -i 's/axi_pkg/axi_axi_pkg/g' {} +

$(HW_DIR)/axi_intercon.sv: $(HW_DIR)/interconnect_utils/gen_inter_wrapper.sh $(HW_DIR)/interconnect_utils/intercon_config.yaml $(BUILD_DIR)/axi.f
	$<
	sed -i 's/axi_pkg/axi_axi_pkg/g' $(HW_DIR)/axi_intercon.sv

$(BUILD_DIR)/sim.vcd: $(HEX_FILE) testbench | $(BUILD_DIR)
	HEX_TEMP=$$(mktemp) && sed s/@./@0/g < $< > $$HEX_TEMP && \
	cd $(BUILD_DIR) && ./obj_dir/Vguineveer_tb +firmware=$$HEX_TEMP ${TB_EXTRA_ARGS};

$(BUILD_DIR)/obj_dir/Vguineveer_tb: $(TB_FILES) $(TB_INCLS) $(TB_CPPS) | $(BUILD_DIR)
	verilator --cc -CFLAGS "-std=c++14" -coverage-max-width 20000 $(defines) \
	  $(addprefix -I,$(TB_INCLS)) -Mdir $(BUILD_DIR)/obj_dir \
	  $(VERILATOR_SKIP_WARNINGS) $(VERILATOR_EXTRA_ARGS) ${TB_FILES} --top-module guineveer_tb \
	  --main --exe --build --autoflush --timing $(VERILATOR_DEBUG) $(VERILATOR_COVERAGE) -fno-table
	$(MAKE) -e -C $(BUILD_DIR)/obj_dir/ -f Vguineveer_tb.mk $(VERILATOR_MAKE_FLAGS)

# Don't build/rebuild if the exec or the hex files were specified by user
ifneq ($(EXT_HEX),1)
$(HEX_FILE): $(ELF_FILE)
	$(GCC_PREFIX)-objcopy -O verilog --verilog-data-width=8 $^ $@
	sed -i s/@./@0/g $@ # Remove offset
endif

ifneq ($(EXT_ELF),1)
$(ELF_FILE): $(PICOLIBC_SPECS) $(TEST_OBJS)
	$(GCC_PREFIX)-gcc $(LD_ABI) --verbose -Wl,-Map=$(BUILD_DIR)/$(TEST).map -T$(LINK) \
			--specs=$(PICOLIBC_SPECS) $(TEST_LIBS) -nostartfiles $(TEST_OBJS) -o $@
	$(GCC_PREFIX)-objdump -S $@ > $(BUILD_DIR)/$(TEST).dis
	$(GCC_PREFIX)-nm -B -n $@ > $(BUILD_DIR)/$(TEST).sym
else
$(if $(wildcard $(ELF_FILE)),$(shell touch $(ELF_FILE)),)
endif

$(BUILD_DIR)/%.o: $(TEST_DIR)/%.c $(PICOLIBC_SPECS) | $(BUILD_DIR)
	$(GCC_PREFIX)-gcc --specs=$(PICOLIBC_SPECS) ${CC_ABI} -c $< -o $@

$(BUILD_DIR)/%.o: $(TEST_DIR)/%.s $(PICOLIBC_SPECS) | $(BUILD_DIR)
	$(GCC_PREFIX)-gcc --specs=$(PICOLIBC_SPECS) ${CC_ABI} -c $< -o $@

$(PICOLIBC_SPECS): | $(BUILD_DIR)
	mkdir -p $(PICOLIBC_DIR)
	$(MAKE) -f ${RV_ROOT}/tools/picolibc.mk all BUILD_PATH=$(PICOLIBC_DIR)/build INSTALL_PATH=$(PICOLIBC_DIR)/install

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/report.html: build_test
	cd $(BUILD_DIR) && renode-test $(SCRIPT_DIR)/sw/guineveer_$(TEST).robot

.PHONY: all clean $(BUILD_DIR)/sim.vcd $(BUILD_DIR)/report.html hw testbench sim build_test renode_test
.PRECIOUS: $(BUILD_DIR)/sim.vcd
