`timescale 1ns/1ps
module ps2_controller (
    input clk,
    input rst_n,
    input ps2_clk,
    input ps2_data,

    output reg [7:0] data,
    output reg valid,
    output reg err
);
    reg [1:0] state;
    reg ps2_clk_negedge;
    reg parity_chk;
    integer bit_pos;

    assign ps2_clk_negedge = ~ps2_clk;

    initial state = 0;

    always @(rst_n) begin 
        if (!rst_n) begin 
            state <= 0;
            data <= 0;
            valid <= 0;
            err <= 0;
        end
    end

    always @(negedge ps2_clk, posedge ps2_clk) begin 
        case (state)
            0: begin 
                if (ps2_clk_negedge) begin 
                    bit_pos <= 0;
                    parity_chk <= 1;
                    state <= 1;
                end
                else begin 
                    valid <= 0;
                    err <= 0;
                    data <= 0;
                    state <= 0;
                end
            end
            1: begin 
                if (bit_pos == 7) begin 
                    data[bit_pos] <= ps2_data;
                    parity_chk <= parity_chk ^ ps2_data;
                    state <= 2;
                end
                else begin 
                    data[bit_pos] <= ps2_data;
                    bit_pos <= bit_pos + 1;
                    parity_chk <= parity_chk ^ ps2_data;
                    state <= 1;
                end
            end
            2: begin 
                if (parity_chk == ps2_data) begin 
                    valid <= 1;
                    err <= 0;
                    state <= 0;
                end
                else begin
                    err <= 1;
                    valid <= 1;
                    state <= 0;
                end
            end
            default: begin 
                state <= 0;
                valid <= 0;
                err <= 0;
                data <= 0;
            end
        endcase
    end
endmodule