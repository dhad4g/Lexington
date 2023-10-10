`timescale  1ns/1ps

`include "rv32.sv"


module control (
        input  logic clk,
        input  logic rst_n,

        input  logic jump,
        input  rv32::word jump_pc,
        input  logic trap_req,
        input  rv32::word trap_pc,
        input  logic atomic_csr,
        input  logic bubble_decode,
        input  logic bubble_exec,

        output logic next_pc_en,
        output rv32::word next_pc,
        output logic bubble_fetch,
        output logic trap_insert,
        output logic atomic_csr_pending
    );

    assign next_pc_en = jump | trap_insert;
    assign next_pc = (jump) ? jump_pc : trap_pc;
    assign bubble_fetch = jump | (trap_req & ~trap_insert) | (atomic_csr_pending);
    assign trap_insert = trap_req & bubble_decode & bubble_exec;

    always_latch begin
        if (~rst_n | (bubble_decode & bubble_exec)) begin
            // clear
            atomic_csr_pending = 0;
        end
        else if (atomic_csr) begin
            // set
            atomic_csr_pending = 1;
        end
    end

endmodule
