#include "lexington.h"


int main() {

    while (1) {
        u8 data = uart_rx(UART0);
        uart_tx(UART0, data);
    }

    return 0;
}