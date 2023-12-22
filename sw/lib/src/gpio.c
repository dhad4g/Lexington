#include "gpio.h"


void gpio_mode(gpio_t* bank, uint32_t pin, uint32_t mode) {
    uint32_t mask = 0b1U << pin;
    if (mode) {
        bank->MODE = mask | bank->MODE;
    } else {
        bank->MODE = (~mask) & bank->MODE;
    }
}

uint32_t gpio_read(gpio_t* bank, uint32_t pin) {
    uint32_t x = bank->IDATA;
    x = (x >> pin) & 0b1U;
    return x;
}

void gpio_write(gpio_t* bank, uint32_t pin, uint32_t state) {
    uint32_t mask = 0b1U << pin;
    if (state) {
        bank->ODATA = mask | bank->ODATA;
    } else {
        bank->ODATA = (~mask) & bank->ODATA;
    }
}
