`timescale 1ns/1ps


module uart_tx #(
        parameter BUS_CLK           = 40_000_000,       // Bus clock frequency in Hz
        parameter BAUD              = 9600              // BAUD rate
    ) (
        input  logic clk,                               // Bus clock
        input  logic rst_n,                             // Reset (active-low)

        output logic tx,                                // TX serial output

        input  logic send,                              // Pulse for one bus clock cycle to start TX
        input  logic [7:0] dout,                        // Byte to send

        output logic busy,                              // Asserted when busy transmitting
        output logic done                               // Asserted for one bus clock cycle after transmitting
    );

    localparam DIV_COUNT = BUS_CLK / BAUD;

    // Clock divider (outputs clk_en)
    logic clk_en; // outputs clock enable signal at BAUD rate
    integer counter;
    assign clk_en = (busy && (counter == 0));
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
        end
        else begin
            if (busy) begin
                if (counter == DIV_COUNT-1) begin
                    counter <= 0;
                end
                else begin
                    counter <= counter + 1;
                end
            end
            else begin
                counter <= 0;
            end
        end
    end


    // TX Engine
    integer bit_idx;
    logic [7:0] _dout; // latch the output data
    enum {START, SEND, STOP, DONE} state;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state   <= START;
            tx      <= 1;
            _dout   <= 0;
            bit_idx <= 0;
            busy    <= 0;
            done    <= 0;
        end
        else begin
            if (done) done <= 0;
            if (!busy && send) begin
                busy    <= 1;
                _dout   <= dout;
            end
            if (clk_en) begin
                case (state)

                START: begin
                    state   <= SEND;
                    tx      <= 0;
                    bit_idx <= 0;
                end

                SEND: begin
                    tx      <= _dout[bit_idx];
                    bit_idx <= bit_idx + 1;
                    if (bit_idx == 7) begin
                        state <= STOP;
                        bit_idx <= 0;
                    end
                end

                STOP: begin
                    state   <= DONE;
                    tx      <= 1;
                end

                DONE: begin
                    state   <= START;
                    busy    <= 0;
                    done    <= 1;
                end

                default: begin
                    state   <= START;
                    tx      <= 1;
                end

                endcase
            end
        end
    end

endmodule