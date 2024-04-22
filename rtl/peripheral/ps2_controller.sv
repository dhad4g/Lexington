`timescale 1ns/1ps
module ps2_controller (
    input clk,
    input ps2_clk,
    input ps2_data,

    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_err
);
    reg [1:0] state;
    reg ps2_clk_negedge;
    reg parity_chk;
    integer bit_pos;

    assign ps2_clk_negedge = ~ps2_clk;

    initial state = 0;

    always @(negedge ps2_clk, posedge ps2_clk) begin 
        case (state)
            0: begin 
                if (ps2_clk_negedge) begin 
                    bit_pos <= 0;
                    parity_chk <= 1;
                    state <= 1;
                end
                else begin 
                    rx_valid <= 0;
                    rx_err <= 0;
                    rx_data <= 0;
                    state <= 0;
                end
            end
            1: begin 
                if (bit_pos == 7) begin 
                    rx_data[bit_pos] <= ps2_data;
                    parity_chk <= parity_chk ^ ps2_data;
                    state <= 2;
                end
                else begin 
                    rx_data[bit_pos] <= ps2_data;
                    bit_pos <= bit_pos = 1;
                    parity_chk <= parity_chk ^ ps2_data;
                    state <= 1;
                end
            end
            2: begin 
                if (parity_chk == ps2_data) begin 
                    rx_valid <= 1;
                    rx_err <= 0;
                    state <= 0;
                end
                else begin
                    rx_err <= 1;
                    rx_valid <= 1;
                    state <= 0;
                end
            end
            default: begin 
                state <= 0;
                rx_valid <= 0;
                rx_err <= 0;
                rx_data <= 0;
            end
        endcase
    end
endmodule