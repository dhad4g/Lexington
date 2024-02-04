#include "lexington.h"

// #define MAX_COUNT   1000000
#define BLINK_DELAY     500


int main() {

    // Timer not working
    // time_init();

    for (uint32_t i=0; i<16; i++) {
        gpio_mode(GPIOA, i, OUTPUT);
    }

    volatile uint32_t count = 0;
    while (1) {
        for (uint32_t i=0; i<15; i++) {
            gpio_write(GPIOA, i, HIGH);
            for (count=0; count<MAX_COUNT; count++); //delay
            // delay(BLINK_DELAY);
            gpio_write(GPIOA, i, LOW);
        }
        for (uint32_t i=15; i>0; i--) {
            gpio_write(GPIOA, i, HIGH);
            for (count=0; count<MAX_COUNT; count++); //delay
            // delay(BLINK_DELAY);
            gpio_write(GPIOA, i, LOW);
        }
    }

    return 0;
}
