.p2align 2
.section .text
.globl   _start

_start:
	addi a0, zero, 1
	addi a1, zero, 0
	addi a3, zero, 0xE0

loop_top:
	sw   a0, (a3)
	addi a2, a0, 0
	add  a0, a0, a1
	addi a1, a2, 0
	j    loop_top
