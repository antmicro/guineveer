# Copyright (c) 2025 Antmicro <www.antmicro.com>
# SPDX-License-Identifier: Apache-2.0

import cocotb
import struct

from cocotb.triggers import Timer
from cocotb.handle import HierarchyObject
from cocotbext_i3c.i3c_recovery_interface import I3cRecoveryInterface
from util import begin_test, read_line, setup, timeout_task

STATIC_ADDR = 0x5A
DYNAMIC_ADDR = 0x52
VIRT_STATIC_ADDR = 0x6A
VIRT_DYNAMIC_ADDR = 0x62

RECOVERY_IMAGE = [
    # _start:
    #   lui a5, 0x30000
    0xb7, 0x07, 0x00, 0x30,
    # 1:auipc a4, %pcrel_hi(_str)
    0x17, 0x07, 0x00, 0x00,
    #   addi a4, a4, %pcrel_lo(1b)
    0x13, 0x07, 0x87, 0x03,
    # _print:
    #   lb a0, 0(a4)
    0x03, 0x05, 0x07, 0x00,
    #   beqz a0, _halt
    0x63, 0x02, 0x05, 0x02,
    #   addi a4, a4, 1
    0x13, 0x07, 0x17, 0x00,
    #   jal _putchar
    0xef, 0x00, 0x80, 0x00,
    #   j _print
    0x6f, 0xf0, 0x1f, 0xff,
    # _putchar:
    #   lw a1, 20(a5)
    0x83, 0xa5, 0x47, 0x01,
    #   andi a1, a1, 8
    0x93, 0xf5, 0x85, 0x00,
    #   beqz a1, _putchar
    0xe3, 0x8c, 0x05, 0xfe,
    #   sw a0, 28(a5)
    0x23, 0xae, 0xa7, 0x00,
    #   ret
    0x67, 0x80, 0x00, 0x00,
    # _halt:
    #   wfi
    0x73, 0x00, 0x50, 0x10,
    #   j _halt
    0x6f, 0xf0, 0xdf, 0xff,
    # _str:
    #   .asciz "Hello from I3C streaming boot image.\r\n"
    *[ord(x) for x in "Hello from I3C streaming boot image.\r\n"], 0x00, 0x00
]

FIFO_EMPTY_FLAG = 1 << 0
FIFO_FULL_FLAG = 1 << 0

RECOVERY_STATUS_AWAITING = 0x01
RECOVERY_STATUS_SUCCESS = 0x03
RECOVERY_STATUS_FAILURE = 0x0c

DEVICE_STATUS_READY_TO_ACCEPT = 0x03

RECOVERY_REASON_STREAMING_BOOT = 0x12

MGMT_RESET_ENTER_STREAMING_BOOT = [0x02, 0x0E, 0x00]

RECOVERY_CTRL_BOOT_IMAGE = [0x00, 0x01, 0x0F]

PROT_CAP_DEVICE_ID = 1 << 0
PROT_CAP_FORCED_RECOVERY = 1 << 1
PROT_CAP_MGMT_RESET = 1 << 2
PROT_CAP_DEVICE_STATUS = 1 << 4
PROT_CAP_RECOVERY_MEMORY_ACCESS = 1 << 5
PROT_CAP_PUSH_C_IMAGE = 1 << 7
PROT_CAP_FLASHLESS_BOOT = 1 << 11


async def fifo_wait_for_space(recovery: I3cRecoveryInterface) -> int:
    while True:
        resp, ok = await recovery.command_read(
            VIRT_DYNAMIC_ADDR, I3cRecoveryInterface.Command.INDIRECT_FIFO_STATUS
        )
        assert ok
        status, wptr, rptr, fifo_size, max_xfer = struct.unpack("<5I", bytes(resp))

        if (status & FIFO_EMPTY_FLAG) > 0:
            return fifo_size * 4

        if (status & FIFO_FULL_FLAG) == 0:
            if wptr > rptr:
                return (fifo_size - (wptr - rptr)) * 4
            else:
                return (rptr - wptr) * 4

        await Timer(100, units="us")


