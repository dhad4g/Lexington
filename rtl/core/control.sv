`timescale  1ns/1ps

`include "rv32.sv"


module control (
        input  logic clk,
        input  logic rst_n,

        input  logic branch,
        input  rv32::word branch_addr,
        input  logic trap_req,
        input  rv32::word trap_addr,
        input  logic csr_rd_en,
        input  rv32::csr_addr_t decode_csr_addr,
        input  rv32::csr_addr_t exec_csr_addr,
        input  logic atomic_csr,
        input  logic bubble_decode,
        input  logic squash_decode,
        input  logic bubble_exec,

        output logic next_pc_en,
        output rv32::word next_pc,
        output logic bubble_fetch,
        output logic stall_decode,
        output logic trap_insert,
        output logic atomic_csr_pending
    );

    // Filter inputs
    logic _bubble_decode, _branch, _csr_rd_en, _atomic_csr;
    assign _bubble_decode = bubble_decode | squash_decode;
    assign _branch      = branch & !_bubble_decode;
    assign _csr_rd_en   = csr_rd_en & !_bubble_decode;
    assign _atomic_csr  = atomic_csr & !_bubble_decode;

    // Control next_pc
    assign next_pc_en = _branch | trap_insert;
    assign next_pc = (_branch) ? branch_addr : trap_addr;

    // Fetch Stage bubble
    assign bubble_fetch = _branch | trap_req | atomic_csr_pending;

    // Generate trap request acknowledge (trap_insert)
    assign trap_insert = ~atomic_csr_pending & trap_req & _bubble_decode;

    // Stall during CSR read hazard
    assign stall_decode = _csr_rd_en & (decode_csr_addr == exec_csr_addr) & !bubble_exec;

    // atomic_csr_pending register
    logic _atomic_csr_pending;
    assign atomic_csr_pending = _atomic_csr | _atomic_csr_pending;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            _atomic_csr_pending <= 0;
        end
        else begin
            if (_bubble_decode) begin
                _atomic_csr_pending <= 0;
            end
            else if (_atomic_csr) begin
                _atomic_csr_pending <= 1;
            end
        end
    end

endmodule
