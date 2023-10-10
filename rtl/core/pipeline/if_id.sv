`timescale 1ns/1ps

`include rv32.sv

module if_id (
        input  logic clk,
        input  logic rst_n,

        input  logic stall,
        input  logic squash,

        input  logic bubble_i,
        input  rv32::word pc_i,
        input  rv32::word pc4_i,
        input  rv32::word inst_i,

        output logic bubble_o,
        output rv32::word pc_o,
        output rv32::word pc4_o,
        output rv32::word inst_o
    );

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bubble_o        <= 1;
            pc_o            <= 0;
            pc4_o           <= 0;
            inst_o          <= 0;
        end
        else begin
            if (squash) begin
                bubble_o        <= 1;
            end
            else if (!stall) begin
                bubble_o        <= bubble_i;
                pc_o            <= pc_i;
                pc4_o           <= pc4_i;
                inst_o          <= inst_i;
            end
        end
    end

endmodule
