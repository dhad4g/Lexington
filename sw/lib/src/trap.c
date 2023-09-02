#include "trap.h"

// Global interrupt enable
inline void __attribute__((always_inline)) enable_global_interrupts() {
    asm volatile inline ("csrs mstatus, 0x4");
};

inline void __attribute__((always_inline)) disable_global_interrupts() {
    asm volatile inline ("csrc mstatus, 0x4");
};

inline uint32_t __attribute__((always_inline)) get_global_interrupt_enable() {
    return 0b1 & (csrr(CSR_MSTATUS) >> 3);
};



// Trap-Vector
inline uint32_t __attribute__((always_inline)) get_mtvec_mode() {
    return MTVEC_MODE_MASK & (csrr(CSR_MSTATUS) >> 3);
};

inline uint32_t __attribute__((always_inline)) get_mtvec_base() {
    return MTVEC_BASE_MASK & csrr(CSR_MTVEC);
};

inline void __attribute__((always_inline)) set_mtvec_direct() {
    asm volatile inline("csrc mtvec, 0x3");
};

inline void __attribute__((always_inline)) set_mtvec_vectored() {
    asm volatile inline(
        "csrc mtvec, 0x2\n"
        "csrs mtvec, 0x1"
    );
};

inline void __attribute__((always_inline)) set_mtvec_base_direct(uint32_t base) {
    uint32_t data = MTVEC_BASE_MASK & base;
    csrw(CSR_MTVEC, data);
};

inline void __attribute__((always_inline)) set_mtvec_base_vectored(uint32_t base) {
    uint32_t data = (base & MTVEC_BASE_MASK) | 0b01;
    csrw(CSR_MTVEC, data);
};



// Interrupt Enable
inline void __attribute__((always_inline)) enable_interrupt(uint32_t source) {
    uint32_t mask = 0b1 << source;
    csrs(CSR_MIE, mask);
};

inline void __attribute__((always_inline)) disable_interrupt(uint32_t source) {
    uint32_t mask = 0b1 << source;
    csrc(CSR_MIE, mask);
};



// Interrupt Pending
inline uint32_t __attribute__((always_inline)) get_interrupt_pending(uint32_t source) {
    return 0b1 & (csrr(CSR_MIP) >> source);
};

inline void __attribute__((always_inline)) set_interrupt_pending(uint32_t source) {
    uint32_t mask = 0b1 << source;
    csrs(CSR_MIP, mask);
};

inline void __attribute__((always_inline)) clear_interrupt_pending(uint32_t source) {
    uint32_t mask = 0b1 << source;
    csrc(CSR_MIP, mask);
};



// Trap Cause
inline uint32_t __attribute__((always_inline)) is_mcause_interrupt() {
    return csrr(CSR_MCAUSE) >> 31;
};
