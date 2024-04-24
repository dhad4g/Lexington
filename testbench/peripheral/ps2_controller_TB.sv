`timescale 1ns/1ps


module gpio_TB;

    localparam CLK_PERIOD = 10;

    localparam MAX_CYCLES = 128;
    integer clk_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;

    // DUT Ports
    logic clk;
    logic rst, rst_n;
    logic ps2_clk;
    logic ps2_data;
    logic [7:0] data;
    logic valid;
    logic err;


    assign rst_n = ~rst;

    // Instantiate DUT
    ps2_controller DUT (
        .clk, // no parenthesis automatically connects to signal of the same name
        .rst_n,
        .ps2_clk,
        .ps2_data,
        .data,
        .valid,
        .err
    );


    // 100 MHz clock
    initial clk = 1;
    initial forever #(CLK_PERIOD/2) clk <= ~clk;

    // Initialize
    initial begin

        ps2_clk  <= 1; // idle high
        ps2_data <= 0;

        fid = $fopen("ps2_controller.log");
        $dumpfile("ps2_controller.vcd");
        $dumpvars(3, ps2_controller_TB);

        // Reset
        rst <= 1;
        #(2*CLK_PERIOD);
        rst <= 0;
    end



    // Stimulus
    integer i;
    logic [7:0] _data;
    initial begin
        #(4*CLK_PERIOD) // wait for reset

        while (1) begin

            // Choice data to send
            _data = $random();
            $write("%3d:    Sending 0x%02X ...");
            $fwrite(fid,"%3d:    Sending 0x%02X ...");

            // Start bit
            ps2_data <= 0;
            #(4*CLK_PERIOD);
            ps2_clk  <= 0;
            #(4*CLK_PERIOD);
            ps2_clk  <= 1

            // Data bits
            for (i=0; i<8; i++) begin

                // TODO

                $write("%b", _data[i]);
                $fwrite(fid,"%b", _data[i]);
            end

            // Parity bit (odd parity)
            ps2_data <= !(^ _data); // use XOR reduction operator
            #(4*CLK_PERIOD);
            ps2_clk  <= 0;
            #(4*CLK_PERIOD);
            ps2_clk  <= 1;

            // Stop bit
            ps2_data <= 1;
            #(4*CLK_PERIOD);
            ps2_clk  <= 0;
            while (!valid) #CLK_PERIOD; // wait for valid
            $write("    received 0x%02X", data);
            $fwrite(fid,"    received 0x%02X", data);

            // Verify
            if (err) begin
                fail_count++;
                $write("        FAIL error flag asserted");
                $fwrite(fid,"        FAIL error flag asserted");
            end
            else if (_data != data) begin
                $write("        FAIL data doesn't match");
                $fwrite(fid,"        FAIL data doesn't match");
                fail_count++;
            end
            else begin
                pass_count++;
            end
            $write("\n");
            $fwrite(fid,"\n");

            #(4*CLK_PERIOD);
            ps2_clk <= 1;
            #(8*CLK_PERIOD);

        end
    end


    // End Simulation
    always @(posedge clk) begin
        clk_count <= clk_count + 1;
        if (clk_count >= MAX_CYCLES) begin
            if (fail_count || (!pass_count)) begin
                $write("\n\nFAILED!    %3d/%3d\n", fail_count, fail_count+pass_count);
                $fwrite(fid,"\n\nFailed!    %3d/%3d\n", fail_count, fail_count+pass_count);
            end
            else begin
                $write("\n\nPASSED all %3d tests\n", pass_count);
                $fwrite(fid,"\n\nPASSED all %3d tests\n", pass_count);
            end
            $fclose(fid);
            $finish();
        end
    end

endmodule
