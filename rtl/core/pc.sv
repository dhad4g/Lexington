`timescale 1ns/1ps

`include "rv32.sv"
`include "saratoga.sv"
import saratoga::*;


module pc #(
        parameter RESET_ADDR = DEFAULT_RESET_ADDR
    ) (
        input logic clk,                    // system clock
        input logic rst_n,                  // global synchronous reset (active-low)
        input logic bubble_fetch,           // insert bubble in Fetch Stage
        input logic stall_fetch,            // stall Fetch Stage
        input logic next_pc_en,             // enable override of PC+4
        input rv32::word next_pc,           // next program counter value
        output rv32::word pc                // current program counter value
    );

    rv32::word _pc;

    // assign pc = (next_pc_en) ? next_pc : _pc;
    assign pc = _pc;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            _pc <= RESET_ADDR;
        end
        else if (!stall_fetch) begin
            if (next_pc_en) begin
                _pc <= next_pc;
            end
            else if (!bubble_fetch) begin
                _pc <= _pc+4;
            end
        end
    end

endmodule
