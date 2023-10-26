`timescale 1ns/1ps


module template_TB;

    localparam MAX_CYCLES = 32;
    integer clk_count = 0;
    integer fail = 0;
    integer fid;

    // DUT Parameters

    // DUT Ports
    logic clk;
    logic rst, rst_n;

    assign rst_n = ~rst;

    // Instantiate DUT
    template #(
        .PARAM(PARAM)
    ) DUT (
        .clk,
        .rst_n
    );


    // 10 MHz clock
    initial clk = 0;
    initial forever #50 clk = ~clk;

    // Initialize
    initial begin

        fid = $fopen("template.log");
        $dumpfile("template.vcd");
        $dumpvars(2, template_TB);
    end


    // Stimulus
    always @(posedge clk) begin
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