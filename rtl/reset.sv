`timescale 1ns/1ps


module reset (
        input  logic clk,
        input  logic rst_n_i,
        output logic rst_n_o
    );

    logic _rst_reg;
    always_ff @(posedge clk) begin
        _rst_reg <= rst_n_i;
    end

    // BUFG: Global Clock Simple Buffer
    // 7 Series
    // Xilinx HDL Libraries Guide, version 2012.2
    BUFG RST_BUFG (
        .I(_rst_reg), // 1-bit input: Clock input
        .O(rst_n_o)   // 1-bit output: Clock output
    );
    // End of BUFG_inst instantiation

endmodule
