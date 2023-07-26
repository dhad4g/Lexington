.file "main.S"
.section .text
.balign 4
.global inst_test
.global check
.global error
.global success

// Important: all registers should contain their index (i.e. x21 = 21) except:
//  - x1: link register/return address (alias ra)
//  - x2: stack pointer (alias sp)
//  - x10: function argument
//  - x11: second function argument


// Instruction test funcion
inst_test:
    addi    sp, sp, -8
    sw      ra, 4(sp)       // push return address
    csrr    ra, mscratch
    sw      ra, 0(sp)       // push mscratch
    csrw    mscratch, x0
    call    init_regs
    // test NOP
    __test_nop:
    nop
    call    check_all
    // test ADD
    __test_add:
    add     x10, x7, x31    // 7 + 31 = 38
    li      x11, 38
    call    check
    // test SUB
    __test_sub:
    sub     x10, x7, x13    // 7 - 13 = -6
    li      x11, -6
    call    check
    // test SLL
    __test_sll:
    sll     x10, x31, x3    // 0x1F << 3 = 0xF8
    li      x11, 0xF8
    call    check
    // test SLT
    __test_slt:
    slt     x10, x13, x13   // 13 !< 13
    li      x11, 0
    call    check
    li      x10, -2047
    slt     x10, x10, x0    // -2047 < 0
    li      x11, 1
    call    check
    // test SLTU
    __test_sltu:
    li      x10, -2047
    sltu    x10, x10, x23   // 0xFFFF_F801 !< 23
    li      x11, 0
    call    check
    // test XOR
    __test_xor:
    xor     x10, x31, x21   // 0b1_1111 ^ 0b1_0101 = 0b0_1010
    li      x11, 0xA
    call    check
    // test SRL
    __test_srl:
    li      x10, 0xFFFFFF00
    srl     x10, x10, x7    // 0xFFFF_FFFF >> 7 = 0x01FF_FFFE
    li      x11, 0x01FFFFFE
    call    check
    // test SRA
    __test_sra:
    li      x10, 0xFFFFFF00
    sra     x10, x10, x7    // 0xFFFF_FF00 >>> 7 = 0xFFFF_FFFE 
    li      x11, 0xFFFFFFFE
    call    check
    // test OR
    __test_or:
    li      x10, 0xFFAA5500
    li      x11, 0xAA5500F3
    or      x10, x10, x11   // 0xFFAA_5500 | 0xAA55_00F3 = 0xFFFF_55F3
    li      x11, 0xFFFF55F3
    call    check
    // test AND
    __test_and:
    li      x10, 0xFFAA5503
    li      x11, 0xAA5500EB
    and     x10, x10, x11   // 0xFFAA_5500 & 0xAA55_00F3 = 0xAA00_0003
    li      x11, 0xAA000003
    call    check
    // test ADDI
    __test_addi:
    addi    x10, x14, -2048 // 14 - 2048 = -2034
    li      x11, -2034
    call    check
    // test SLLI
    __test_slli:
    slli    x10, x27, 27    // 0x0000_001B << 11 = 0xD800_0000
    li      x11, 0xD8000000
    call    check
    // test SLTI
    __test_slti:
    slti    x10, x7, -12    // 7 !< -12
    li      x11, 0
    call    check
    // test SLTUI
    __test_sltui:
    sltiu   x10, x7, -12    // 7 < 0xFFFF_FFF4
    li      x11, 1
    call    check
    // test XORI
    __test_xori:
    xori    x10, x23, 0xF0  // 0x17 ^ 0xF0 = 0xE7
    li      x11, 0xE7
    call    check
    // test ANDI
    __test_andi:
    andi    x10, x23, 0xF0  // 0x17 & 0xF0 = 0x10
    li      x11, 0x10
    call    check
    // test LUI
    __test_lui:
    lui     x10, 0x5A5FF    // 0x5A5FF << 12 = 0x0A5F_F000
    li      x11, 0x5A5
    slli    x11, x11, 8
    addi    x11, x11, 0xFF
    slli    x11, x11, 12
    call    check
    // test auipc
    __test_auipc:
    auipc   x10, 0
    jalr    x11, x10, 8
    addi    x11, x11, -8
    call    check
    // test BEQ
    __test_beq_taken:
    li      x10, 0
    li      x11, 0
    beq     x10, x11, (__test_beq_taken + 16)
    li      x11, 1
    call    check
    __test_beq_not_taken:
    li      x10, 0
    li      x11, 10
    beq     x10, x11, (__test_beq_not_taken + 16)
    li      x11, 5
    addi    x11, x11, -5
    call    check
    // test BNE
    __test_bne_taken:
    li      x10, 0
    li      x11, 5
    bne     x10, x11, (__test_bne_taken + 16)
    li      x11, 10
    addi    x11, x11, -5
    call    check
    __test_bne_not_taken:
    li      x10, 0
    li      x11, 0
    bne     x10, x11, (__test_bne_not_taken + 16)
    li      x11, -5
    addi    x11, x11, 5
    call    check
    // test BLT
    __test_blt_taken:
    li      x10, -5
    li      x11, 0
    blt     x10, x11, (__test_blt_taken + 16)
    li      x10, -10
    addi    x10, x10, 5
    call    check
    __test_blt_not_taken:
    li      x10, -5
    li      x11, -5
    blt     x10, x11, (__test_blt_not_taken + 16)
    li      x11, 0
    addi    x10, x10, 5
    call    check
    // test BGE
    __test_bge_taken:
    li      x10, 0
    li      x11, 0
    bge     x10, x11, (__test_bge_taken + 16)
    li      x11, 0xFF
    call    check
    __test_bge_not_taken:
    li      x10, -5
    li      x11, 0
    bge     x10, x11, (__test_bge_not_taken + 24) // not taken
    addi    x10, x10, 5
    bge     x10, x11, (__test_bge_not_taken + 24) // taken
    addi    x10, x10, 5
    call    check
    // test BLTU
    __test_bltu_taken:
    li      x10, 0
    li      x11, -5
    bltu    x10, x11, (__test_bltu_taken + 16)
    li      x11, -10
    addi    x11, x11, 5
    call    check
    __test_bltu_not_taken:
    li      x10, -1
    li      x11, 0
    bltu    x10, x11, (__test_bltu_not_taken + 16)
    li      x10, 0
    call    check
    // test BGEU
    __test_bgeu_taken:
    li      x10, -27
    li      x11, 40
    bgeu    x10, x11, (__test_bgeu_taken + 16)
    li      x11, 0
    addi    x11, x11, -67
    call    check
    __test_bgeu_not_taken:
    li      x10, 4
    li      x11, -4
    bgeu    x10, x11, (__test_bgeu_not_taken + 24) // not taken
    li      x11, 4
    bgeu    x10, x11, (__test_bgeu_not_taken + 24) //taken
    addi    x11, x11, 10
    call    check
    // initiale memory test
    __test_mem:
    addi    sp, sp, -4
    // test SW & LW
    __test_sw_lw:
    li      x10, 0xBAADCAFE
    li      x11, 0
    sw      x10, 0(sp)
    lw      x11, 0(sp)
    call    check
    // test SH
    __test_sh:
    li      x10, 0xBAADCAFE
    li      x11, 0xAAAAF00D
    sw      x10, 0(sp)
    sh      x11, 0(sp)
    lw      x10, 0(sp)
    li      x11, 0xBAADF00D
    call    check
    // test LH LHU
    __test_lh_lhu:
    li      x10, 0xBAADCAFE
    sw      x10, 0(sp)
    lh      x11, 0(sp)
    li      x10, 0xFFFFCAFE
    call    check
    lhu     x11, 0(sp)
    li      x10, 0x0000CAFE
    call    check
    // test SB
    __test_sb:
    li      x10, 0xBAADCAFE
    li      x11, 0xAAAAF00D
    sw      x10, 0(sp)
    sb      x11, 0(sp)
    lw      x10, 0(sp)
    li      x11, 0xBAADCA0D
    call    check
    // test LB LBU
    __test_lb_lbu:
    li      x10, 0xBAADCAFE
    sw      x10, 0(sp)
    lb      x11, 0(sp)
    li      x10, 0xFFFFFFFE
    call    check
    lbu     x11, 0(sp)
    li      x10, 0x000000FE
    call    check
    __end_test_mem:
    addi    sp, sp, 4

    // CSR Tests
    // test misa
    __test_misa:
    li      x10, 0xFFFFFFFF
    csrrw   x10, misa, x10
    li      x11, 0x80000000     // expected value
    call    check
    csrr    x10, misa
    call    check
    // test mvendorid
    __test_mvendorid:
    li      x10, 0xFFFFFFFF
    csrrw   x10, mvendorid, x10
    li      x11, 0              // expected value
    call    check
    csrr    x10, mvendorid
    call    check
    // test marchid
    __test_marchid:
    li      x10, 0xFFFFFFFF
    csrrw   x10, marchid, x10
    li      x11, 0              // expected value
    call    check
    csrr    x10, marchid
    call    check
    // test mimpid
    __test_mimpid:
    li      x10, 0xFFFFFFFF
    csrrw   x10, mimpid, x10
    li      x11, 1              // expected value
    call    check
    csrr    x10, mimpid
    call    check
    // test mstatus(h)
    __test_mstatus:
    addi    sp, sp, -8
    csrr    x11, mstatush       // save values
    li      x10, 0x20
    csrc    mstatush, x10       // ensure little-endian data access
    csrr    x10, mstatus
    sw      x10, 4(sp)
    sw      x11, 0(sp)
    __test_mstatus_1s:
    li      x10, 0xFFFFFFFF
    csrw    mstatus, x10
    csrw    mstatush, x10
    csrr    x10, mstatus
    li      x11, 0x18AA         // MPP, MPIE, SPIE, MIE, & SIE bits set
    call    check
    csrr    x10, mstatush
    li      x11, 0x20           // MBE bit set
    call    check
    __test_mstatus_0s:
    csrw    mstatus, 0
    csrw    mstatush, 0
    csrr    x10, mstatus
    li      x11, 0x1822         // MPP, SPIE, & SIE bits set
    call    check
    csrr    x10, mstatush
    li      x11, 0              // no bits set
    call    check
    __end_test_mstatus:
    li      x10, 0x20
    csrc    mstatush, x10       // ensure little-endian data access
    lw      x10, 4(sp)
    lw      x11, 0(sp)
    csrw    mstatus, x10        // restore value
    csrw    mstatush, x11
    addi    sp, sp, 8
    // test mcycle(h)
    __test_mcycle:
    addi    sp, sp, -4
    csrr    x10, mcountinhibit  // save value
    sw      x10, 0(sp)
    csrw    mcountinhibit, 0    // ensure counter is not inhibited
    __test_mcycle_set:
    csrw    mcycle, 0
    csrr    x10, mcycle
    li      x11, 0
    call    check
    __test_mcycle_inc:
    csrr    x10, mcycle
    nop
    nop
    nop
    csrr    x11, mcycle
    addi    x11, x11, -4
    call    check
    __test_mcycle_overflow:
    li      x10, -1
    csrw    mcycleh, 1
    csrw    mcycle, x10
    nop
    nop
    csrr    x10, mcycle
    li      x11, 8
    bgt     x10, x11, +8
    mv      x11, x10
    call    check
    __end_test_mcycle:
    lw      x10, 0(sp)
    csrw    mcountinhibit, x10  // restore value
    addi    sp, sp, 4

    // TRAP, FENCE, ECALL, EBREAK, MRET, and WFI are not explicitely tested

    __test_done:
    // finally test that all registers are correct (except x1, x2, x10, & x11)
    li      x10, 10
    li      x11, 11
    call    check_all
    lw      ra, 0(sp)       // pop mscratch
    csrw    mscratch, ra
    lw      ra, 4(sp)       // pop return address
    addi    sp, sp, 8
    ret




