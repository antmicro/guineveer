# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
TEST := axi-streaming-boot-dualcore

ADDITIONAL_GCC_FLAGS := -DMAX_STREAMING_BOOT_SIZE=0x2000

include $(SCRIPT_DIR)/../../common.mk

build: $(HEX_FILE)

clean:
	rm -rf $(BUILD_DIR)

all: build

test:
	@echo $(LIB_OBJS)

.PHONY: build clean all
