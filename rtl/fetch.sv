`timescale 1ns/1ps


module fetch #(
        parameter WIDTH             = 32,                   // data width
        parameter ROM_ADDR_WIDTH    = 10                    // ROM address with (word-addressable)
    ) (
        // clock not needed; module is purely combinatorial
        // reset not needed; module is stateless

        input wire  [WIDTH-1:0] pc,                         // current value of the program counter

        output wire ibus_rd_en,                             // instruction bus (ibus) read enable
        output wire [ROM_ADDR_WIDTH-1:0] ibus_rd_addr,      // ibus read address (word-addressable)
        input wire  [WIDTH-1:0] ibus_rd_data,               // ibus read data

        output wire [WIDTH-1:0] inst,                       // current instruction bits
        output wire access_fault                            // asserted if PC is outside of ibus address space
    );


    assign ibus_rd_en = 1;
    assign ibus_rd_addr = pc[(ROM_ADDR_WIDTH+2)-1:2];
    assign inst = ibus_rd_data;

    assign access_fault = |( pc[WIDTH-1:ROM_ADDR_WIDTH+2] ); // reduction operator OR of upper address bits

endmodule