// Check values function
check: // check(int test_value, int correct_value)
    csrw    mscratch, x0
    ebreak
    bne     x10, x11, error
    ret


// Error trap
error:
    li      x10, 0xDEADBEEF
    csrw    mscratch, x10
    ebreak
    ret


// Success trap
success:
    li      x10, 0x0D15EA5E
    csrw    mscratch, x10
    ebreak
    __dead_loop:
    j       __dead_loop


// Initialize registers function
init_regs:
    //li      x0, 0     // hardwired to zero
    //li      x1, 1     // link register
    //li      x2, 2     // stack pointer
    li      x3, 3
    li      x4, 4
    li      x5, 5
    li      x6, 6
    li      x7, 7
    li      x8, 8
    li      x9, 9
    li      x10, 10
    li      x11, 11
    li      x12, 12
    li      x13, 13
    li      x14, 14
    li      x15, 15
    li      x16, 16
    li      x17, 17
    li      x18, 18
    li      x19, 19
    li      x20, 20
    li      x21, 21
    li      x22, 22
    li      x23, 23
    li      x24, 24
    li      x25, 25
    li      x26, 26
    li      x27, 27
    li      x28, 28
    li      x29, 29
    li      x30, 30
    li      x31, 31
    ret


// Check all registers are their initialized values (except x1 and x2)
check_all:
    addi    sp, sp, -4
    sw      ra, 0(sp)   // push return address to stack
    li      x1, 1
    //bne     x1, x1, __check_all_fail      // link register
    addi    x1, x1, 1
    //bne     x2, x1, __check_all_fail      // stack pointer
    addi    x1, x1, 1
    bne     x3, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x4, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x5, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x6, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x7, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x8, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x9, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x10, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x11, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x12, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x13, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x14, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x15, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x16, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x17, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x18, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x19, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x20, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x21, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x22, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x23, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x24, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x25, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x26, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x27, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x28, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x29, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x30, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x31, x1, __check_all_fail
    lw      ra, 0(sp)   // pull return address from stack
    addi    sp, sp, 4
    ret
__check_all_fail:
    j       error
