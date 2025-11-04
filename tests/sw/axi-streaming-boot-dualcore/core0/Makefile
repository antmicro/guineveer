SCRIPT_DIR := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
TEST := axi-streaming-boot-dualcore

include $(SCRIPT_DIR)/../../common.mk

build: $(HEX_FILE)

clean:
	rm -rf $(BUILD_DIR)

all: build

test:
	@echo $(LIB_OBJS)

.PHONY: build clean all
