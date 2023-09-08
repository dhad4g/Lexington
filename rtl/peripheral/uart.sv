`timescale 1ns/1ps

`include "axi4_lite.sv"


module uart #(
        parameter WIDTH         = 32,           // bus width
        parameter BUS_CLK       = 40_000_000,   // bus clock in Hz
        parameter BAUD          = 9600,         // BAUD rate
        parameter FIFO_DEPTH    = 8             // FIFO depth for both TX and RX (depth 0 is invalid)
    ) (
        input  logic rx,                        // UART RX signal
        output logic tx,                        // UART TX signal
        output logic rx_int,                    // RX interrupt
        output logic tx_int,                    // TX interrupt

        axi4_lite.subordinate axi               // AXI4-Lite subordinate interface
    );

    // AXI registers
    logic [WIDTH-1:0] uartx_data, uartx_conf;

endmodule
