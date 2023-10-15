`timescale  1ns/1ps

`include "rv32.sv"


module control (
        input  logic clk,
        input  logic rst_n,

        input  logic branch,
        input  rv32::word branch_addr,
        input  logic trap_req,
        input  rv32::word trap_addr,
        input  logic atomic_csr,
        input  logic bubble_decode,
        input  logic bubble_exec,

        output logic next_pc_en,
        output rv32::word next_pc,
        output logic bubble_fetch,
        output logic trap_insert,
        output logic atomic_csr_pending
    );

    // Add bubble to branch and atomic_csr flags
    logic _branch, _atomic_csr;
    assign _branch = branch & !bubble_decode;
    assign _atomic_csr = atomic_csr & !bubble_decode;

    assign next_pc_en = _branch | trap_insert;
    assign next_pc = (_branch) ? branch_addr : trap_addr;
    assign bubble_fetch = _branch | (trap_req & ~trap_insert) | (atomic_csr_pending);
    assign trap_insert = ~atomic_csr_pending & trap_req & bubble_decode & bubble_exec;

    always_latch begin
        if (~rst_n | (bubble_decode & bubble_exec)) begin
            // clear
            atomic_csr_pending = 0;
        end
        else if (_atomic_csr) begin
            // set
            atomic_csr_pending = 1;
        end
    end

endmodule
