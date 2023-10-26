`timescale 1ns/1ps

`include "rv32.sv"
`include "lexington.sv"
import lexington::*;


module debug (
        input  logic clk,                       // system clock
        input  logic rst_n,                     // reset (active-low)

        output logic uart_en,                   // UART override enable
        output logic uart_send,                 // UART send flag
        input  logic uart_recv,                 // UART receive flag
        output logic [7:0] uart_dout,           // UART tx data
        input  logic [7:0] uart_din,            // UART rx data
        input  logic uart_rx_busy,              // UART RX busy flag
        input  logic uart_tx_busy               // UART TX busy flag
    );

    localparam MSG_LENGTH = 20;

    logic [7:0] msg [MSG_LENGTH-1:0];   // Message
    integer msg_idx;                    // Index of current message byte

    assign uart_en = 1;
    assign uart_dout = msg[msg_idx];

    initial begin
        msg[0]  = "L";
        msg[1]  = "e";
        msg[2]  = "x";
        msg[3]  = "i";
        msg[4]  = "n";
        msg[5]  = "g";
        msg[6]  = "t";
        msg[7]  = "o";
        msg[8]  = "n";
        msg[9]  = " ";
        msg[10] = "D";
        msg[11] = "e";
        msg[12] = "b";
        msg[13] = "u";
        msg[14] = "g";
        msg[15] = "g";
        msg[16] = "e";
        msg[17] = "r";
        msg[18] = "\r";
        msg[19] = "\n";
    end


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            uart_send <= 0;
            msg_idx   <= MSG_LENGTH-1;
        end
        else begin
            if (!uart_tx_busy) begin
                uart_send <= 1;
                if (msg_idx == MSG_LENGTH - 1) begin
                    msg_idx <= 0;
                end
                else begin
                    msg_idx <= msg_idx + 1;
                end
            end
            else begin
                uart_send <= 0;
            end
        end
    end

endmodule