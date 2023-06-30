`timescale 1ns/1ps

module regfile #(
        parameter WIDTH         = 32,       // Data width
        parameter REG_COUNT     = 32,       // Number of registers
        parameter ADDR_WIDTH    = $clog2(REG_COUNT) // Address with for register select
    ) (
        input clk,                          // write port clock
        // reset not needed, registers can start in undefined state

        input  rs1_en,                      // enable for read port 1
        input  [ADDR_WIDTH-1:0] rs1_addr,   // address for read port 1
        output [WIDTH-1:0] rs1_data,        // data for read port 1

        input  rs2_en,                      // enable for read port 2
        input  [ADDR_WIDTH-1:0] rs2_addr,   // address for read port 2
        output [WIDTH-1:0] rs2_data,        // data for read port 2

        input  dest_en,                     // enable for write port
        input  [ADDR_WIDTH-1:0] dest_addr,  // address for write port
        input  [WIDTH-1:0] dest_data        // data for write port

    );

    reg [WIDTH-1:0] ram [REG_COUNT-1:1];

    assign rs1_data = (rs1_en && rs1_addr) ? ram[rs1_addr] : 0;
    assign rs2_data = (rs2_en && rs2_addr) ? ram[rs2_addr] : 0;

    always_ff @(posedge clk) begin
        if (dest_en && dest_addr) begin
            ram[dest_addr] <= dest_data;
        end
    end
    
endmodule