`timescale 1ns/1ps

`include "rv32.sv"
`include "saratoga.sv"
import saratoga::*;


module pc #(
        parameter RESET_ADDR = DEFAULT_RESET_ADDR
    ) (
        input logic clk,                    // system clock
        input logic rst_n,                  // global synchronous reset (active-low)
        input logic stall_fetch,            // stall Fetch Stage
        input logic next_pc_en,             // enable override of PC+4
        input rv32::word next_pc,           // next program counter value
        output rv32::word pc                // current program counter value
    );


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pc <= RESET_ADDR;
        end
        else if (!stall_fetch) begin
            pc <= (next_pc_en) ? next_pc : pc+4;
        end
    end

endmodule
