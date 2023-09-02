#ifndef __TRAP_H
#define __TRAP_H

#include <stdint.h>

#include "csr.h"


// Standard Interrupt Causes
#define TRAP_CODE_NMI                   0
#define TRAP_CODE_SSI                   1
#define TRAP_CODE_MSI                   3
#define TRAP_CODE_STI                   5
#define TRAP_CODE_MTI                   7
#define TRAP_CODE_SEI                   9
#define TRAP_CODE_MEI                   11

// Platform Interrupt Causes
#define TRAP_CODE_UART0RX               16
#define TRAP_CODE_UART0TX               17
#define TRAP_CODE_TIM0                  18
#define TRAP_CODE_TIM1                  19
#define TRAP_CODE_GPIOA0                20
#define TRAP_CODE_GPIOA1                21
#define TRAP_CODE_GPIOB0                22
#define TRAP_CODE_GPIOB1                23
#define TRAP_CODE_GPIOC0                24
#define TRAP_CODE_GPIOC1                25

// Exception Trap Codes
#define TRAP_CODE_INST_MISALIGNED       0
#define TRAP_CODE_INST_ACCESS_FAULT     1
#define TRAP_CODE_ILLEGAL_INST          2
#define TRAP_CODE_BREAKPOINT            3
#define TRAP_CODE_LOAD_MISALIGNED       4
#define TRAP_CODE_LOAD_ACCESS_FAULT     5
#define TRAP_CODE_STORE_MISALIGNED      6
#define TRAP_CODE_STORE_ACCESS_FAULT    7
#define TRAP_CODE_ECALL_UMODE           8
#define TRAP_CODE_ECALL_SMODE           9
#define TRAP_CODE_ECALL_MMODE           10
#define TRAP_CODE_INST_PAGE_FAULT       11
#define TRAP_CODE_LOAD_PAGE_FAULT       12
#define TRAP_CODE_STORE_PAGE_FAULT      13

// mtvec Modes
#define MTVEC_MODE_DIRECT               0
#define MTVEC_MODE_VECTORED             1
#define MTVEC_MODE_MASK                 (0b11)
#define MTVEC_BASE_MASK                 ((uint32_t)0xFFFFFFFC)


// Global interrupt enable
void enable_global_interrupts();
void disable_global_interrupts();
uint32_t get_global_interrupt_enable();

// Trap-Vector
uint32_t get_mtvec_mode();
uint32_t get_mtvec_base();
void set_mtvec_direct();
void set_mtvec_vectored();
void set_mtvec_base_direct(uint32_t base);
void set_mtvec_base_vectored(uint32_t base);

// Interrupt Enable
void enable_interrupt(uint32_t source);
void disable_interrupt(uint32_t source);

// Interrupt Pending
uint32_t get_interrupt_pending(uint32_t source);
void set_interrupt_pending(uint32_t source);
void clear_interrupt_pending(uint32_t source);

// Trap Cause
uint32_t is_mcause_interrupt();


#endif // __TRAP_H
