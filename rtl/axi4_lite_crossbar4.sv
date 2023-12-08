`timescale 1ns/1ps

`include "axi4_lite.sv"


module axi4_lite_crossbar4 #(
        parameter WIDTH             = 32,               // data bus width
        parameter ADDR_WIDTH        = 32,               // upstream manager address width
        parameter S00_ADDR_WIDTH    = 4,                // Subordinate 0 address width
        parameter S01_ADDR_WIDTH    = 4,                // Subordinate 1 address width
        parameter S02_ADDR_WIDTH    = 4,                // Subordinate 2 address width
        parameter S03_ADDR_WIDTH    = 4,                // Subordinate 3 address width
        parameter S00_BASE_ADDR     = 'h00,             // Subordinate 0 base address
        parameter S01_BASE_ADDR     = 'h10,             // Subordinate 1 base address
        parameter S02_BASE_ADDR     = 'h20,             // Subordinate 2 base address
        parameter S03_BASE_ADDR     = 'h30              // Subordinate 3 base address
    ) (
        axi4_lite.subordinate axi_m,
        axi4_lite.manager axi_s00,
        axi4_lite.manager axi_s01,
        axi4_lite.manager axi_s02,
        axi4_lite.manager axi_s03
    );

    localparam COUNT = 4;

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
    always_comb begin
        if (!axi_m.areset_n) begin
            wr_active = 0;
            rd_active = 0;
        end
        else begin
            wr_active[0] = (S00_BASE_ADDR == mask_upper_bits(_awaddr, S00_ADDR_WIDTH));
            wr_active[1] = (S01_BASE_ADDR == mask_upper_bits(_awaddr, S01_ADDR_WIDTH));
            wr_active[2] = (S02_BASE_ADDR == mask_upper_bits(_awaddr, S02_ADDR_WIDTH));
            wr_active[3] = (S03_BASE_ADDR == mask_upper_bits(_awaddr, S03_ADDR_WIDTH));
            rd_active[0] = (S00_BASE_ADDR == mask_upper_bits(_araddr, S00_ADDR_WIDTH));
            rd_active[1] = (S01_BASE_ADDR == mask_upper_bits(_araddr, S01_ADDR_WIDTH));
            rd_active[2] = (S02_BASE_ADDR == mask_upper_bits(_araddr, S02_ADDR_WIDTH));
            rd_active[3] = (S03_BASE_ADDR == mask_upper_bits(_araddr, S03_ADDR_WIDTH));
        end
    end


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
    //////////////////////////////////////////////////
    // axi_s00
    // axi_s00 global signals
    assign axi_s00.aclk         = axi_m.aclk;
    assign axi_s00.areset_n     = axi_m.areset_n;
    // axi_s00 write address channel
    assign axi_s00.awaddr       = axi_m.awaddr;
    assign axi_s00.awprot       = axi_m.awprot;
    // axi_s00 write data channel
    assign axi_s00.wdata        = axi_m.wdata;
    assign axi_s00.wstrb        = axi_m.wstrb;
    // axi_s00 read address
    assign axi_s00.araddr       = axi_m.araddr;
    assign axi_s00.arprot       = axi_m.arprot;
    //////////////////////////////////////////////////
    // axi_s01
    // axi_s01 global signals
    assign axi_s01.aclk         = axi_m.aclk;
    assign axi_s01.areset_n     = axi_m.areset_n;
    // axi_s01 write address channel
    assign axi_s01.awaddr       = axi_m.awaddr;
    assign axi_s01.awprot       = axi_m.awprot;
    // axi_s01 write data channel
    assign axi_s01.wdata        = axi_m.wdata;
    assign axi_s01.wstrb        = axi_m.wstrb;
    // axi_s01 read address
    assign axi_s01.araddr       = axi_m.araddr;
    assign axi_s01.arprot       = axi_m.arprot;
    //////////////////////////////////////////////////
    // axi_s02
    // axi_s02 global signals
    assign axi_s02.aclk         = axi_m.aclk;
    assign axi_s02.areset_n     = axi_m.areset_n;
    // axi_s02 write address channel
    assign axi_s02.awaddr       = axi_m.awaddr;
    assign axi_s02.awprot       = axi_m.awprot;
    // axi_s02 write data channel
    assign axi_s02.wdata        = axi_m.wdata;
    assign axi_s02.wstrb        = axi_m.wstrb;
    // axi_s02 read address
    assign axi_s02.araddr       = axi_m.araddr;
    assign axi_s02.arprot       = axi_m.arprot;
    //////////////////////////////////////////////////
    // axi_s03
    // axi_s03 global signals
    assign axi_s03.aclk         = axi_m.aclk;
    assign axi_s03.areset_n     = axi_m.areset_n;
    // axi_s03 write address channel
    assign axi_s03.awaddr       = axi_m.awaddr;
    assign axi_s03.awprot       = axi_m.awprot;
    // axi_s03 write data channel
    assign axi_s03.wdata        = axi_m.wdata;
    assign axi_s03.wstrb        = axi_m.wstrb;
    // axi_s03 read address
    assign axi_s03.araddr       = axi_m.araddr;
    assign axi_s03.arprot       = axi_m.arprot;


    // Connect multiplexed signals
    // axi_m
    always_comb begin
        case (wr_active)
            'b0001: begin
                axi_m.awready   = axi_s00.awready;
                axi_m.wready    = axi_s00.wready;
                axi_m.bvalid    = axi_s00.bvalid;
                axi_m.bresp     = axi_s00.bresp;
            end
            'b0010: begin
                axi_m.awready   = axi_s01.awready;
                axi_m.wready    = axi_s01.wready;
                axi_m.bvalid    = axi_s01.bvalid;
                axi_m.bresp     = axi_s01.bresp;
            end
            'b0100: begin
                axi_m.awready   = axi_s02.awready;
                axi_m.wready    = axi_s02.wready;
                axi_m.bvalid    = axi_s02.bvalid;
                axi_m.bresp     = axi_s02.bresp;
            end
            'b1000: begin
                axi_m.awready   = axi_s03.awready;
                axi_m.wready    = axi_s03.wready;
                axi_m.bvalid    = axi_s03.bvalid;
                axi_m.bresp     = axi_s03.bresp;
            end
            default: begin
                axi_m.awready   = 0;
                axi_m.wready    = 0;
                axi_m.bvalid    = 0;
                axi_m.bresp     = axi_m.DECERR;
            end
        endcase
        case (rd_active)
            'b0001: begin
                axi_m.arready   = axi_s00.arready;
                axi_m.rvalid    = axi_s00.rvalid;
                axi_m.rdata     = axi_s00.rdata;
                axi_m.rresp     = axi_s00.rresp;
            end
            'b0010: begin
                axi_m.arready   = axi_s01.arready;
                axi_m.rvalid    = axi_s01.rvalid;
                axi_m.rdata     = axi_s01.rdata;
                axi_m.rresp     = axi_s01.rresp;
            end
            'b0100: begin
                axi_m.arready   = axi_s02.arready;
                axi_m.rvalid    = axi_s02.rvalid;
                axi_m.rdata     = axi_s02.rdata;
                axi_m.rresp     = axi_s02.rresp;
            end
            'b1000: begin
                axi_m.arready   = axi_s03.arready;
                axi_m.rvalid    = axi_s03.rvalid;
                axi_m.rdata     = axi_s03.rdata;
                axi_m.rresp     = axi_s03.rresp;
            end
            default: begin
                axi_m.arready   = 0;
                axi_m.rvalid    = 0;
                axi_m.rdata     = 0;
                axi_m.rresp     = axi_m.DECERR;
            end
        endcase
    end
    // axi_s00
    assign axi_s00.awvalid      = (wr_active[0]) ? axi_m.awvalid : 0;
    assign axi_s00.wvalid       = (wr_active[0]) ? axi_m.wvalid : 0;
    assign axi_s00.bready       = (wr_active[0]) ? axi_m.bready : 0;
    assign axi_s00.arvalid      = (rd_active[0]) ? axi_m.arvalid : 0;
    assign axi_s00.rready       = (rd_active[0]) ? axi_m.rready : 0;
    // axi_s01
    assign axi_s01.awvalid      = (wr_active[1]) ? axi_m.awvalid : 0;
    assign axi_s01.wvalid       = (wr_active[1]) ? axi_m.wvalid : 0;
    assign axi_s01.bready       = (wr_active[1]) ? axi_m.bready : 0;
    assign axi_s01.arvalid      = (rd_active[1]) ? axi_m.arvalid : 0;
    assign axi_s01.rready       = (rd_active[1]) ? axi_m.rready : 0;
    // axi_s02
    assign axi_s02.awvalid      = (wr_active[2]) ? axi_m.awvalid : 0;
    assign axi_s02.wvalid       = (wr_active[2]) ? axi_m.wvalid : 0;
    assign axi_s02.bready       = (wr_active[2]) ? axi_m.bready : 0;
    assign axi_s02.arvalid      = (rd_active[2]) ? axi_m.arvalid : 0;
    assign axi_s02.rready       = (rd_active[2]) ? axi_m.rready : 0;
    // axi_s03
    assign axi_s03.awvalid      = (wr_active[3]) ? axi_m.awvalid : 0;
    assign axi_s03.wvalid       = (wr_active[3]) ? axi_m.wvalid : 0;
    assign axi_s03.bready       = (wr_active[3]) ? axi_m.bready : 0;
    assign axi_s03.arvalid      = (rd_active[3]) ? axi_m.arvalid : 0;
    assign axi_s03.rready       = (rd_active[3]) ? axi_m.rready : 0;


endmodule
