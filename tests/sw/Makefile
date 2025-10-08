CORE ?= core0
TEST ?= uart
SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
TEST_DIR = $(abspath $(SCRIPT_DIR)/$(TEST))
BUILD_DIR := $(SCRIPT_DIR)/build
CORE_BUILD_DIR := $(abspath $(BUILD_DIR)/$(CORE))

LD_ABI := -mabi=ilp32 -march=rv32imac
CC_ABI := -mabi=ilp32 -march=rv32imc_zicsr_zifencei
GCC_PREFIX := riscv64-unknown-elf

RV_ROOT := $(SCRIPT_DIR)/../../third_party/Cores-VeeR-EL2

TEST_SRCS := $(wildcard $(TEST_DIR)/$(CORE)/*.c $(TEST_DIR)/$(CORE)/*.s)
TEST_OBJS := $(addprefix $(CORE_BUILD_DIR)/,$(addsuffix .o,$(notdir $(basename $(TEST_SRCS)))))

PICOLIBC_DIR := $(BUILD_DIR)/$(CORE)/picolibc
PICOLIBC_SPECS :=  $(PICOLIBC_DIR)/install/picolibc.specs

LINK := $(abspath $(TEST_DIR)/$(CORE)/$(TEST).ld)
HEX_FILE := $(CORE_BUILD_DIR)/$(TEST).hex
ELF_FILE := $(CORE_BUILD_DIR)/$(TEST).elf

$(ELF_FILE): $(PICOLIBC_SPECS) $(TEST_OBJS) $(CORE_BUILD_DIR)
	$(GCC_PREFIX)-gcc $(LD_ABI) --verbose -Wl,-Map=$(CORE_BUILD_DIR)/$(TEST).map -T$(LINK) \
			--specs=$(PICOLIBC_SPECS) $(TEST_LIBS) -nostartfiles $(TEST_OBJS) -o $@
	$(GCC_PREFIX)-objdump -S $@ > $(BUILD_DIR)/$(CORE)/$(TEST).dis
	$(GCC_PREFIX)-nm -B -n $@ > $(BUILD_DIR)/$(CORE)/$(TEST).sym

$(HEX_FILE): $(ELF_FILE)
	$(GCC_PREFIX)-objcopy -O verilog --verilog-data-width=8 $^ $@
	cp $@ $@.original
	sed -i s/@../@00/g $@

$(PICOLIBC_SPECS): | $(BUILD_DIR)
	mkdir -p $(PICOLIBC_DIR)
	$(MAKE) -f ${RV_ROOT}/tools/picolibc.mk all BUILD_PATH=$(PICOLIBC_DIR)/build INSTALL_PATH=$(PICOLIBC_DIR)/install

$(CORE_BUILD_DIR)/%.o: $(TEST_DIR)/$(CORE)/%.s $(PICOLIBC_SPECS) | $(CORE_BUILD_DIR)
	$(GCC_PREFIX)-gcc --specs=$(PICOLIBC_SPECS) ${CC_ABI} -c $< -o $@

$(CORE_BUILD_DIR)/%.o: $(TEST_DIR)/$(CORE)/%.c $(PICOLIBC_SPECS) | $(CORE_BUILD_DIR)
	$(GCC_PREFIX)-gcc --specs=$(PICOLIBC_SPECS) ${CC_ABI} -c $< -o $@

$(BUILD_DIR):
	mkdir -p $@

$(CORE_BUILD_DIR): $(BUILD_DIR)
	mkdir -p $@

build: $(HEX_FILE)

clean:
	rm -rf $(BUILD_DIR)

all: build

.PHONY: build clean all
