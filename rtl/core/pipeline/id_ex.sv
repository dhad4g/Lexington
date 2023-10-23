`timescale 1ns/1ps

`include "rv32.sv"
`include "saratoga.sv"
import saratoga::*;


module id_ex (
        input  logic clk,
        input  logic rst_n,

        input  logic stall_decode,
        input  logic squash_decode,
        input  logic stall_exec,

        input  logic bubble_i,
        input  rv32::word pc_i,
        input  rv32::word src1_i,
        input  rv32::word src2_i,
        input  rv32::word alt_data_i,
        input  rv32::csr_addr_t csr_addr_i,
        input  rv32::gpr_addr_t dest_i,
        input  alu_op_t alu_op_i,
        input  lsu_op_t lsu_op_i,

        output logic bubble_o,
        output rv32::word pc_o,
        output rv32::word src1_o,
        output rv32::word src2_o,
        output rv32::word alt_data_o,
        output rv32::csr_addr_t csr_addr_o,
        output rv32::gpr_addr_t dest_o,
        output alu_op_t alu_op_o,
        output lsu_op_t lsu_op_o
    );

    always_ff @(posedge clk) begin
        if (!rst_n | squash_decode) begin
            bubble_o        <= 1;
            pc_o            <= 0;
            src1_o          <= 0;
            src2_o          <= 0;
            alt_data_o      <= 0;
            csr_addr_o      <= 0;
            dest_o          <= 0;
            alu_op_o        <= ALU_NOP;
            lsu_op_o        <= LSU_NOP;
        end
        else begin
            if (bubble_i | (stall_decode & !stall_exec)) begin
                bubble_o        <= 1;
                pc_o            <= 0;
                src1_o          <= 0;
                src2_o          <= 0;
                alt_data_o      <= 0;
                csr_addr_o      <= 0;
                dest_o          <= 0;
                alu_op_o        <= ALU_NOP;
                lsu_op_o        <= LSU_NOP;
            end
            else if (!stall_exec) begin
                bubble_o        <= bubble_i;
                pc_o            <= pc_i;
                src1_o          <= src1_i;
                src2_o          <= src2_i;
                alt_data_o      <= alt_data_i;
                csr_addr_o      <= csr_addr_i;
                dest_o          <= dest_i;
                alu_op_o        <= alu_op_i;
                lsu_op_o        <= lsu_op_i;
            end
        end
    end

endmodule
