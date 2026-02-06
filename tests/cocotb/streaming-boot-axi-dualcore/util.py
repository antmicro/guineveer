# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

from cocotb.clock import Clock
from cocotb.handle import HierarchyObject
from cocotb.triggers import ClockCycles, Timer
from cocotbext.uart import UartSink, UartSource
from cocotbext_i3c.i3c_controller import I3cController


async def read_line(uart_sink: UartSink) -> str:
    buf = list[int]()

    while not buf or buf[-1] != ord("\n"):
        buf += await uart_sink.read(count=1)

    return bytes(buf).decode("utf-8").rstrip("\r\n")


async def reset(dut: HierarchyObject):
    dut.uart_rx_i.value = 1

    dut.i3c_scl_i.value = 1
    dut.i3c_sda_i.value = 1

    dut.rst_ni.value = 0
    await ClockCycles(dut.core_clk_o, 2)
    dut.rst_ni.value = 1
    await ClockCycles(dut.core_clk_o, 2)


async def setup(dut: HierarchyObject) -> tuple[Clock, Clock, I3cController, UartSink, UartSource]:
    await reset(dut)

    i3c_ctrl = I3cController(
        sda_i=dut.i3c_sda_o,
        # TODO: This signal is omitted because of performance and memory usage problems with the
        # I3cController bus watching logic. Doing this prevents us from listening for IBIs.
        # scl_i=dut.i3c_scl_o,
        scl_i=None,
        sda_o=dut.i3c_sda_i,
        scl_o=dut.i3c_scl_i,
    )

    baud = 115200
    uart_sink = UartSink(dut.uart_tx_o, baud=baud)
    uart_source = UartSource(dut.uart_rx_i, baud=baud)

    return i3c_ctrl, uart_sink, uart_source


async def begin_test(uart_sink: UartSink, uart_source: UartSource, test_case: str):
    line = await read_line(uart_sink)
    assert line == "Hi Cocotb"

    await uart_source.write([ord(test_case)])
    await uart_source.wait()


async def timeout_task(timeout: int):
    await Timer(timeout, "ms")
    raise RuntimeError("Test timeout!")
