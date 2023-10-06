`timescale 1ns/1ps

`include rv32.sv

module mem_wb (
        input  logic clk,
        input  logic rst_n,

        input  logic stall,
        input  logic squash,

        input  logic bubble_i,
        input  rv32::word pc_i,
        input  rv32::priv_mode_t priv_i,
        input  rv32::priv_mode_t mem_priv_i,
        input  logic endianness_i,
        input  rv32::word dest_data_i,
        input  rv32::gpr_addr_t dest_i,

        output logic bubble_o,
        output rv32::word pc_o,
        output rv32::priv_mode_t priv_o,
        output rv32::priv_mode_t mem_priv_o,
        output logic endianness_o,
        output rv32::word dest_data_o,
        output rv32::gpr_addr_t dest_o
    );

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bubble_o        <= 1;
            pc_o            <= 0;
            priv_o          <= 0;
            mem_priv_o      <= 0;
            endianness_o    <= 0;
            dest_data_o     <= 0;
            dest_o          <= 0;
        end
        else  begin
            if (squash) begin
                bubble_o        <= 0;
            end
            else if (!stall) begin
                bubble_o        <= bubble_i;
                pc_o            <= pc_i;
                priv_o          <= priv_i;
                mem_priv_o      <= mem_priv_i;
                endianness_o    <= endianness_i;
                dest_data_o     <= dest_data_i;
                dest_o          <= dest_i;
            end
        end
    end

endmodule
