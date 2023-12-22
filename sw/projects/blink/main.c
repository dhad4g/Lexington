#include "lexington.h"

#define MAX_COUNT   1000000


int main() {

    for (uint32_t i=0; i<16; i++) {
        gpio_mode(GPIOA, i, OUTPUT);
    }
    // GPIOA->MODE = 0x0000FFFFu;

    volatile uint32_t count = 0;
    while (1) {
        for (uint32_t i=0; i<15; i++) {
            gpio_write(GPIOA, i, HIGH);
            for (count=0; count<MAX_COUNT; count++); //delay
            gpio_write(GPIOA, i, LOW);
        }
        for (uint32_t i=15; i>0; i--) {
            gpio_write(GPIOA, i, HIGH);
            for (count=0; count<MAX_COUNT; count++); //delay
            gpio_write(GPIOA, i, LOW);
        }
    }

    return 0;
}
