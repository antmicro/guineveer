# Copyright (c) 2025 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

from enum import IntEnum

import cocotb
from cocotb.clock import Clock
from cocotb.handle import HierarchyObject
from cocotb.triggers import ClockCycles, Edge
from cocotbext.ahb import AHBBus, AHBMaster, AHBResp
from cocotbext.uart import UartSink, UartSource


class ADDRS(IntEnum):
    INTR_STATE = 0x0
    INTR_ENABLE = 0x4
    INTR_TEST = 0x8
    ALERT_TEST = 0xC
    CTRL = 0x10
    STATUS = 0x14
    RDATA = 0x18
    WDATA = 0x1C
    FIFO_CTRL = 0x20
    FIFO_STATUS = 0x24
    OVRD = 0x28
    VAL = 0x2C
    TIMEOUT_CTRL = 0x30


REG_INTR_ENABLE_TX_WATERMARK_MASK = 1 << 0
REG_INTR_ENABLE_RX_WATERMARK_MASK = 1 << 1
REG_CTRL_NCO_OFFSET = 16
REG_CTRL_NCO_MASK = 0xFFFF << REG_CTRL_NCO_OFFSET
REG_CTRL_TX_MASK = 1 << 0
REG_CTRL_RX_MASK = 1 << 1
REG_STATUS_TXIDLE_MASK = 1 << 3
REG_STATUS_RXEMPTY_MASK = 1 << 5
REG_FIFO_CTRL_RXRST_MASK = 1 << 0
REG_FIFO_CTRL_TXRST_MASK = 1 << 1
REG_FIFO_STATUS_TXLVL_MASK = 0b111111

BAUD_RATE = 921600


async def reset(dut: HierarchyObject):
    dut.uart_rx.value = 0

    dut.sub_haddr.value = 0
    dut.sub_hwdata.value = 0
    dut.sub_hsel.value = 0
    dut.sub_hwrite.value = 0
    dut.sub_hready.value = 0
    dut.sub_htrans.value = 0
    dut.sub_hsize.value = 0

    dut.rst.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 1
    await ClockCycles(dut.clk, 2)


async def ahb_loopback(dut: HierarchyObject):
    dut.sub_hready.value = dut.sub_hreadyout.value
    while True:
        await Edge(dut.sub_hreadyout)
        dut.sub_hready.value = dut.sub_hreadyout.value


async def wait_for_tx(ahb: AHBMaster):
    [resp] = await ahb.read(ADDRS.STATUS)
    assert resp["resp"] == AHBResp.OKAY
    if int(resp["data"], 16) & REG_STATUS_TXIDLE_MASK == 0:
        await ClockCycles(ahb.clk, 1000)
        await wait_for_tx(ahb)


async def drain_recv_buf(ahb: AHBMaster) -> bytes:
    out = list[int]()

    while True:
        [resp] = await ahb.read(ADDRS.STATUS)
        assert resp["resp"] == AHBResp.OKAY

        if int(resp["data"], 16) & REG_STATUS_RXEMPTY_MASK != 0:
            return bytes(out)

        [resp] = await ahb.read(ADDRS.RDATA, size=1)
        assert resp["resp"] == AHBResp.OKAY
        out.append(int(resp["data"], 16))


async def clear_interrupts(ahb: AHBMaster):
    [resp] = await ahb.read(ADDRS.INTR_ENABLE)
    assert resp["resp"] == AHBResp.OKAY
    enabled_intrs = int(resp["data"], 16)

    [resp] = await ahb.write(ADDRS.INTR_ENABLE, 0)
    assert resp["resp"] == AHBResp.OKAY

    [resp] = await ahb.write(ADDRS.INTR_STATE, 0)
    assert resp["resp"] == AHBResp.OKAY

    [resp] = await ahb.write(ADDRS.INTR_ENABLE, enabled_intrs)
    assert resp["resp"] == AHBResp.OKAY


async def setup(dut: HierarchyObject) -> tuple[Clock, AHBMaster]:
    clock = Clock(dut.clk, 10, units="ns")  # 100 Mhz

    cocotb.start_soon(ahb_loopback(dut))
    cocotb.start_soon(clock.start())
    await reset(dut)

    ahb = AHBMaster(AHBBus.from_prefix(dut, "sub"), dut.clk, dut.rst)

    # set correct NCO and enable RX & TX
    nco = BAUD_RATE << 20
    nco //= clock.frequency * 1_000_000
    ctrl = (int(nco) << REG_CTRL_NCO_OFFSET) & REG_CTRL_NCO_MASK
    ctrl |= REG_CTRL_TX_MASK | REG_CTRL_RX_MASK
    resp = await ahb.write(ADDRS.CTRL, ctrl)
    assert resp[0]["resp"] == AHBResp.OKAY

    # enable RX interrupt on every word
    intr = REG_INTR_ENABLE_RX_WATERMARK_MASK
    resp = await ahb.write(ADDRS.INTR_ENABLE, intr)
    assert resp[0]["resp"] == AHBResp.OKAY

    return clock, ahb


@cocotb.test
async def reg_to_uart(dut: HierarchyObject):
    """
    Checks if data written to the WDATA register
    gets transmitted correctly on the UART TX line
    """

    _, ahb = await setup(dut)
    sink = UartSink(dut.uart_tx, baud=BAUD_RATE)
    data = bytes([0x00, 0xFF, 0x4F, 0x12, 0x6A])

    for byte in data:
        resp = await ahb.write(ADDRS.WDATA, byte, size=1)
        assert resp[0]["resp"] == AHBResp.OKAY
        await wait_for_tx(ahb)

    received = sink.read_nowait()
    assert received == data


@cocotb.test
async def uart_to_reg(dut: HierarchyObject):
    """
    Checks if data received on the UART RX line
    is correctly readable from the RDATA register
    """

    _, ahb = await setup(dut)
    data = bytes([0x00, 0xFF, 0x3D, 0x2F, 0x19])
    source = UartSource(dut.uart_rx, baud=BAUD_RATE)

    await source.write(data)
    await source.wait()

    received = await drain_recv_buf(ahb)
    assert received == data


@cocotb.test
async def rx_intr(dut: HierarchyObject):
    """
    Checks if the RX_WATERMARK interrupt line is
    correctly asserted when data is received on UART RX
    """

    _, ahb = await setup(dut)
    data = bytes([0x00, 0xFF, 0x3D, 0x2F, 0x19])
    source = UartSource(dut.uart_rx, baud=BAUD_RATE)

    assert not dut.intr_rx_watermark_o.value

    await source.write(data)
    await source.wait()

    for byte in data:
        assert dut.intr_rx_watermark_o.value
        out = await ahb.read(ADDRS.RDATA, size=1)
        assert out[0]["resp"] == AHBResp.OKAY
        assert int(out[0]["data"], 16) == byte
        await clear_interrupts(ahb)
        assert not dut.intr_rx_watermark_o.value
        await ClockCycles(dut.clk, 2)
