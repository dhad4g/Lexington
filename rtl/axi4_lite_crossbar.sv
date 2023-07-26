`timescale 1ns/1ps

`include "axi4_lite.sv"


module axi4_lite_crossbar #(
        parameter WIDTH         = 32,               // data bus width
        parameter ADDR_WIDTH    = 32,               // upstream manager address width
        parameter COUNT         = 2,                // number of downstream subordinates
        // array of downstream subordinate address widths
        parameter integer S_ADDR_WIDTH[COUNT-1:0] = {4, 4},
        // array of downstream subordinate base addresses
        parameter integer S_BASE_ADDR[COUNT-1:0] = {'h00, 'h01}
    ) (
        axi4_lite.subordinate axi_s,
        axi4_lite.manager axi_mx[COUNT-1:0]
    );

    // Address space mask function
    function automatic logic [ADDR_WIDTH-1:0] mask_upper_bits(logic [ADDR_WIDTH-1:0] addr, integer bit_width);
        logic [ADDR_WIDTH-1:0] mask;
        mask = (~(0)) << bit_width;
        return mask & addr;
    endfunction

    logic [WIDTH-1:0] _wdata;           // latched write data
    logic [ADDR_WIDTH-1:0] _awaddr;     // latched write address
    logic [ADDR_WIDTH-1:0] _araddr;     // latched read address
    logic [COUNT-1:0] wr_active;        // one-hot write transaction select
    logic [COUNT-1:0] rd_active;        // one-hot read transaction select


    // Decode addresses
    generate
        for (genvar i=0; i<COUNT; i++) begin
            always_comb begin
                if (!axi_s.areset_n) begin
                    wr_active[i] = 0;
                    rd_active[i] = 0;
                end
                else begin
                    wr_active[i] = (S_BASE_ADDR[i] == mask_upper_bits(_awaddr, S_ADDR_WIDTH[i]));
                    rd_active[i] = (S_BASE_ADDR[i] == mask_upper_bits(_araddr, S_ADDR_WIDTH[i]));
                end
            end
        end
    endgenerate


    // Latch addresses and wdata
    always_latch begin
        if (axi_s.awvalid) begin
            _awaddr <= axi_s.awaddr;
        end
        if (axi_s.arvalid) begin
            _araddr <= axi_s.araddr;
        end
        if (axi_s.wvalid) begin
            _wdata <= axi_s.wdata;
        end
    end


    // Connect shared signals
    generate
        for (genvar i=0; i<COUNT; i++) begin
            // global signals
            assign axi_mx[i].aclk       = axi_s.aclk;
            assign axi_mx[i].areset_n   = axi_s.areset_n;
            // write address
            assign axi_mx[i].awaddr     = axi_s.awaddr;
            assign axi_mx[i].awprot     = axi_s.awprot;
            // write data
            assign axi_mx[i].wstrb      = axi_s.wstrb;
            // read address
            assign axi_mx[i].araddr     = axi_s.araddr;
            assign axi_mx[i].arprot     = axi_s.arprot;
        end
    endgenerate


    // Connect multiplexed signals
    generate
        for (genvar i=0; i<COUNT; i++) begin
            // write address
            assign axi_mx[i].awvalid    = (wr_active[i]) ? axi_s.awvalid : 0;
            assign axi_s.awready        = (wr_active[i]) ? axi_mx[i].awready : 'z;
            // write data
            assign axi_mx[i].wvalid     = (wr_active[i]) ? axi_s.wvalid : 0;
            assign axi_s.wready         = (wr_active[i]) ? axi_mx[i].wready : 'z;
            // write response
            assign axi_s.bvalid         = (wr_active[i]) ? axi_mx[i].bvalid : 'z;
            assign axi_mx[i].bready     = (wr_active[i]) ? axi_s.bready : 0;
            assign axi_s.bresp          = (wr_active[i]) ? axi_mx[i].bresp : 'z;
            // read address
            assign axi_mx[i].arvalid    = (rd_active[i]) ? axi_s.arvalid : 0;
            assign axi_s.arready        = (rd_active[i]) ? axi_mx[i].arready : 'z;
            // read data
            assign axi_s.rvalid         = (rd_active[i]) ? axi_mx[i].rvalid : 'z;
            assign axi_mx[i].rready     = (rd_active[i]) ? axi_s.rready : 0;
            assign axi_s.rdata          = (rd_active[i]) ? axi_mx[i].rdata : 'z;
            assign axi_s.rresp          = (rd_active[i]) ? axi_mx[i].rresp : 'z;
        end
    endgenerate


endmodule
