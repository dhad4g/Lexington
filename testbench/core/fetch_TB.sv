`timescale 1ns/1ps


module fetch_TB;

    localparam MAX_CYCLES = 128;
    integer clk_count = 0;
    integer fail = 0;
    integer fid;

    parameter WIDTH             = 32;
    parameter ROM_ADDR_WIDTH    = 10;

    reg clk;

    reg  [WIDTH-1:0] pc;
    wire ibus_rd_en;
    wire [ROM_ADDR_WIDTH-1:0] ibus_addr;
    reg  [WIDTH-1:0] ibus_rd_data;
    wire [WIDTH-1:0] inst;

    fetch FetchUnit (
        .pc,
        .ibus_rd_en,
        .ibus_addr,
        .ibus_rd_data,
        .inst(inst)
    );


    // 10 MHz clock
    initial clk = 0;
    initial forever #50 clk = ~clk;

    initial begin
        pc = 0;

        fid = $fopen("fetch.log");
        $dumpfile("fetch.vcd");
        $dumpvars(2, fetch_TB);
    end


    always_comb begin
        ibus_rd_data = ~pc;
    end

    always @(posedge clk) begin
        pc[(ROM_ADDR_WIDTH+2)-1:2] <= $random();
        pc[WIDTH-1:ROM_ADDR_WIDTH+2] <= ($urandom_range(1)) ? $random() : 0;

        $write("clk = %d    pc = 0x%h", clk_count, pc);
        $write("    ibus_rd_data = 0x%h", ibus_rd_data);
        $fwrite(fid,"clk = %d    pc = 0x%h", clk_count, pc);
        $fwrite(fid,"    ibus_rd_data = 0x%h", ibus_rd_data);
        if (ibus_addr != pc[(ROM_ADDR_WIDTH+2)-1:2]) begin
            fail = fail + 1;
            $write("    incorrect ROM address!");
            $fwrite(fid,"    incorrect ROM address!");
        end
        if (inst != ~pc) begin
            fail = fail + 1;
            $write("    incorrect read data!");
            $fwrite(fid,"    incorrect read data!");
        end
        $write("\n");
        $fwrite(fid,"\n");
    end


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