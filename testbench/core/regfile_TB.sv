`timescale 1ns/1ps

module regfile_TB ();

    localparam WIDTH = 32;
    localparam REG_COUNT = 32;
    localparam ADDR_WIDTH = 5;

    localparam MAX_CYCLES = 128;
    integer clk_count = 0;
    integer fail = 0;
    integer fid;

    reg clk;

    reg [ADDR_WIDTH-1:0] rs1_addr;
    reg [ADDR_WIDTH-1:0] rs2_addr;
    reg [ADDR_WIDTH-1:0] dest_addr;
    reg dest_en;

    wire [WIDTH-1:0] rs1_data;
    wire [WIDTH-1:0] rs2_data;
    reg  [WIDTH-1:0] dest_data;

    regfile DUT (
            .clk(clk),
            .rs1_en(1'b1),
            .rs1_addr(rs1_addr),
            .rs1_data(rs1_data),
            .rs2_en(1'b1),
            .rs2_addr(rs2_addr),
            .rs2_data(rs2_data),
            .dest_en(dest_en),
            .dest_addr(dest_addr),
            .dest_data(dest_data)
        );


    // 10 MHz clock
    initial clk = 0;
    initial forever #50 clk = ~clk;

    integer dump_i;
    initial begin
        rs1_addr = 0;
        rs2_addr = 0;
        dest_addr  = 0;
        dest_en    = 1;
        dest_data  = 0;

        fid = $fopen("regfile.log");
        $dumpfile("regfile.vcd");
        $dumpvars(3, regfile_TB);
        $dumpvars(1, DUT.ram[1]);
    end


    reg [WIDTH-1:0] _d1, _d2;
    always @(posedge clk) begin
        rs2_addr <= rs1_addr;
        rs1_addr <= dest_addr;
        dest_addr <= $random();

        _d2 <= _d1;
        if (dest_addr == rs1_addr) begin
            // check for consective writes to same register
            _d2 <= dest_data;
        end
        _d1 <= dest_data;
        if (dest_addr == 0) begin
            // check for special x0 register
            _d1 <= 0;
        end
        dest_data <= $random();
        
        $write("clk = %d    writing 0x%h to x%d", clk_count, dest_data, dest_addr);
        $fwrite(fid,"clk = %d    writing 0x%h to x%d", clk_count, dest_data, dest_addr);
        if (clk_count > 3) begin
            // Read port 1
            $write("    read 0x%h from x%d", rs1_data, rs1_addr);
            $fwrite(fid,"    read 0x%h from x%d", rs1_data, rs1_addr);
            // Read port 2
            $write("    read 0x%h from x%d", rs2_data, rs2_addr);
            $fwrite(fid,"    read 0x%h from x%d", rs2_data, rs2_addr);
            if (rs1_data != _d1 || rs2_data != _d2) begin
                fail = fail + 1;
                $write("    read failed");
                $fwrite(fid,"    read failed");
            end
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