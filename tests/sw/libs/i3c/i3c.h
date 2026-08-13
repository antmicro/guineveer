// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025-2026 Antmicro <www.antmicro.com>

#ifndef I3C_H
#define I3C_H

#include <stdint.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include "i3c_registers.h"
#include "utils.h"

#ifndef MAX_STREAMING_BOOT_SIZE
#define MAX_STREAMING_BOOT_SIZE 0x1000
#endif

/* All accesses below are explicitly 32-bit MMIO operations. */
#define I3C_BASE (0x30001000)
#define I3C_REGS ((volatile TARGET_I3CCSR_t *)I3C_BASE)
#define I3C_REG_ADDR(PATH) ((uint32_t)(uintptr_t)&I3C_REGS->PATH)
#define I3C_READ(PATH) read32(I3C_REG_ADDR(PATH))
#define I3C_WRITE(PATH, VALUE) write32(I3C_REG_ADDR(PATH), (VALUE))
#define I3C_FIELD(GROUP, REGISTER, FIELD, PROPERTY) \
	TARGET_I3CCSR__I3C_EC__##GROUP##__##REGISTER##__##FIELD##_##PROPERTY
#define I3C_FIELD_GET(VALUE, GROUP, REGISTER, FIELD) \
	(((VALUE) & I3C_FIELD(GROUP, REGISTER, FIELD, bm)) >> \
	 I3C_FIELD(GROUP, REGISTER, FIELD, bp))
#define I3C_FIELD_SET(VALUE, FIELD_VALUE, GROUP, REGISTER, FIELD) do { \
	(VALUE) &= ~TARGET_I3CCSR__I3C_EC__##GROUP##__##REGISTER##__##FIELD##_bm; \
	(VALUE) |= ((uint32_t)(FIELD_VALUE) << \
		TARGET_I3CCSR__I3C_EC__##GROUP##__##REGISTER##__##FIELD##_bp) & \
		TARGET_I3CCSR__I3C_EC__##GROUP##__##REGISTER##__##FIELD##_bm; \
} while (0)

#define I3C_FIELD_WRITE(PATH, FIELD_VALUE, GROUP, REGISTER, FIELD) do { \
	uint32_t i3c_field_value = I3C_READ(PATH); \
	I3C_FIELD_SET(i3c_field_value, FIELD_VALUE, GROUP, REGISTER, FIELD); \
	I3C_WRITE(PATH, i3c_field_value); \
} while (0)
#define I3C_FIELD_EQ(PATH, VALUE, GROUP, REGISTER, FIELD) \
	(I3C_FIELD_GET(I3C_READ(PATH), GROUP, REGISTER, FIELD) == (uint32_t)(VALUE))


#define STATIC_ADDR (0x5A)
#define VIRT_STATIC_ADDR (0x6A)

/* Software-defined values from the Secure Firmware Recovery protocol. */
#define I3C_SECFW_PROT_CAP_VERSION_1p1		0x0101u
#define I3C_SECFW_PROT_CAP_DEVICE_ID		(1u << 16)
#define I3C_SECFW_PROT_CAP_FORCED_RECOVERY	(1u << 17)
#define I3C_SECFW_PROT_CAP_MGMT_RESET		(1u << 18)
#define I3C_SECFW_PROT_CAP_DEVICE_STATUS	(1u << 20)
#define I3C_SECFW_PROT_CAP_INDIRECT_CTRL	(1u << 21)
#define I3C_SECFW_PROT_CAP_PUSH_CIMAGE_SUPPORT	(1u << 23)
#define I3C_SECFW_PROT_CAP_FLASHLESS_BOOT	(1u << 27)

#define I3C_SECFW_DEV_STATUS_DEVICE_HEALTHY	0x01u
#define I3C_SECFW_DEV_STATUS_RECOVERY_READY	0x03u
#define I3C_SECFW_DEV_STATUS_ERROR		0x0Fu
#define I3C_SECFW_REC_REASON_STREAMING_BOOT	0x0012u
#define I3C_SECFW_DEVICE_RESET_FORCED_STREAMING_BOOT	0x0Eu
#define I3C_SECFW_MGMT_RESET			0x02u
#define I3C_SECFW_RECOVERY_CONTROL_ACTIVATE	0x0Fu
#define I3C_SECFW_RECOVERY_STATUS_AWAITING	0x01u
#define I3C_SECFW_RECOVERY_STATUS_PROCESSING	0x02u
#define I3C_SECFW_RECOVERY_STATUS_SUCCESSFUL	0x03u
#define I3C_SECFW_RECOVERY_STATUS_FAILED	0x0Cu

void i3c_wait_for_payload_available();

void start_streaming_boot_reciver();

void i3c_init();

void i3c_clear_dynamic_addr();

int i3c_has_dynamic_addr();

uint8_t i3c_dynamic_addr();

void i3c_wait_for_rx();

void i3c_wait_for_tx();

uint32_t i3c_pop_rx_desc();

void i3c_push_tx_desc(uint32_t);

void i3c_read_rx_data(void*, size_t);

void i3c_write_tx_data(const void*, size_t);

#endif
