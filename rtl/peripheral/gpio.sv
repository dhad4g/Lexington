`timescale 1ns/1ps

`include "axi4_lite.sv"


module gpio #(
        parameter WIDTH         = 32,       // bus width
        parameter PIN_COUNT     = 16        // number of I/O pins
    ) (

        inout  logic [PIN_COUNT-1:0] io_pins,
        output logic int0,
        output logic int1,

        axi4_lite.subordinate axi

    );

    // AXI registers
    logic [WIDTH-1:0] GPIOx_mode, GPIOx_idata, GPIOx_odata, GPIOx_int_conf;


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: I/O Logic
    ////////////////////////////////////////////////////////////
    assign GPIOx_idata[PIN_COUNT-1:0] = io_pins;
    assign GPIOx_idata[WIDTH-1:PIN_COUNT] = 0;
    generate
        // Output tristate
        genvar i;
        for (i=0; i<PIN_COUNT; i++) begin
            assign io_pins[i] = (GPIOx_mode[i]) ? GPIOx_odata[i] : 1'bz;
        end
    endgenerate
    ////////////////////////////////////////////////////////////
    // END: I/O Logic
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Interrupt Logic
    ////////////////////////////////////////////////////////////
    localparam NUM_INTERRUPTS = 2;
    logic [1:0] interrupts;
    assign int0 = interrupts[0];
    assign int1 = interrupts[1];
    typedef enum logic [2:0] {
        DISABLE = 3'b000,
        RISING  = 3'b100,
        FALLING = 3'b101,
        HIGH    = 3'b110,
        LOW     = 3'b111
    } mode_t;
    mode_t int_mode[2];
    assign int_mode[0] = mode_t'(GPIOx_int_conf[2:0]);
    assign int_mode[1] = mode_t'(GPIOx_int_conf[5:3]);
    logic [4:0] int_pin [1:0];
    assign int_pin[0] = GPIOx_int_conf[10:6];
    assign int_pin[1] = GPIOx_int_conf[15:11];
    // Interrupt state registers
    logic [1:0] startup;    // disable interrupts on first cycle after reset/reconfig
    logic [1:0] prev_mode;  // previous interrupt mode
    logic [1:0] prev_pin;   // previous interrupt pin
    logic [1:0] prev_val;   // previous value of interrupt pin.
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            startup     <= 0;
            interrupts  <= 0;
        end
        else begin
            for (integer i=0; i<NUM_INTERRUPTS; i++) begin
                // default to no interrupt
                interrupts[i] <= 0;
                if (startup[i] && (prev_mode[i] == int_mode[i]) && (prev_pin[i] == int_pin[i])) begin
                    // config is stable
                    if (int_pin[i] < PIN_COUNT) begin
                        case (int_mode[i])
                            RISING:  interrupts[i]  <= GPIOx_idata[int_pin[i]] & ~prev_val[i];
                            FALLING: interrupts[i]  <= ~GPIOx_idata[int_pin[i]] & prev_val[i];
                            HIGH:    interrupts[i]  <= GPIOx_idata[int_pin[i]];
                            LOW:     interrupts[i]  <= ~GPIOx_idata[int_pin[i]];
                            default: interrupts[i]  <= 0;
                        endcase
                    end
                end
                // Store previous values
                prev_mode[i] <= int_mode[i];
                prev_pin[i]  <= int_pin[i];
                if (prev_pin[i] < PIN_COUNT) begin
                    prev_val[i] <= GPIOx_idata[int_pin[i]];
                end
                startup <= 1;
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Interrupt Logic
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Read Channels
    ////////////////////////////////////////////////////////////
    logic [3:0] _araddr;
    enum {AR_READY, R_VALID} rd_state;
    // read state machine
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            rd_state    <= AR_READY;
            _araddr     <= 0;
            axi.arready <= 1;
            axi.rvalid  <= 0;
            axi.rresp   <= axi.OKAY;
        end
        else begin
            case (rd_state)
                AR_READY: begin // arready asserted, waiting for arvalid
                    if (axi.arvalid) begin
                        rd_state    <= R_VALID;
                        axi.arready <= 0;
                        axi.rvalid  <= 1;
                        _araddr     <= axi.araddr;
                        axi.rresp   <= (|_araddr[1:0]) ? axi.SLVERR : axi.OKAY;
                    end
                end
                R_VALID: begin // rvalid asserted, waiting for rready
                    if (axi.rready) begin
                        rd_state    <= AR_READY;
                        axi.arready <= 1;
                        axi.rvalid  <= 0;
                    end
                end
                default: begin // invalid state
                    rd_state    <= AR_READY;
                    axi.arready <= 1;
                    axi.rvalid  <= 0;
                end
            endcase
        end
    end
    // decode read address
    always_comb begin
        case (_araddr)
            4'h0: axi.rdata = GPIOx_mode;
            4'h4: axi.rdata = GPIOx_idata;
            4'h8: axi.rdata = GPIOx_odata;
            4'hC: axi.rdata = GPIOx_int_conf;
            default: axi.rdata = 0;
        endcase
    end
    ////////////////////////////////////////////////////////////
    // END: Read Channels
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Write Channels
    ////////////////////////////////////////////////////////////
    logic [3:0] _awaddr;
    enum {AW_READY, W_READY, B_VALID} wr_state;
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            wr_state    <= AW_READY;
            _awaddr     <= 0;
            axi.awready <= 1;
            axi.wready  <= 0;
            axi.bvalid  <= 0;
            axi.bresp   <= axi.OKAY;
            GPIOx_mode  <= 0;
            GPIOx_odata <= 0;
            GPIOx_int_conf <= 0;
        end
        else begin
            case (wr_state)
                AW_READY: begin // awready asserted, waiting for awvalid
                    if (axi.awvalid) begin
                        wr_state    <= W_READY;
                        _awaddr     <= axi.awaddr;
                        axi.awready <= 0;
                        axi.wready  <= 1;
                    end
                end
                W_READY: begin // wready asserted, waiting for wvalid
                    if (axi.wvalid) begin
                        wr_state    <= B_VALID;
                        axi.wready  <= 0;
                        axi.bvalid  <= 1;
                        // default to OKAY response
                        axi.bresp   <= axi.OKAY;
                        case (_awaddr)
                            4'h0: GPIOx_mode    <= axi.wdata;
                            4'h4: axi.bresp     <= axi.SLVERR; // read-only
                            4'h8: GPIOx_odata   <= axi.wdata;
                            4'hC: GPIOx_int_conf<= axi.wdata;
                            default: axi.bresp  <= axi.SLVERR; // address misaligned
                        endcase
                    end
                end
                B_VALID: begin // bvalid asserted, waiting for bready
                    if (axi.bready) begin
                        wr_state    <= AW_READY;
                        axi.awready <= 1;
                        axi.bvalid  <= 0;
                    end
                end
                default: begin // invalid state
                    wr_state    <= AW_READY;
                    axi.awready <= 1;
                    axi.wready  <= 0;
                    axi.bvalid  <= 0;
                end
            endcase
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Write Channels
    ////////////////////////////////////////////////////////////

endmodule
