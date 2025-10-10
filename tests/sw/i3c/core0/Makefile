SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
TEST := i3c

include $(SCRIPT_DIR)/../../common.mk

build: $(HEX_FILE)

clean:
	rm -rf $(BUILD_DIR)

all: build

.PHONY: build clean all
