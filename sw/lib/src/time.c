#include "time.h"


inline void __attribute__((always_inline)) set_mtime(uint64_t val) {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } cycles;
    cycles.u64 = val;

    MACHINE_TIMER->mtime  = 0;
    MACHINE_TIMER->mtimeh = cycles.u32[1];
    MACHINE_TIMER->mtime  = cycles.u32[0];
}

inline void __attribute__((always_inline)) set_mtimecmp(uint64_t val) {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } cycles;
    cycles.u64 = val;
    
    MACHINE_TIMER->mtimecmp  = 0;
    MACHINE_TIMER->mtimecmph = cycles.u32[1];
    MACHINE_TIMER->mtimecmp  = cycles.u32[0];
}

inline uint64_t __attribute__((always_inline)) get_time() {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } cycles;

    uint32_t tmp;
    do {
        cycles.u32[1] = csrr(CSR_TIMEH);
        cycles.u32[0] = csrr(CSR_TIME);
        tmp           = csrr(CSR_TIMEH);
    } while (cycles.u32[1] != tmp);
    return cycles.u64;
}

inline uint64_t __attribute__((always_inline)) get_mtimecmp() {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } cycles;

    cycles.u32[1] = MACHINE_TIMER->mtimecmph;
    cycles.u32[0] = MACHINE_TIMER->mtimecmp;
    return cycles.u64;
}


uint32_t milliseconds() {
    uint32_t millis = csrr(CSR_TIME);
    return millis / 1000;
}

inline uint32_t __attribute__((always_inline)) microseconds() {
    return csrr(CSR_TIME);
}

void delay(uint32_t val) {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } cycles;
    cycles.u32[0] = val;
    cycles.u32[1] = 0;

    cycles.u64 *= 1000;
    cycles.u64 += get_time();
    while (cycles.u32[1] < csrr(CSR_TIMEH));
    while (cycles.u32[0] <= csrr(CSR_TIME));
}

void delay_micro(uint32_t val) {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } cycles;
    cycles.u32[0] = val;
    cycles.u32[1] = 0;

    cycles.u64 += get_time();
    while (cycles.u32[1] < csrr(CSR_TIMEH));
    while (cycles.u32[0] <= csrr(CSR_TIME));
}
