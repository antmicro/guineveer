define uniq =
  $(eval seen :=)
    $(foreach _,$1,$(if $(filter $_,${seen}),,$(eval seen += $_)))
	${seen}
endef

defines := +define+DIGITAL_IO_I3C=1

SCRIPT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ROOT_DIR := $(abspath $(SCRIPT_DIR)/../../)
BUILD_DIR := $(ROOT_DIR)/build/renode_i3c_cosim

CALIPTRA_ROOT := $(ROOT_DIR)/third_party/caliptra-rtl
I3C_ROOT_DIR:= $(ROOT_DIR)/third_party/i3c-core
I3C_SRCLIST_RAW := $(subst $${CALIPTRA_ROOT},${CALIPTRA_ROOT},\
	$(subst $${I3C_ROOT_DIR},${I3C_ROOT_DIR},\
    $(file < ${I3C_ROOT_DIR}/src/i3c.f)))
I3C_INCLIST_RAW := $(subst +incdir+,,$(filter +incdir+%,$(I3C_SRCLIST_RAW)))
I3C_INCLIST = $(strip $(call uniq,$(I3C_INCLIST_RAW)))
I3C_SRCLIST := $(strip $(call uniq,$(filter-out +incdir+%,$(I3C_SRCLIST_RAW))))

RENODE_LIB_DIR := $(ROOT_DIR)/third_party/renode/src/Plugins/CoSimulationPlugin/IntegrationLibrary/
RENODE_SRCLIST := $(RENODE_LIB_DIR)/hdl/imports/renode_axi_pkg.sv \
	$(RENODE_LIB_DIR)/hdl/renode_pkg.sv \
	$(RENODE_LIB_DIR)/hdl/modules/renode_inputs.sv \
	$(RENODE_LIB_DIR)/hdl/modules/renode.sv \
	$(RENODE_LIB_DIR)/hdl/modules/axi/renode_axi_if.sv \
	$(RENODE_LIB_DIR)/hdl/modules/axi/renode_axi_manager.sv \
	$(RENODE_LIB_DIR)/src/renode_dpi.cpp \
	$(RENODE_LIB_DIR)/src/communication/socket_channel.cpp \
	$(RENODE_LIB_DIR)/libs/socket-cpp/Socket/TCPClient.cpp \
	$(RENODE_LIB_DIR)/libs/socket-cpp/Socket/Socket.cpp
RENODE_INCLIST := $(RENODE_LIB_DIR) \
	$(RENODE_LIB_DIR)/hdl \
	$(RENODE_LIB_DIR)/hdl/includes \
	$(RENODE_LIB_DIR)/src

ALL_SRCS = $(I3C_SRCLIST) $(RENODE_SRCLIST) $(SCRIPT_DIR)/renode_i3c_cosim.sv
ALL_INCLS = $(I3C_INCLIST) $(RENODE_INCLIST) $(VERILOG_INCLUDE_DIRS)

VERILATOR_SKIP_WARNINGS := $(VERILATOR_NOIMPLICIT) -Wno-TIMESCALEMOD -Wno-SELRANGE \
	-Wno-CASEINCOMPLETE -Wno-INITIALDLY -Wno-WIDTH -Wno-UNOPTFLAT -Wno-REDEFMACRO \
	-Wno-LATCH -Wno-MULTIDRIVEN -Wno-UNSIGNED -Wno-CMPCONST

$(BUILD_DIR)/Vsim: $(ALL_SRCS) $(ALL_INCLS) | $(BUILD_DIR)
	verilator --cc -CFLAGS "-std=c++14" -coverage-max-width 20000 $(defines) \
	  $(addprefix -I,$(ALL_INCLS)) -Mdir $(BUILD_DIR) \
	  $(VERILATOR_SKIP_WARNINGS) $(VERILATOR_EXTRA_ARGS) ${ALL_SRCS} --top-module sim\
	  --main --exe --build --autoflush --timing $(VERILATOR_DEBUG) $(VERILATOR_COVERAGE) -fno-table

$(BUILD_DIR):
	mkdir -p $@
