#ifndef __TIME_H
#define __TIME_H

#include <stdint.h>

#include "csr.h"


#define MTIME_BASE              ((uint32_t)0xC0000000)

typedef volatile struct __attribute__((packed,aligned(4))) {
    uint32_t mtime;
    uint32_t mtimeh;
    uint32_t mtimecmp;
    uint32_t mtimecmph;
} mtime_t;

#define MACHINE_TIMER           ((mtime_t*) MTIME_BASE)


void set_mtime(uint64_t val);
void set_mtimecmp(uint64_t val);
uint64_t get_time();
uint64_t get_mtimecmp();

uint32_t milliseconds();
uint32_t microseconds();
void delay(uint32_t val);
void delay_micro(uint32_t val);


#endif // __TIME_H
