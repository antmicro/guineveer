# Copyright (c) 2025 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

from enum import IntEnum

import cocotb
from cocotb.clock import Clock
from cocotb.handle import HierarchyObject
from cocotb.triggers import ClockCycles, Edge
from cocotbext.uart import UartSink, UartSource
from cocotbext_i3c.i3c_controller import I3cController


EMPTY_ADDR = 0x00
STATIC_ADDR = 0x5A
DYNAMIC_ADDR = 0x52


async def read_line(uart_sink: UartSink) -> str:
    buf = list[int]()

    while not buf or buf[-1] != ord('\n'):
        buf += await uart_sink.read(count=1)

    return bytes(buf).decode('utf-8').rstrip("\r\n")


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


@cocotb.test
async def test_unknown(dut: HierarchyObject):
    """
    Test whether unknown tests respond with a question mark.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)

    await begin_test(uart_sink, uart_source, "?")

    line = await read_line(uart_sink)
    assert line == "?"


@cocotb.test
async def test_ccc_setdasa(dut: HierarchyObject):
    """
    Test whether the CCC SETDASA command causes the appropriate register changes
    observable from the CPU.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)

    await begin_test(uart_sink, uart_source, "1")

    CCC_DIRECT_SETDASA = 0x87

    line = await read_line(uart_sink)
    assert line == f"{EMPTY_ADDR:02x}"

    await i3c_ctrl.i3c_ccc_write(
        ccc=CCC_DIRECT_SETDASA, directed_data=[(STATIC_ADDR, [DYNAMIC_ADDR << 1])]
    )

    line = await read_line(uart_sink)
    assert line == f"{DYNAMIC_ADDR:02x}"


@cocotb.test
async def test_read_write(dut: HierarchyObject):
    """
    Test whether the CPU can process read and write transactions.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)

    await begin_test(uart_sink, uart_source, "2")

    test_data = [0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0, 0xaa, 0xbb, 0xcc]
    await i3c_ctrl.i3c_write(STATIC_ADDR, test_data)

    line = await read_line(uart_sink)
    assert line == str(len(test_data))

    line = await read_line(uart_sink)
    assert line == "".join(f"{v:02x} " for v in test_data)

    recv_data = await i3c_ctrl.i3c_read(STATIC_ADDR, 11)
    assert not recv_data.nack
    assert recv_data.data == bytes(test_data)
