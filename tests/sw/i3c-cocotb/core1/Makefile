# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
TEST := i3c-cocotb

include $(SCRIPT_DIR)/../../common.mk

build: $(HEX_FILE)

clean:
	rm -rf $(BUILD_DIR)

all: build

.PHONY: build clean all
