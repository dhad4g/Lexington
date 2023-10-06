`timescale 1ns/1ps

`include rv32.sv


module ex_mem (
        input  logic clk,
        input  logic rst_n,

        input  logic stall,
        input  logic squash,

        input  logic bubble_i,
        input  rv32::word pc_i,
        input  rv32::priv_mode_t priv_i,
        input  rv32::priv_mode_t mem_priv_i,
        input  logic endianness_i,
        input  rv32::word alu_result_i,
        input  rv32::word alt_data_i,
        input  rv32::csr_addr_t csr_addr_i,
        input  rv32::gpr_addr_t dest_i,
        input  logic mem_en_i,
        input  logic csr_wr_i,
        input  logic load_forward_mem_i,

        output logic bubble_o,
        output rv32::word pc_o,
        output rv32::priv_mode_t priv_o,
        output rv32::priv_mode_t mem_priv_o,
        output logic endianness_o,
        output rv32::word alu_result_o,
        output rv32::word alt_data_o,
        output rv32::csr_addr_t csr_addr_o,
        output rv32::gpr_addr_t dest_o,
        output logic mem_en_o,
        output logic csr_wr_o,
        output logic load_forward_mem_o,
    );

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bubble_o        <= 1;
            pc_o            <= 0;
            priv_o          <= 0;
            mem_priv_o      <= 0;
            endianness_o    <= 0;
            alu_result_o    <= 0;
            alt_data_o      <= 0;
            csr_addr_o      <= 0;
            dest_o          <= 0;
            mem_en_o        <= 0;
            csr_wr_o        <= 0;
            load_forward_mem_o <= 0;
        end
        else begin
            if (squash) begin
                bubble_o    <= 0;
            end
            else if (!stall) begin
                bubble_o        <= bubble_i;
                pc_o            <= pc_i;
                priv_o          <= priv_i;
                mem_priv_o      <= mem_priv_i;
                endianness_o    <= endianness_i;
                alu_result_o    <= alu_result_i;
                alt_data_o      <= alt_data_i;
                csr_addr_o      <= csr_addr_i;
                dest_o          <= dest_i;
                mem_en_o        <= mem_en_i;
                csr_wr_o        <= csr_wr_i;
                load_forward_mem_o <= load_forward_mem_i;
            end
        end
    end

endmodule
