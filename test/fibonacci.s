.p2align 2
.section .text
.globl   _start

.equ UART_BASE, 0xFFFF0000
.equ UART_GEN_CFG_REG, 0x00
.equ UART_TX_DMA_BUF_START_REG, 0x04
.equ UART_TX_DMA_BUF_END_REG, 0x08
.equ UART_RX_DMA_BUF_START_REG, 0x0C
.equ UART_RX_DMA_BUF_END_REG, 0x10
.equ UART_RX_DMA_BUF_PTR_REG, 0x14

.equ UART_TX_EN_BIT, 0x01
.equ UART_TX_DONE_BIT, 0x03
.equ UART_RX_EN_BIT, 2
.equ UART_RX_DMA_BUF_FULL_BIT, 4
.equ UART_RX_PTR_RST_BIT, 5

_start:
	addi a0, zero, 1
	addi a1, zero, 0
	addi a3, zero, 0xE0
	addi t0, zero, 10
	addi t1, zero, 1

loop_top:
	sw   a0, (a3)
	addi a2, a0, 0
	add  a0, a0, a1
	addi a1, a2, 0
	sub  t0, t0, t1
	bnez t0, loop_top

	li  t0, UART_BASE & 0xFFF
	lui t0, UART_BASE >> 12

write_uart:
	addi a3, zero, 0xE0

	sw   a3, UART_TX_DMA_BUF_START_REG(t0) # Write fibonacci number address
	addi a3, a3, 1
	sw   a3, UART_TX_DMA_BUF_END_REG(t0)  # Write fibonacci number address + 1
	sw   a3, UART_RX_DMA_BUF_START_REG(t0)  # Write fibonacci number address + 1
	addi a3, a3, 1
	sw   a3, UART_RX_DMA_BUF_END_REG(t0)  # Write fibonacci number address + 2

	addi t1, zero, (1 << UART_TX_EN_BIT | 1 << UART_RX_EN_BIT)
	sw   t1, UART_GEN_CFG_REG(t0)      # Enable UART TX and RX

wait_tx_done:
	lw  t1, UART_RX_DMA_BUF_PTR_REG(t0)
	bne t1, a3, wait_tx_done

	xor t1, t1, t1
	li  t1, (1 << UART_RX_PTR_RST_BIT)
	sw  t1, UART_GEN_CFG_REG(t0)      # Clear TX and RX enable, and reset RX pointer

	xor  t1, t1, t1
	lui  t1, 1 # addi sign-extends, so we need to load 1 for the addition to overflow and give us 0x0000_0FFC
	addi t1, t1, -4
	li   t0, 0xFF
	sb   t0, (t1) # Write 0xFF to address 0x3FF of bank 0

halt:
	j halt
