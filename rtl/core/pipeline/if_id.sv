`timescale 1ns/1ps

`include "rv32.sv"

module if_id (
        input  logic clk,
        input  logic rst_n,

        input  logic stall_decode,

        input  logic bubble_i,
        input  rv32::word pc_i,
        input  rv32::word inst_i,

        output logic bubble_o,
        output rv32::word pc_o,
        output rv32::word inst_o
    );

    // Stall inst
    logic _stall;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            _stall <= 0;
        end
        else begin
            _stall <= stall_decode;
        end
    end
    always_latch begin
        if (!rst_n) begin
            inst_o <= 0;
        end
        else if (!stall_decode & !_stall) begin
            inst_o <= inst_i;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bubble_o    <= 1;
            pc_o        <= 0;
        end
        else begin
            if (bubble_i) begin
                bubble_o    <= 1;
                pc_o        <= -1;
            end
            else if (!stall_decode) begin
                bubble_o    <= bubble_i;
                pc_o        <= pc_i;
            end
        end
    end

endmodule
