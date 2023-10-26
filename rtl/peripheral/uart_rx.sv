`timescale 1ns/1ps


module uart_rx #(
        parameter BUS_CLK           = 40_000_000,       // Bus clock frequency in Hz
        parameter BAUD              = 9600              // BAUD rate
    ) (
        input  logic clk,                               // Bus clock
        input  logic rst_n,                             // Reset (active-low)

        input  logic rx,                                // RX serial input

        output logic [7:0] din,                         // Receive data
        output logic busy,                              // Asserted when receiving data
        output logic recv,                              // Asserted for one bus clock cycle when data is received
        output logic err                                // Asserted for one bus clock cycle if stop bit is not found
    );

    localparam DIV_COUNT = BUS_CLK / BAUD;

    // Clock divider (outputs clk_en)
    logic clk_en; // outputs clock enable signal at BAUD rate
    integer counter;
    assign clk_en = (busy && (counter == DIV_COUNT/2)); // read at midpoint
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
    logic _err; // shadow error
    logic [7:0] _din; // shadow data
    integer bit_idx;
    enum {START, RECEIVE, STOP, DONE} state;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state   <= START;
            din     <= 0;
            _din    <= 0;
            bit_idx <= 0;
            busy    <= 0;
            recv    <= 0;
            err     <= 0;
            _err    <= 0;
        end
        else begin
            if (recv) recv <= 0;
            if (err) err <= 0;
            if (!busy && !rx) busy <= 1;
            if (clk_en) begin
                case (state)

                START: begin
                    if (rx) begin
                        busy    <= 0; // false start
                    end
                    else begin
                        state   <= RECEIVE;
                        bit_idx <= 0;
                    end
                end

                RECEIVE: begin
                    _din[bit_idx] <= rx;
                    bit_idx <= bit_idx + 1;
                    if (bit_idx == 7) begin
                        state <= STOP;
                        bit_idx <= 0;
                    end
                end

                STOP: begin
                    state   <= DONE;
                    _err    <= !rx;
                end

                DONE: begin
                    if (!rx && !_err) begin
                        // start bit detected immediately after stop bit
                        state   <= RECEIVE;
                        bit_idx <= 0;
                    end
                    else begin
                        state   <= START;
                        busy    <= 0;
                    end
                    din     <= _din;
                    recv    <= !_err;
                    err     <= _err;
                end

                default: begin
                    state   <= START;
                end

                endcase
            end
        end
    end

endmodule