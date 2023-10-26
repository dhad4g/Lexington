`timescale 1ns/1ps


module uart_TB;

    localparam MAX_CYCLES = 4096*128;
    integer clk_count = 0;
    integer fail = 0;
    integer fid;

    // DUT Parameters
    localparam WIDTH        = 32;
    localparam BUS_CLK      = 40_000_000;
    localparam BAUD         = 9600;
    localparam FIFO_DEPTH   = 8;

    localparam AXI_ADDR_WIDTH = 3;

    // DUT Ports
    logic clk;
    logic rst, rst_n;
    logic rx, tx;
    logic rx_int, tx_int;
    logic dbg_en;
    logic dbg_send;
    logic dbg_recv;
    logic [7:0] dbg_din;
    logic [7:0] dbg_dout;
    logic dbg_rx_busy;
    logic dbg_tx_busy;
    axi4_lite #(.WIDTH(WIDTH), .ADDR_WIDTH(AXI_ADDR_WIDTH)) axi();

    assign axi.aclk = clk;
    assign axi.areset_n = rst_n;
    assign rst_n = ~rst;
    assign rx = tx;

    // Instantiate DUT
    uart #(
        .WIDTH(WIDTH),
        .BUS_CLK(BUS_CLK),
        .BAUD(BAUD),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) DUT (
        .rx,
        .tx,
        .rx_int,
        .tx_int,
        .dbg_en,
        .dbg_send,
        .dbg_recv,
        .dbg_dout,
        .dbg_din,
        .dbg_rx_busy,
        .dbg_tx_busy,
        .axi
    );


    // 10 MHz clock
    initial clk = 0;
    initial forever #12.5 clk <= ~clk;

    // Initialize
    initial begin
        dbg_en      <= 1;
        dbg_send    <= 0;
        dbg_dout    <= 0;

        axi.awvalid <= 0;
        axi.awaddr  <= 0;
        axi.awprot  <= 0;
        axi.wvalid  <= 0;
        axi.wdata   <= 0;
        axi.wstrb   <= 0;
        axi.bready  <= 0;
        axi.arvalid <= 0;
        axi.araddr  <= 0;
        axi.arprot  <= 0;
        axi.rready  <= 0;

        // Reset
        rst <= 1;
        #50
        rst <= 0;

        fid = $fopen("uart.log");
        $dumpfile("uart.vcd");
        $dumpvars(4, uart_TB);
    end


    // Stimulus
    // AXI and Interrupt functions not tested
    // Only Debug functions tested
    logic [7:0] _dout;
    always @(posedge clk) begin
        if (!rst) begin
            // TX
            if (!dbg_tx_busy && !dbg_send) begin
                dbg_send <= 1;
                dbg_dout <= $random();
                _dout    <= dbg_dout;
            end
            else begin
                dbg_send <= 0;
            end
            // RX
            if (dbg_recv) begin
                if (dbg_din === _dout) begin
                    $write("Successfully received 0x%x\n", dbg_din);
                    $fwrite(fid,"Successfully received 0x%x\n", dbg_din);
                end
                else begin
                    fail <= fail + 1;
                    $write("FAILED: received 0x%x, but sent 0x%x\n", dbg_din, dbg_dout);
                    $fwrite(fid,"FAILED: received 0x%x, but sent 0x%x\n", dbg_din, dbg_dout);
                end
            end
        end
    end


    // End Simulation
    always @(posedge clk) begin
        clk_count <= clk_count + 1;
        if (clk_count >= MAX_CYCLES) begin
            if (fail) begin
                $write("\n\nFAILED %d tests\n", fail);
                $fwrite(fid,"\n\nFailed %d tests\n", fail);
            end
            else begin
                $write("\n\nPASSED all tests\n");
                $fwrite(fid,"\n\nPASSED all tests\n");
            end
            $fclose(fid);
            $finish();
        end
    end

endmodule