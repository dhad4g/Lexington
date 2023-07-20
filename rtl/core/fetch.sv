`timescale 1ns/1ps

`include "rv32.sv"


module fetch #(
        
    ) (
        // clock not needed; module is purely combinatorial
        // reset not needed; module is stateless

        input rv32::word pc,                // current value of the program counter

        output logic ibus_rd_en,            // instruction bus (ibus) read enable
        output rv32::word ibus_addr,        // ibus read address (word-addressable)
        input  rv32::word ibus_rd_data,     // ibus read data

        output rv32::word inst              // current instruction bits
    );


    assign ibus_rd_en = 1;
    assign ibus_addr  = pc;
    assign inst = ibus_rd_data;

endmodule