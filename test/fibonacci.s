.p2align 2
.section .text
.globl   _start

.equ UART_BASE, 0xFFFF0000
.equ UART_GEN_CFG_REG, 0x00
.equ UART_TX_SRC_START_REG, 0x04
.equ UART_TX_SRC_STOP_REG, 0x08
.equ UART_TX_EN_BIT, 0x01
.equ UART_TX_DONE_BIT, 0x03

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

	addi t0, zero, UART_BASE & 0xFFF
	lui  t0, UART_BASE >> 12
	sw   a3, UART_TX_SRC_START_REG(t0) # Write fibonacci number address
	addi a3, a3, 1
	sw   a3, UART_TX_SRC_STOP_REG(t0)  # Write fibonacci number address + 1
	addi t1, zero, 1 << UART_TX_EN_BIT
	sw   t1, UART_GEN_CFG_REG(t0)      # Enable UART TX

wait_tx_done:
	lw   t1, UART_GEN_CFG_REG(t0)
	andi t1, t1, 1 << UART_TX_DONE_BIT
	beqz t1, wait_tx_done

	addi t1, zero, 0
	sw   t1, UART_GEN_CFG_REG(t0)      # Clear TX enable

halt:
	j halt
