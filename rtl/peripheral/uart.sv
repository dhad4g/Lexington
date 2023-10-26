//depend peripheral/uart_rx.sv
//depend peripheral/uart_tx.sv
//depend mem/fifo.sv
`timescale 1ns/1ps

`include "axi4_lite.sv"


module uart #(
        parameter WIDTH         = 32,           // bus data width
        parameter BUS_CLK       = 10_000_000,   // bus clock frequency in Hz
        parameter BAUD          = 9600,         // BAUD rate
        parameter FIFO_DEPTH    = 8             // FIFO depth for both TX and RX (depth 0 is invalid)
    ) (
        input  logic rx,                        // UART RX signal
        output logic tx,                        // UART TX signal
        output logic rx_int,                    // RX interrupt
        output logic tx_int,                    // TX interrupt

        input  logic dbg_en,                    // Enable override access by debugger
        input  logic dbg_send,                  // Debugger send flag
        output logic dbg_recv,                  // Debugger receive flag
        input  logic [7:0] dbg_dout,            // Debugger tx data (bypasses FIFO)
        output logic [7:0] dbg_din,             // Debugger rx data (bypasses FIFO)
        output logic dbg_rx_busy,               // RX busy flag for debugger
        output logic dbg_tx_busy,               // TX busy flag for debugger

        axi4_lite.subordinate axi               // AXI4-Lite subordinate interface
    );

    // AXI Registers
    logic [WIDTH-1:0] UARTx_data, UARTx_conf;
    logic [2:0] _araddr;
    logic [2:0] _awaddr;

    // RX/TX Signals
    logic [7:0] rx_din, tx_dout;
    logic rx_recv, tx_send;
    logic rx_busy, tx_busy;
    logic tx_done;
    logic rx_err, _rx_err; // sticky bit, and direct connect
    // FIFO Signals
    logic [7:0] rx_fifo_din, tx_fifo_din;
    logic [7:0] rx_fifo_dout, tx_fifo_dout;
    logic rx_fifo_wr, tx_fifo_wr;
    logic rx_fifo_rd, tx_fifo_rd;
    logic rx_fifo_full, tx_fifo_full;
    logic rx_fifo_empty, tx_fifo_empty;

    // Register Fields
    logic [2:0] rx_int_conf;
    logic [1:0] tx_int_conf;
    logic sreset; //soft reset
    assign UARTx_data[7:0] = rx_din;
    assign UARTx_data[WIDTH-1:8] = 0;
    assign UARTx_conf[5:0] = {tx_fifo_empty, tx_fifo_full,
                            rx_fifo_empty, rx_fifo_full,
                            tx_busy, rx_busy};
    assign UARTx_conf[7:6] = rx_int_conf;
    assign UARTx_conf[9:8] = tx_int_conf;
    assign UARTx_conf[28:10] = 0;
    assign UARTx_conf[29] = dbg_en;
    assign UARTx_conf[30] = sreset; assign sreset = 0; // not implemented yet
    assign UARTx_conf[31] = rx_err;


    // Connect Debugger Outputs
    assign dbg_recv = rx_recv;
    assign dbg_din = rx_din;
    assign dbg_rx_busy = rx_busy;
    assign dbg_tx_busy = tx_busy;
    // Multiplex TX Inputs
    assign tx_send = (dbg_en) ? dbg_send : tx_fifo_rd;
    assign tx_dout = (dbg_en) ? dbg_dout : tx_fifo_dout;
    // Connect FIFO Inputs
    assign rx_fifo_din = rx_din;
    // tx_fifo_din assigned by AXI write state machine
    assign rx_fifo_wr = (dbg_en) ? 0 : rx_recv;
    assign tx_fifo_rd = (dbg_en) ? 0 : (!tx_busy && !tx_fifo_full); // Feed TX

    // Interrupt Sources
    assign rx_int = (dbg_en) ? 0 : (
                    (rx_int_conf[0] && rx_recv)
                    || (rx_int_conf[1] && rx_fifo_full)
                    || (rx_int_conf[2] && rx_err));
    assign tx_int = (dbg_en) ? 0 : (
                    (tx_int_conf[0] && tx_done)
                    || (tx_int_conf[1] && tx_fifo_empty));


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: RX/TX FIFO
    ////////////////////////////////////////////////////////////
    fifo #(
        .WIDTH(8),
        .DEPTH(FIFO_DEPTH)
    ) rx_fifo (
        .clk(axi.aclk),
        .rst_n(axi.areset_n),
        .wr_en(rx_fifo_wr),
        .din(rx_fifo_din),
        .full(rx_fifo_full),
        .rd_en(rx_fifo_rd),
        .dout(rx_fifo_dout),
        .empty(rx_fifo_empty)
    );
    fifo #(
        .WIDTH(8),
        .DEPTH(FIFO_DEPTH)
    ) tx_fifo (
        .clk(axi.aclk),
        .rst_n(axi.areset_n),
        .wr_en(tx_fifo_wr),
        .din(tx_fifo_din),
        .full(tx_fifo_full),
        .rd_en(tx_fifo_rd),
        .dout(tx_fifo_dout),
        .empty(tx_fifo_empty)
    );
    ////////////////////////////////////////////////////////////
    // END: RX/TX FIFO
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: RX/TX Submodules
    ////////////////////////////////////////////////////////////
    uart_rx #(
        .BUS_CLK(BUS_CLK),
        .BAUD(BAUD)
    ) _rx (
        .clk(axi.aclk),
        .rst_n(axi.areset_n),
        .rx,
        .din(rx_din),
        .busy(rx_busy),
        .recv(rx_recv),
        .err(_rx_err)
    );
    uart_tx #(
        .BUS_CLK(BUS_CLK),
        .BAUD(BAUD)
    ) _tx (
        .clk(axi.aclk),
        .rst_n(axi.areset_n),
        .tx,
        .send(tx_send),
        .dout(tx_dout),
        .busy(tx_busy),
        .done(tx_done)
    );
    ////////////////////////////////////////////////////////////
    // END: RX/TX Submodules
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: AXI Read Channels
    ////////////////////////////////////////////////////////////
    enum {AR_READY, RD_FIFO, R_VALID} rd_state;
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            rd_state    <= AR_READY;
            axi.arready <= 0;
            axi.rvalid  <= 0;
            axi.rresp   <= axi.OKAY;
            rx_fifo_rd  <= 0;
            rx_err      <= 0;
        end
        else begin
            case (rd_state)
                AR_READY: begin // arready asserted, waiting for arvalid
                    if (axi.arvalid) begin
                        rd_state    <= R_VALID;
                        axi.arready <= 0;
                        axi.rvalid  <= 1;
                        axi.rresp   <= (|axi.araddr[1:0]) ? axi.SLVERR : axi.OKAY;
                        _araddr     <= axi.araddr;
                        case (axi.araddr)
                            4'h0: begin
                                rd_state    <= RD_FIFO;
                                rx_fifo_rd  <= 1;
                                axi.rvalid  <= 0;
                            end
                            4'h4: begin
                                axi.rdata   <= UARTx_conf;
                                rx_err      <= 0; // clear sticky bit
                            end
                            default: axi.rdata <= 0;
                        endcase
                    end
                end
                RD_FIFO: begin // Read data from RX FIFO
                    rd_state    <= R_VALID;
                    rx_fifo_rd  <= 0;
                    axi.rvalid  <= 1;
                    axi.rdata   <= rx_fifo_dout;
                end
                R_VALID: begin // rvalid asserted, waiting for rready
                    rx_fifo_rd <= 0;
                    if (axi.rready) begin
                        rd_state    <= AR_READY;
                        axi.arready <= 1;
                        axi.rvalid  <= 0;
                    end
                end
                default: begin // invalid state
                    rd_state    <= AR_READY;
                    rx_fifo_rd  <= 0;
                    axi.arready <= 1;
                    axi.rvalid  <= 0;
                end
            endcase
            if (_rx_err) begin
                // write to sticky bit
                rx_err <= 1;
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: AXI Read Channels
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: AXI Write Channels
    ////////////////////////////////////////////////////////////
    enum {AW_READY, W_READY, B_VALID} wr_state;
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            wr_state    <= AW_READY;
            axi.awready <= 1;
            axi.wready  <= 0;
            axi.bvalid  <= 0;
            axi.bresp   <= axi.OKAY;
            rx_int_conf <= 0;
            tx_int_conf <= 0;
            _awaddr     <= 0;
            tx_fifo_wr  <= 0;
        end
        else begin
            case (wr_state)
                AW_READY: begin // awready asserted, waiting for awvalid
                    if (axi.awvalid) begin
                        wr_state    <= W_READY;
                        axi.awready <= 0;
                        axi.wready  <= 1;
                        _awaddr     <= axi.awaddr;
                    end
                end
                W_READY: begin // wready asserted, waiting for wvalid
                    if (axi.wvalid) begin
                        wr_state    <= B_VALID;
                        axi.wready  <= 0;
                        axi.bvalid  <= 1;
                        axi.bresp   <= axi.OKAY; // default to OKAY
                        case (_awaddr)
                            4'h0: begin
                                tx_fifo_wr  <= 1; // write to TX FIFO
                                tx_fifo_din <= axi.wdata[7:0];
                            end
                            4'h4: begin
                                rx_int_conf <= axi.wdata[8:6];
                                tx_int_conf <= axi.wdata[10:9];
                            end
                            default: axi.bresp <= axi.SLVERR; // address misaligned
                        endcase
                    end
                end
                B_VALID: begin // bvalid asserted, waiting for bready
                    tx_fifo_wr <= 1;
                    if (axi.bready) begin
                        wr_state    <= AW_READY;
                        axi.awready <= 1;
                        axi.bvalid  <= 0;
                    end
                end
                default: begin // invalid state
                    wr_state    <= AW_READY;
                    tx_fifo_wr  <= 0;
                    axi.awready <= 1;
                    axi.wready  <= 0;
                    axi.bvalid  <= 0;
                end
            endcase
        end
    end
    ////////////////////////////////////////////////////////////
    // END: AXI Write Channels
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


endmodule
