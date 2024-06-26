//cmd cd ${PROJ_DIR}/sw/projects/blink && make build dump
//cmd cp ${PROJ_DIR}/sw/projects/blink/rom.hex .
`timescale 1ns/1ps


module soc_TB;

    localparam CLK_PERIOD = 100;
    localparam CYCLES_PER_MILLI = 1_000_000 / CLK_PERIOD;
    localparam SIM_MILLIS = 1;

    localparam MAX_CYCLES = SIM_MILLIS * CYCLES_PER_MILLI;
    integer clk_count = 0;
    integer fail = 0;
    integer fid;

    // DUT Parameters
    localparam UART0_BAUD           = 9600;
    localparam UART0_FIFO_DEPTH     = 8;

    // DUT Ports
    logic clk;
    logic rst, rst_n;
    wire  [15:0] gpioa, gpiob, gpioc;
    logic uart0_rx;
    logic uart0_tx;

    assign rst_n = ~rst;

    // Instantiate DUT
    soc #(
        .UART0_BAUD(UART0_BAUD),
        .UART0_FIFO_DEPTH(UART0_FIFO_DEPTH)
    ) DUT (
        .clk,
        .rst_n,
        .gpioa,
        .gpiob,
        .gpioc,
        .uart0_rx,
        .uart0_tx
    );


    // 10 MHz clock
    initial clk = 0;
    initial forever #(CLK_PERIOD/2) clk = ~clk;

    // Initialize
    initial begin

        rst = 1;
        #200;
        rst = 0;

        fid = $fopen("soc.log");
        $dumpfile("soc.vcd");
        $dumpvars(5, soc_TB);
    end


    // Stimulus
    integer millis = 0;
    initial forever begin
        $write("%1d/%1d ms\n", millis, SIM_MILLIS);
        millis++;
        #(CYCLES_PER_MILLI * CLK_PERIOD);
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
