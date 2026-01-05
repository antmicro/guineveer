SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
TEST := payload
RV_ROOT ?= $(SCRIPT_DIR)/../../../../../third_party/Cores-VeeR-EL2

SW_DIR := $(SCRIPT_DIR)/../../../
BUILD_DIR := $(SCRIPT_DIR)/build
H_FILE := $(BUILD_DIR)/$(TEST).h
BIN_FILE := $(BUILD_DIR)/$(TEST).bin

ADDITIONAL_LINKER_FLAGS := -Wl,--gc-sections -mno-relax
ADDITIONAL_GCC_FLAGS := -Os -ffunction-sections -fdata-sections -fPIC -mcmodel=medany -mno-relax -fvisibility=hidden

include $(SCRIPT_DIR)/../../../common.mk

$(BIN_FILE): $(ELF_FILE)
	$(GCC_PREFIX)-objcopy -O binary $^ $@

$(H_FILE): $(BIN_FILE)
	xxd -n payload -i $^ > $@

build: $(H_FILE)

clean:
	rm -rf $(BUILD_DIR)

all: build

.PHONY: build clean all
