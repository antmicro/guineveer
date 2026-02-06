# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

TOPLEVEL = uart_top_wrapper

CALIPTRA_ROOT = $(abspath ${CURDIR}/../../third_party/caliptra-rtl)
UART_FLIST = $(subst $${CALIPTRA_ROOT},${CALIPTRA_ROOT},\
    $(file < ${CALIPTRA_ROOT}/src/uart/config/uart.vf))

VERILOG_SOURCES = \
    $(CALIPTRA_ROOT)/src/caliptra_prim/rtl/caliptra_prim_count_pkg.sv \
    $(filter-out +incdir+%,$(UART_FLIST)) \
    $(CURDIR)/uart_core_ahb/uart_top_wrapper.sv

VERILOG_INCLUDE_DIRS = \
    $(subst +incdir+,,$(filter +incdir+%,$(UART_FLIST)))

include $(CURDIR)/../common.mk
