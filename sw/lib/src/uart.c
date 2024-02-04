#include "uart.h"


inline void uart_tx(UART_t* UART, uint8_t data) {
    while (UART->CONF & UART_CONF_TX_FULL);
    UART->DATA = (uint32_t) data;
}

inline uint8_t uart_rx(UART_t* UART) {
    while (UART->CONF & UART_CONF_RX_EMPTY);
    return (uint8_t) UART->DATA;
}
