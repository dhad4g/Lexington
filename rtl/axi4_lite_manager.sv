`timescale 1ns/1ps

`include "rv32.sv"
`include "lexington.sv"
`include "axi4_lite.sv"
import lexington::*;


module axi4_lite_manager #(
        parameter ADDR_WIDTH    = DEFAULT_AXI_ADDR_WIDTH,   // address bus width
        parameter TIMEOUT       = DEFAULT_AXI_TIMEOUT       // bus timeout in number of cycles
    ) (
        input logic clk,
        input logic rst_n,

        input logic rd_en,
        input logic wr_en,
        input logic [ADDR_WIDTH-1:0] addr,
        input rv32::word wr_data,
        input logic [(rv32::XLEN/8)-1:0] wr_strobe,

        output rv32::word rd_data,
        output logic access_fault,
        output logic busy,

        axi4_lite.manager axi
    );

    logic rd_busy, wr_busy;
    assign busy = rd_busy | wr_busy;

    logic rd_fault, wr_fault;
    assign access_fault = rd_fault | wr_fault;

    assign axi.aclk = clk;
    assign axi.areset_n = rst_n;


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Read channels
    ////////////////////////////////////////////////////////////
    integer rd_timer;
    enum {R_IDLE, AR_VALID, R_READY} rd_state;
    assign axi.arprot.privileged = 1;
    assign axi.arprot.non_secure = 0;
    assign axi.arprot.inst_data_n = 0;
    assign axi.araddr = addr;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rd_state <= R_IDLE;
            rd_timer <= 0;
        end
        else begin
            case (rd_state)
                R_IDLE: begin // first clock cycle of instruction
                    if (rd_en) begin
                        rd_state <= (axi.arready) ? R_READY : AR_VALID;
                        rd_timer <= 0;
                    end
                end
                AR_VALID: begin // ar_valid asserted, waiting for ar_ready
                    rd_timer <= rd_timer + 1;
                    if (rd_timer >= TIMEOUT) begin
                        rd_state <= R_IDLE;
                    end
                    else if (axi.arready) begin
                        rd_state <= R_READY;
                    end
                end
                R_READY: begin // r_ready asserted, waiting for r_valid
                    rd_timer <= rd_timer + 1;
                    if (rd_timer >= TIMEOUT) begin
                        rd_state <= R_IDLE;
                    end
                    else if (axi.rvalid) begin
                        rd_state <= R_IDLE;
                    end
                end
                default: begin // error
                    rd_state <= R_IDLE;
                end
            endcase
        end
    end
    always_comb begin
        if (!rst_n) begin
            rd_busy     = 0;
            axi.arvalid = 0;
            axi.rready  = 0;
            rd_fault    = 0;
        end
        else begin
            case (rd_state)
                R_IDLE: begin // first clock cycle of instruction
                    rd_busy     = rd_en;
                    axi.arvalid = rd_en;
                    axi.rready  = 0;
                    rd_fault    = 0;
                end
                AR_VALID: begin // ar_valid asserted, waiting for ar_ready
                    rd_busy     = 1;
                    axi.arvalid = 1;
                    axi.rready  = 0;
                    rd_fault    = (rd_timer >= TIMEOUT);
                end
                R_READY: begin // r_ready asserted, waiting for r_valid
                    rd_busy     = ~axi.rvalid;
                    axi.arvalid = 0;
                    axi.rready  = 1;
                    rd_fault    = (rd_timer >= TIMEOUT) | (axi.rresp != axi.rresp.OKAY);
                end
                default: begin // error
                    rd_busy     = 0;
                    axi.arvalid = 0;
                    axi.rready  = 0;
                    rd_fault    = 1;
                end
            endcase
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Read Channels
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Write Channels
    ////////////////////////////////////////////////////////////
    integer wr_timer;
    enum {W_IDLE, AWW_VALID, AW_VALID, W_VALID, B_READY} wr_state;
    assign axi.awprot.privileged = 1;
    assign axi.awprot.non_secure = 0;
    assign axi.awprot.inst_data_n = 0;
    assign axi.awaddr = addr;
    assign axi.wstrb = wr_strobe;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_state <= W_IDLE;
            wr_timer <= 0;
        end
        else begin
            case (wr_state)
                W_IDLE: begin // first cycle of instruction
                    if (wr_en) begin
                        case ({axi.awready, axi.wready})
                            'b00: wr_state <= AWW_VALID;
                            'b01: wr_state <= AW_VALID;
                            'b10: wr_state <= W_VALID;
                            'b11: wr_state <= B_READY;
                        endcase
                        wr_timer <= 0;
                    end
                end
                AWW_VALID: begin // awvalid and wvalid asserted, waiting for awready and wready
                    case ({axi.awready, axi.wready})
                        'b00: wr_state <= AWW_VALID;
                        'b01: wr_state <= AW_VALID;
                        'b10: wr_state <= W_VALID;
                        'b11: wr_state <= B_READY;
                    endcase
                end
                AW_VALID: begin // awvalid asserted, waiting for awready, write channel already complete
                    if (axi.awready) begin
                        wr_state <= B_READY;
                    end
                end
                W_VALID: begin // wvalid asserted, waiting for wready, write address channel already complete
                    if (axi.wready) begin
                        wr_state <= B_READY;
                    end
                end
                B_READY: begin // b_ready asserted, waiting for bvalid
                    if (axi.bvalid) begin
                        wr_state <= W_IDLE;
                    end
                end
                default: begin // error
                    wr_state <= W_IDLE;
                end
            endcase
            if (wr_state != W_IDLE) begin
                wr_timer <= wr_timer + 1;
                if (wr_timer >= TIMEOUT) begin
                    // timer overrides state transitions
                    wr_state <= W_IDLE;
                end
            end
        end
    end
    always_comb begin
        if (!rst_n) begin
        end
        else begin
            case (wr_state)
                W_IDLE: begin // first cycle of instruction
                    wr_busy     = wr_en;
                    axi.awvalid = wr_en;
                    axi.wvalid  = wr_en;
                    axi.bready  = 0;
                    wr_fault    = 0;
                end
                AWW_VALID: begin // awvalid and wvalid asserted, waiting for awready and wready
                    wr_busy     = 1;
                    axi.awvalid = 1;
                    axi.wvalid  = 1;
                    axi.bready  = 0;
                    wr_fault    = 0;
                end
                AW_VALID: begin // awvalid asserted, waiting for awready, write channel already complete
                    wr_busy     = 1;
                    axi.awvalid = 1;
                    axi.wvalid  = 0;
                    axi.bready  = 0;
                    wr_fault    = 0;
                end
                W_VALID: begin // wvalid asserted, waiting for wready, write address channel already complete
                    wr_busy     = 1;
                    axi.awvalid = 0;
                    axi.wvalid  = 1;
                    axi.bready  = 0;
                    wr_fault    = 0;
                end
                B_READY: begin // b_ready asserted, waiting for bvalid
                    wr_busy     = ~axi.bvalid;
                    axi.awvalid = 0;
                    axi.wvalid  = 0;
                    axi.bready  = 1;
                    wr_fault    = (axi.bresp != axi.bresp.OKAY);
                end
                default: begin // error
                    wr_busy     = 0;
                    axi.awvalid = 0;
                    axi.wvalid  = 0;
                    axi.bready  = 0; 
                    wr_fault    = 1;
                end
            endcase
            if ( (wr_state != W_IDLE) && (wr_timer >= TIMEOUT)) begin
                // timeout overrides wr_fault
                wr_fault = 1;
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Write Channels
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

endmodule
