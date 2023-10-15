`timescale 1ns/1ps

`include "rv32.sv"


module fetch (
        // clock not needed; module is purely combinatorial
        // reset not needed; module is stateless

        input  rv32::word pc,               // current value of the program counter
        input  logic stall_fetch,           // stall Fetch Stage
        output logic ibus_rd_en,            // IBus read enable
        output rv32::word pc4               // PC + 4
    );

    assign ibus_rd_en = stall_fetch;
    assign pc4 = pc + 4;

endmodule