# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

import cocotb
import struct

from cocotb.triggers import Timer
from cocotb.handle import HierarchyObject
from util import begin_test, read_line, setup, timeout_task

@cocotb.test
async def test_axi_streaming_boot(dut: HierarchyObject):
    """
    Test whether AXI streaming boot works.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)

    cocotb.start_soon(timeout_task(50))

    # AXI streaming boot is mostly driven by the firmware, so we don't have much to do here.

    # Wait for a message from the booted image.
    line = await read_line(uart_sink)
    assert line == "Hello from AXI streaming boot image."
