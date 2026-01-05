BUILD_DIR ?= $(SCRIPT_DIR)/build
LIB_BUILD_DIR := $(BUILD_DIR)/lib
SW_DIR ?= $(SCRIPT_DIR)/../..

RV_ROOT ?= $(SW_DIR)/../../third_party/Cores-VeeR-EL2

LD_ABI ?= -mabi=ilp32 -march=rv32imac
CC_ABI ?= -mabi=ilp32 -march=rv32imc_zicsr_zifencei
GCC_PREFIX ?= riscv64-unknown-elf

TEST_SRCS ?= $(wildcard $(SCRIPT_DIR)/src/*.c $(SCRIPT_DIR)/src/*.s)
TEST_OBJS ?= $(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(notdir $(basename $(TEST_SRCS)))))

PICOLIBC_DIR ?= $(BUILD_DIR)/picolibc
PICOLIBC_SPECS ?=  $(PICOLIBC_DIR)/install/picolibc.specs

LINK ?= $(SCRIPT_DIR)/src/$(TEST).ld
HEX_FILE ?= $(BUILD_DIR)/$(TEST).hex
ELF_FILE ?= $(BUILD_DIR)/$(TEST).elf

LIBS ?= uart i3c utils

LIBS_DIR := $(SW_DIR)/libs
LIB_INCLUDES := $(addprefix -I,$(addprefix $(LIBS_DIR)/,$(LIBS)))

LIB_SRCS_C := $(foreach lib,$(LIBS),$(wildcard $(LIBS_DIR)/$(lib)/*.c))
LIB_SRCS_S := $(foreach lib,$(LIBS),$(wildcard $(LIBS_DIR)/$(lib)/*.s))

LIB_OBJS := $(patsubst $(LIBS_DIR)/%.c,$(LIB_BUILD_DIR)/%.o,$(LIB_SRCS_C)) \
  $(patsubst $(LIBS_DIR)/%.s,$(LIB_BUILD_DIR)/%.o,$(LIB_SRCS_S))

$(ELF_FILE): $(PICOLIBC_SPECS) $(TEST_OBJS) $(BUILD_DIR) $(LIB_OBJS)
	$(GCC_PREFIX)-gcc $(LD_ABI) $(ADDITIONAL_LINKER_FLAGS) --verbose -Wl,-Map=$(BUILD_DIR)/$(TEST).map -T$(LINK) \
			--specs=$(PICOLIBC_SPECS) -nostartfiles $(TEST_OBJS) $(LIB_OBJS) -o $@
	$(GCC_PREFIX)-objdump -S $@ > $(BUILD_DIR)/$(TEST).dis
	$(GCC_PREFIX)-nm -B -n $@ > $(BUILD_DIR)/$(TEST).sym

$(HEX_FILE): $(ELF_FILE)
	$(GCC_PREFIX)-objcopy -O verilog --verilog-data-width=8 $^ $@
	cp $@ $@.original
	sed -i s/@../@00/g $@

$(PICOLIBC_SPECS): | $(BUILD_DIR)
	mkdir -p $(PICOLIBC_DIR)
	$(MAKE) -f ${RV_ROOT}/tools/picolibc.mk all BUILD_PATH=$(PICOLIBC_DIR)/build INSTALL_PATH=$(PICOLIBC_DIR)/install

$(BUILD_DIR)/%.o: $(SCRIPT_DIR)/src/%.s $(PICOLIBC_SPECS) | $(CORE_BUILD_DIR)
	$(GCC_PREFIX)-gcc $(ADDITIONAL_GCC_FLAGS) --specs=$(PICOLIBC_SPECS) ${CC_ABI} -c $< -o $@

$(BUILD_DIR)/%.o: $(SCRIPT_DIR)/src/%.c $(PICOLIBC_SPECS) $(GENERATED_PAYLOAD) | $(CORE_BUILD_DIR)
	$(GCC_PREFIX)-gcc $(ADDITIONAL_GCC_FLAGS) --specs=$(PICOLIBC_SPECS) $(CPPFLAGS) $(LIB_INCLUDES) ${CC_ABI} -c $< -o $@

$(LIB_BUILD_DIR)/%.o: $(LIBS_DIR)/%.c $(PICOLIBC_SPECS) | $(LIB_BUILD_DIR)
	mkdir -p $(dir $@)
	$(GCC_PREFIX)-gcc $(ADDITIONAL_GCC_FLAGS) --specs=$(PICOLIBC_SPECS) ${CC_ABI} $(LIB_INCLUDES) -c $< -o $@

$(LIB_BUILD_DIR)/%.o: $(LIBS_DIR)/%.s $(PICOLIBC_SPECS) | $(LIB_BUILD_DIR)
	mkdir -p $(dir $@)
	$(GCC_PREFIX)-gcc $(ADDITIONAL_GCC_FLAGS) -Os -ffunction-sections -fdata-sections --specs=$(PICOLIBC_SPECS) ${CC_ABI} -c $< -o $@

$(BUILD_DIR):
	mkdir -p $@

$(LIB_BUILD_DIR): $(BUILD_DIR)
	mkdir -p $@
