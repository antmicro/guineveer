# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

CORE ?= core0
TEST ?= uart
SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
TEST_DIR = $(abspath $(SCRIPT_DIR)/$(TEST))
BUILD_DIR := $(SCRIPT_DIR)/build
CORE_BUILD_DIR := $(BUILD_DIR)/$(CORE)

ELF_FILE_CORE := $(TEST_DIR)/$(CORE)/build/$(TEST).elf
ELF_FILE := $(CORE_BUILD_DIR)/$(TEST).elf

HEX_FILE_CORE := $(TEST_DIR)/$(CORE)/build/$(TEST).hex
HEX_FILE := $(CORE_BUILD_DIR)/$(TEST).hex

$(ELF_FILE_CORE):
	$(MAKE) -C $(TEST_DIR)/$(CORE) build

$(ELF_FILE): $(CORE_BUILD_DIR) $(ELF_FILE_CORE)
	cp $(ELF_FILE_CORE) $@

$(HEX_FILE_CORE): $(ELF_FILE_CORE)
	$(MAKE) -C $(TEST_DIR)/$(CORE) build

$(HEX_FILE): $(CORE_BUILD_DIR) $(HEX_FILE_CORE) 
	cp $(HEX_FILE_CORE) $@

$(BUILD_DIR):
	mkdir -p $@

$(CORE_BUILD_DIR): $(BUILD_DIR)
	mkdir -p $@

build: $(ELF_FILE) $(HEX_FILE)

clean:
	rm -rf $(BUILD_DIR)
	$(MAKE) -C $(TEST_DIR)/$(CORE) clean

all: build

.PHONY: build clean all
