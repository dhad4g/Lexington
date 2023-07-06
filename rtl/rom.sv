`timescale 1ns/1ps


module ROM #(
        parameter WIDTH         = 32,               // data width
        parameter ADDR_WIDTH    = 10,               // address width (word-addressable)
        localparam DEPTH        = 2**ADDR_WIDTH     // number of words in ROM
    ) (
        // clock not needed; module is asynchronous
        // reset not needed; module is read-only

        input wire  rd_en1,                         // read enable 1
        input wire  [ADDR_WIDTH-1:0] addr1,         // read address 1 (word-addressable)
        output wire [WIDTH-1:0] rd_data1,           // read data 1

        input wire  rd_en2,                         // read enable 2
        input wire  [ADDR_WIDTH-1:0] addr2,         // read address 2 (word-addressable)
        output wire [WIDTH-1:0] rd_data2,           // read data 2
    );

    reg [WIDTH-1:0] data [DEPTH-1:0];

    initial begin
        $readmemb("rom.bin", data, 0, DEPTH-1);
    end


    assign rd_data1 = (rd_en1) ? data[addr1] : 0;
    assign rd_data2 = (rd_en2) ? data[addr2] : 0;

endmodule
