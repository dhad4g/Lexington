#ifndef __TIME_H
#define __TIME_H

#include <stdint.h>

#include "csr.h"
#include "trap.h"


#define MTIME_BASE              ((uint32_t)0xC0000000)

typedef volatile struct __attribute__((packed,aligned(4))) {
    uint32_t mtime;
    uint32_t mtimeh;
    uint32_t mtimecmp;
    uint32_t mtimecmph;
} mtime_t;

#define MACHINE_TIMER           ((mtime_t*) MTIME_BASE)

void __MTI_HANDLER(); // interrupt handler

void time_init();

static void set_mtime(uint64_t val);
static void set_mtimecmp(uint64_t val);
static uint64_t get_time();
static uint64_t get_mtimecmp();

static uint32_t milliseconds();
static uint32_t microseconds();

void delay(uint32_t val);
void delay_micro(uint32_t val);

extern volatile uint32_t __millis;




static inline void __attribute__((always_inline)) set_mtime(uint64_t val) {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } cycles;
    cycles.u64 = val;

    MACHINE_TIMER->mtime  = 0;
    MACHINE_TIMER->mtimeh = cycles.u32[1];
    MACHINE_TIMER->mtime  = cycles.u32[0];
}

static inline void __attribute__((always_inline)) set_mtimecmp(uint64_t val) {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } cycles;
    cycles.u64 = val;

    MACHINE_TIMER->mtimecmp  = 0;
    MACHINE_TIMER->mtimecmph = cycles.u32[1];
    MACHINE_TIMER->mtimecmp  = cycles.u32[0];
}

static inline uint64_t __attribute__((always_inline)) get_time() {
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

static inline uint64_t __attribute__((always_inline)) get_mtimecmp() {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } cycles;

    cycles.u32[1] = MACHINE_TIMER->mtimecmph;
    cycles.u32[0] = MACHINE_TIMER->mtimecmp;
    return cycles.u64;
}


static inline __attribute((always_inline)) uint32_t milliseconds() {
    return __millis;
}

static inline uint32_t __attribute__((always_inline)) microseconds() {
    return csrr(CSR_TIME);
}


#endif // __TIME_H
