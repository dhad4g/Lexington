`timescale 1ns/1ps

`include "axi4_lite.sv"


module axi4_lite_crossbar #(
        parameter WIDTH         = 32,               // data bus width
        parameter ADDR_WIDTH    = 32,               // upstream manager address width
        parameter COUNT         = 2,                // number of downstream subordinates
        // array of downstream subordinate address width
        parameter integer S_ADDR_WIDTH[COUNT] = {4, 4},
        // array of downstream subordinate base addresses
        parameter integer S_BASE_ADDR[COUNT]  = {'h00, 'h10}
    ) (
        axi4_lite.subordinate axi_m,
        axi4_lite.manager axi_sx[COUNT]
    );

    // Address space mask function
    function automatic logic [ADDR_WIDTH-1:0] mask_upper_bits(logic [ADDR_WIDTH-1:0] addr, integer bit_width);
        logic [ADDR_WIDTH-1:0] mask;
        mask = (~(0)) << bit_width;
        return mask & addr;
    endfunction

    logic [ADDR_WIDTH-1:0] _awaddr;     // latched write address
    logic [ADDR_WIDTH-1:0] _araddr;     // latched read address
    logic [COUNT-1:0] wr_active;        // one-hot write transaction select
    logic [COUNT-1:0] rd_active;        // one-hot read transaction select


    // Decode addresses
    generate
        for (genvar i=0; i<COUNT; i++) begin
            logic [ADDR_WIDTH-1:0] _base_addr;
            assign _base_addr = S_BASE_ADDR[i]; // truncate/extend to correct address width
            always_comb begin
                if (!axi_m.areset_n) begin
                    wr_active[i] = 0;
                    rd_active[i] = 0;
                end
                else begin
                    wr_active[i] = (_base_addr == mask_upper_bits(_awaddr, S_ADDR_WIDTH[i]));
                    rd_active[i] = (_base_addr == mask_upper_bits(_araddr, S_ADDR_WIDTH[i]));
                end
            end
        end
    endgenerate


    // Latch addresses
    always_latch begin
        if (!axi_m.areset_n) begin
            _awaddr <= 0;
            _araddr <= 0;
        end
        else begin
            if (axi_m.awvalid) begin
                _awaddr <= axi_m.awaddr;
            end
            if (axi_m.arvalid) begin
                _araddr <= axi_m.araddr;
            end
        end
    end


    // Connect shared signals
    generate
        for (genvar i=0; i<COUNT; i++) begin
            // global signals
            assign axi_sx[i].aclk       = axi_m.aclk;
            assign axi_sx[i].areset_n   = axi_m.areset_n;
            // write address
            assign axi_sx[i].awaddr     = axi_m.awaddr;
            assign axi_sx[i].awprot     = axi_m.awprot;
            // write data
            assign axi_sx[i].wdata      = axi_m.wdata;
            assign axi_sx[i].wstrb      = axi_m.wstrb;
            // read address
            assign axi_sx[i].araddr     = axi_m.araddr;
            assign axi_sx[i].arprot     = axi_m.arprot;
        end
    endgenerate


    // Connect multiplexed signals
    // wor type: logic or of all drivers
    wor _awready;
    wor _wready;
    wor _bvalid;
    wor [1:0] _bresp;
    wor _arready;
    wor _rvalid;
    wor [WIDTH-1:0] _rdata;
    wor [1:0] _rresp;
    assign axi_m.awready    = _awready;
    assign axi_m.wready     = _wready;
    assign axi_m.bvalid     = _bvalid;
    assign axi_m.bresp      = _bresp;
    assign axi_m.arready    = _arready;
    assign axi_m.rvalid     = _rvalid;
    assign axi_m.rdata      = _rdata;
    assign axi_m.rresp      = _rresp;
    generate
        // this works for simulation, but not synthesis
        for (genvar i=0; i<COUNT; i++) begin
            // write address
            assign axi_sx[i].awvalid    = (wr_active[i]) ? axi_m.awvalid : 0;
            assign _awready             = (wr_active[i]) ? axi_sx[i].awready : 0;
            // write data
            assign axi_sx[i].wvalid     = (wr_active[i]) ? axi_m.wvalid : 0;
            assign _wready              = (wr_active[i]) ? axi_sx[i].wready : 0;
            // write response
            assign _bvalid              = (wr_active[i]) ? axi_sx[i].bvalid : 0;
            assign axi_sx[i].bready     = (wr_active[i]) ? axi_m.bready : 0;
            assign _bresp               = (wr_active[i]) ? axi_sx[i].bresp : axi_m.DECERR;
            // read address
            assign axi_sx[i].arvalid    = (rd_active[i]) ? axi_m.arvalid : 0;
            assign _arready             = (rd_active[i]) ? axi_sx[i].arready : 0;
            // read data
            assign _rvalid              = (rd_active[i]) ? axi_sx[i].rvalid : 0;
            assign axi_sx[i].rready     = (rd_active[i]) ? axi_m.rready : 0;
            assign _rdata               = (rd_active[i]) ? axi_sx[i].rdata : 0;
            assign _rresp               = (rd_active[i]) ? axi_sx[i].rresp : axi_m.DECERR;
        end
    endgenerate


endmodule
