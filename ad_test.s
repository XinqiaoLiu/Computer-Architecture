riscv_mp0test.s:
.align 4
.section .text
.globl _start
_start:
    andi x1,x0,0
    andi x3,x0,0
    lw x2, FIVE
loop:
    addi x1, x1, 1
    bne x1, x2, loop
    nop
    nop
    nop
    lw x4, FFFF
loop2:
    addi x3, x3, 1
    bne x3, x4,loop2
    beq x0, x0, halt
    lw x5, BAD
    nop
    nop
halt:
    lw x5, GOOD

ONE:  .word 0x00000001
FIVE: .word 0x00000005
FFFF: .word 0x0000000f
BAD:  .word 0xBADDBADD
GOOD:   .word 0x600D600D
