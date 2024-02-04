#include "time.h"

volatile uint32_t __millis = 0;

void __MTI_HANDLER() {
    set_mtimecmp(1000 + get_mtimecmp());
    __millis++;
}

void time_init() {
    set_mtimecmp(1000);
    enable_interrupt(TRAP_CODE_MTI);
    enable_global_interrupts();
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
