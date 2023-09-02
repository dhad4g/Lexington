#include "gpio.h"


void gpio_mode(gpio_t* bank, uint32_t pin, uint32_t mode) {
    uint32_t mask = (mode ? 0b1U : 0b0U) << pin;
    uint32_t x = bank->MODE;
    if (mode) {
        x |= mask;
    } else {
        x &= ~mask;
    }
    bank->MODE = x;
}

uint32_t gpio_read(gpio_t* bank, uint32_t pin) {
    uint32_t x = bank->IDATA;
    x = (x >> pin) & 0b1U;
    return x;
}

void gpio_write(gpio_t* bank, uint32_t pin, uint32_t state) {
    uint32_t mask = (state ? 0b1U : 0b0U) << pin;
    uint32_t x = bank->ODATA;
    if (state) {
        x |= mask;
    } else {
        x &= mask;
    }
    bank->ODATA = x;
}
