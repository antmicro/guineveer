# Copyright (c) 2025-2026 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.handle import HierarchyObject
from cocotb.triggers import ClockCycles
from util import begin_test, read_line, setup

EMPTY_ADDR = 0x00
STATIC_ADDR = 0x5A
DYNAMIC_ADDR = 0x52


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


@cocotb.test
async def test_ccc_getpid(dut: HierarchyObject):
    """
    Test whether the CCC GETPID command yields the expected value.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)

    await begin_test(uart_sink, uart_source, "p")

    CCC_DIRECT_GETPID = 0x8D
    DEFAULT_PID = bytes([0xff, 0xfe, 0x00, 0x5a, 0x00, 0xa5])
    NEW_PID = bytes([0xab, 0xcc, 0xef, 0x01, 0x23, 0x45])

    resp = (await i3c_ctrl.i3c_ccc_read(
        ccc=CCC_DIRECT_GETPID, addr=STATIC_ADDR, count=6
    ))[0]
    assert resp[0]
    assert resp[1] == DEFAULT_PID

    await uart_source.write([1])
    await uart_source.wait()

    line = await read_line(uart_sink)
    assert line == "ok"

    resp = (await i3c_ctrl.i3c_ccc_read(
        ccc=CCC_DIRECT_GETPID, addr=STATIC_ADDR, count=6
    ))[0]
    assert resp[0]
    assert resp[1] == NEW_PID


@cocotb.test
async def test_ccc_getbcr(dut: HierarchyObject):
    """
    Test whether the CCC GETBCR command yields the expected value.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)

    await begin_test(uart_sink, uart_source, "b")

    CCC_DIRECT_GETBCR = 0x8E

    DEFAULT_BCR = bytes([0b00100110])
    INVERSE_BCR = bytes([0b11011001])

    resp = (await i3c_ctrl.i3c_ccc_read(
        ccc=CCC_DIRECT_GETBCR, addr=STATIC_ADDR, count=1
    ))[0]
    assert resp[0]
    assert resp[1] == DEFAULT_BCR

    await uart_source.write([1])
    await uart_source.wait()

    line = await read_line(uart_sink)
    assert line == "ok"

    resp = (await i3c_ctrl.i3c_ccc_read(
        ccc=CCC_DIRECT_GETBCR, addr=STATIC_ADDR, count=1
    ))[0]
    assert resp[0]
    assert resp[1] == INVERSE_BCR


@cocotb.test
async def test_ccc_getdcr(dut: HierarchyObject):
    """
    Test whether the CCC GETDCR command yields the expected value.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)

    await begin_test(uart_sink, uart_source, "d")

    CCC_DIRECT_GETDCR = 0x8F

    DEFAULT_DCR = bytes([0b10111101])
    INVERSE_DCR = bytes([0b01000010])

    resp = (await i3c_ctrl.i3c_ccc_read(
        ccc=CCC_DIRECT_GETDCR, addr=STATIC_ADDR, count=1
    ))[0]
    assert resp[0]
    assert resp[1] == DEFAULT_DCR

    await uart_source.write([1])
    await uart_source.wait()

    line = await read_line(uart_sink)
    assert line == "ok"

    resp = (await i3c_ctrl.i3c_ccc_read(
        ccc=CCC_DIRECT_GETDCR, addr=STATIC_ADDR, count=1
    ))[0]
    assert resp[0]
    assert resp[1] == INVERSE_DCR


@cocotb.test
async def test_ccc_getstatus(dut: HierarchyObject):
    """
    Test whether the CCC GETSTATUS command yields the expected value.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)

    await begin_test(uart_sink, uart_source, "?")

    CCC_DIRECT_GETSTATUS = 0x90

    DEFAULT_STATUS = bytes([0x00, 0x60])
    PROTO_ERROR_STATUS = bytes([0x00, 0x70])

    resp = (await i3c_ctrl.i3c_ccc_read(
        ccc=CCC_DIRECT_GETSTATUS, addr=STATIC_ADDR, count=2
    ))[0]
    assert resp[0]
    assert resp[1] == DEFAULT_STATUS

    # Inject protocol error and check if the appropriate bit is set and cleared after read.

    await i3c_ctrl.i3c_write(STATIC_ADDR, [0xab, 0xcd, 0xef], inject_tbit_err=True)
    await ClockCycles(dut.core_clk_o, 10)

    resp = (await i3c_ctrl.i3c_ccc_read(
        ccc=CCC_DIRECT_GETSTATUS, addr=STATIC_ADDR, count=2
    ))[0]
    assert resp[0]
    assert resp[1] == PROTO_ERROR_STATUS

    # Reading the status should automatically clear the protocol error flag.

    resp = (await i3c_ctrl.i3c_ccc_read(
        ccc=CCC_DIRECT_GETSTATUS, addr=STATIC_ADDR, count=2
    ))[0]
    assert resp[0]
    assert resp[1] == DEFAULT_STATUS
