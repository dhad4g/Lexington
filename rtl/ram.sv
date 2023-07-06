`timescale 1ns/1ps


module RAM #(
        parameter WIDTH         = 32,               // data width
        parameter ADDR_WIDTH    = 10,               // address width (word-addressable)
        localparam DEPTH        = 2**ADDR_WIDTH     // number of words in RAM
    ) (
        input wire clk,
        // reset not needed; memory can start in undefined state

        input wire  rd_en,                          // read enable
        input wire  wr_en,                          // write enable
        input wire  [ADDR_WIDTH-1:0] addr,          // read/write address (word-addressable)
        input wire  [WIDTH-1:0] wr_data,            // write data
        output wire [WIDTH-1:0] rd_data             // read data
    );

    reg [WIDTH-1:0] data [DEPTH-1:0];


    assign rd_data = (rd_en) ? data[addr] : 0;

    always_ff @(posedge clk) begin
        if (wr_en) begin
            data[addr] <= wr_data;
        end
    end

endmodule