@cocotb.test
async def test_i3c_streaming_boot(dut: HierarchyObject):
    """
    Test whether I3C streaming boot works.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)
    recovery = I3cRecoveryInterface(i3c_ctrl)

    await begin_test(uart_sink, uart_source, "B")

    cocotb.start_soon(timeout_task(5))

    CCC_DIRECT_SETDASA = 0x87

    res = await i3c_ctrl.i3c_ccc_write(
        ccc=CCC_DIRECT_SETDASA, directed_data=[(STATIC_ADDR, [DYNAMIC_ADDR << 1])]
    )
    assert res[0]

    res = await i3c_ctrl.i3c_ccc_write(
        ccc=CCC_DIRECT_SETDASA, directed_data=[(VIRT_STATIC_ADDR, [VIRT_DYNAMIC_ADDR << 1])]
    )
    assert res[0]

    resp, ok = await recovery.command_read(VIRT_DYNAMIC_ADDR, I3cRecoveryInterface.Command.PROT_CAP)
    assert ok
    magic, major, minor, cap, *_ = struct.unpack("<8sBBHBBB", bytes(resp))
    assert magic == b"OCP RECV"
    assert major == 1
    assert minor == 1
    assert (cap & PROT_CAP_DEVICE_ID) > 0
    assert (cap & PROT_CAP_FORCED_RECOVERY) > 0
    assert (cap & PROT_CAP_MGMT_RESET) > 0
    assert (cap & PROT_CAP_DEVICE_STATUS) > 0
    assert (cap & PROT_CAP_RECOVERY_MEMORY_ACCESS) > 0
    assert (cap & PROT_CAP_PUSH_C_IMAGE) > 0
    assert (cap & PROT_CAP_FLASHLESS_BOOT) > 0

    # Reset management interface and force flashless boot mode.
    await recovery.command_write(
        VIRT_DYNAMIC_ADDR,
        I3cRecoveryInterface.Command.DEVICE_RESET,
        data=MGMT_RESET_ENTER_STREAMING_BOOT,
    )

    # Wait for device to enter recovery mode.
    while True:
        resp, ok = await recovery.command_read(
            VIRT_DYNAMIC_ADDR, I3cRecoveryInterface.Command.DEVICE_STATUS
        )
        assert ok
        dev_status, _, rec_reason, *_ = struct.unpack("<BBHHB", bytes(resp))

        if dev_status == DEVICE_STATUS_READY_TO_ACCEPT:
            assert rec_reason == RECOVERY_REASON_STREAMING_BOOT
            break

        await Timer(10, units="us")

    resp, ok = await recovery.command_read(
        VIRT_DYNAMIC_ADDR, I3cRecoveryInterface.Command.RECOVERY_STATUS
    )
    assert ok
    assert resp[0] == RECOVERY_STATUS_AWAITING

    # Configure indirect FIFO for transfer.
    await recovery.command_write(
        VIRT_DYNAMIC_ADDR,
        I3cRecoveryInterface.Command.INDIRECT_FIFO_CTRL,
        data=struct.pack("<BBI", 0, 0, (len(RECOVERY_IMAGE) + 3) // 4),
    )

    # Make sure the image is not too large.
    resp, ok = await recovery.command_read(
        VIRT_DYNAMIC_ADDR, I3cRecoveryInterface.Command.RECOVERY_STATUS
    )
    assert ok
    assert resp[0] == RECOVERY_STATUS_AWAITING

    # Query max transfer size.
    resp, ok = await recovery.command_read(
        VIRT_DYNAMIC_ADDR, I3cRecoveryInterface.Command.INDIRECT_FIFO_STATUS
    )
    assert ok
    _, _, _, _, xfer_size = struct.unpack("<5I", bytes(resp))
    xfer_size *= 4  # Transfer size is in 4B word units

    # Write recovery image.
    progress = 0
    while progress < len(RECOVERY_IMAGE):
        # Wait for space in FIFO.
        fifo_free = await fifo_wait_for_space(recovery)

        chunk_size = min(len(RECOVERY_IMAGE) - progress, xfer_size, fifo_free)
        chunk = RECOVERY_IMAGE[progress : progress + chunk_size]

        await recovery.command_write(
            VIRT_DYNAMIC_ADDR, I3cRecoveryInterface.Command.INDIRECT_FIFO_DATA, data=chunk
        )

        progress += chunk_size

    # Boot the written image.
    await recovery.command_write(
        VIRT_DYNAMIC_ADDR, I3cRecoveryInterface.Command.RECOVERY_CTRL, data=RECOVERY_CTRL_BOOT_IMAGE
    )

    # Wait for the image to be booted.
    while True:
        resp, ok = await recovery.command_read(
            VIRT_DYNAMIC_ADDR, I3cRecoveryInterface.Command.RECOVERY_STATUS
        )
        assert ok

        if resp[0] == RECOVERY_STATUS_SUCCESS or resp[0] == RECOVERY_STATUS_FAILURE:
            assert resp[0] != RECOVERY_STATUS_FAILURE
            break

        await Timer(100, units="us")

    # Wait for a message from the booted image.
    line = await read_line(uart_sink)
    assert line == "Hello from I3C streaming boot image."


@cocotb.test
async def test_axi_streaming_boot(dut: HierarchyObject):
    """
    Test whether AXI streaming boot works.
    """

    i3c_ctrl, uart_sink, uart_source = await setup(dut)

    await begin_test(uart_sink, uart_source, "A")

    cocotb.start_soon(timeout_task(5))

    # AXI streaming boot is mostly driven by the firmware, so we don't have much to do here.

    # Wait for a message from the booted image.
    line = await read_line(uart_sink)
    assert line == "Hello from AXI streaming boot image."
