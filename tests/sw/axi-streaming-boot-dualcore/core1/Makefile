# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
TEST := axi-streaming-boot-dualcore

BUILD_DIR := $(SCRIPT_DIR)/build

GENERATED_DIR := $(BUILD_DIR)/generated
GENERATED_PAYLOAD := $(GENERATED_DIR)/payload.h

CPPFLAGS := -I$(GENERATED_DIR)

include $(SCRIPT_DIR)/../../common.mk

$(GENERATED_PAYLOAD): $(GENERATED_DIR)
	$(MAKE) -C payload build
	cp payload/build/payload.h $@

$(GENERATED_DIR): $(BUILD_DIR)
	mkdir -p $@

generate: $(GENERATED_PAYLOAD)

build: $(HEX_FILE)

clean:
	$(MAKE) -C payload clean
	rm -rf $(BUILD_DIR)

all: build

.PHONY: build clean generate all
