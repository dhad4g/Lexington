`timescale 1ns/1ps

`include "rv32.sv"
`include "saratoga.sv"
import saratoga::*;


(* dont_touch = "yes" *)
module rom #(
        parameter ADDR_WIDTH    = DEFAULT_ROM_ADDR_WIDTH    // word-addressable address bits
    ) (
        input  logic clk,
        // reset not needed; module is read-only

        input  logic rd_en1,                                // read enable 1
        input  logic [ADDR_WIDTH-1:0] addr1,                // read address 1 (word-addressable)
        output rv32::word rd_data1,                         // read data 1

        input  logic rd_en2,                                // read enable 2
        input  logic [ADDR_WIDTH-1:0] addr2,                // read address 2 (word-addressable)
        output rv32::word rd_data2                          // read data 2
    );

    localparam DEPTH = 2 ** ADDR_WIDTH;
    rv32::word data [DEPTH-1:0];

    initial begin
        $readmemh("rom.hex", data, 0, DEPTH-1);
    end

    always_ff @(posedge clk) begin
        if (rd_en1) begin
            rd_data1 <= data[addr1];
        end
        if (rd_en2) begin
            rd_data2 <= data[addr2];
        end
    end

endmodule
