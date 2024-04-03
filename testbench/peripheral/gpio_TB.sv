`timescale 1ns/1ps


module gpio_TB;

    localparam MAX_CYCLES = 16*8;
    integer clk_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;

    // DUT Parameters
    localparam WIDTH        = 32;
    localparam PIN_COUNT    = 16;

    localparam AXI_ADDR_WIDTH = 4;
    localparam GPIOx_MODE   = 'h0;
    localparam GPIOx_IDATA  = 'h4;
    localparam GPIOx_ODATA  = 'h8;

    // DUT Ports
    wire [PIN_COUNT-1:0] io_pins;
    axi4_lite #(.WIDTH(WIDTH), .ADDR_WIDTH(AXI_ADDR_WIDTH)) axi();

    logic clk;
    logic rst, rst_n;

    logic _err;
    logic _mode;
    logic [PIN_COUNT-1:0] _out;
    logic [PIN_COUNT-1:0] _en;

    // testbench tri-states
    generate
        for (genvar i=0; i<PIN_COUNT; i++) begin
            assign io_pins[i] = (_en[i]) ? _out[i] : 1'bz;
        end
    endgenerate


    assign axi.aclk = clk;
    assign axi.areset_n = rst_n;
    assign rst_n = ~rst;

    // Instantiate DUT
    gpio #(
        .WIDTH(WIDTH),
        .PIN_COUNT(PIN_COUNT)
    ) DUT (
        .io_pins(io_pins),
        .int0(),
        .int1(),
        .axi
    );


    // 100 MHz clock
    initial clk = 1;
    initial forever #5 clk <= ~clk;

    // Initialize
    initial begin

        axi.awvalid <= 0;
        axi.awaddr  <= 0;
        axi.awprot  <= 0;
        axi.wvalid  <= 0;
        axi.wdata   <= 0;
        axi.wstrb   <= 4'b1111;
        axi.bready  <= 0;
        axi.arvalid <= 0;
        axi.araddr  <= 0;
        axi.arprot  <= 0;
        axi.rready  <= 0;

        _err    <= 0;
        _mode   <= 0;
        _en     <= 0;
        _out    <= 0;

        // Reset
        rst <= 1;
        #20
        rst <= 0;

        fid = $fopen("gpio.log");
        $dumpfile("gpio.vcd");
        $dumpvars(4, gpio_TB);
    end


    task axi_wr(input  [AXI_ADDR_WIDTH-1:0] awaddr,
                input  [WIDTH-1:0] wdata,
                output err);
        begin
            axi.awvalid <= 1;
            axi.awaddr  <= awaddr;
            axi.wvalid  <= 1;
            axi.wdata   <= wdata;
            @(posedge axi.aclk);
            while ((axi.awvalid && !axi.awready)
                || (axi.wvalid && !axi.wready))
            begin
                if (axi.awready) begin
                    axi.awvalid <= 0;
                end
                if (axi.wready) begin
                    axi.wvalid <= 0;
                end
                @(posedge axi.aclk);
            end
            axi.awvalid <= 0;
            axi.wvalid  <= 0;
            axi.bready  <= 1;
            @(posedge axi.aclk);
            while (!axi.bvalid) @(posedge axi.aclk);
            axi.bready  <= 0;
            err <= (axi.bresp != 2'b00);
            @(posedge axi.aclk);
        end
    endtask
    task axi_rd(input [AXI_ADDR_WIDTH-1:0] araddr,
                output [WIDTH-1:0] rdata,
                output err);
        begin
            axi.arvalid <= 1;
            axi.araddr  <= araddr;
            @(posedge axi.aclk);
            while (!axi.arready) @(posedge axi.aclk);
            axi.arvalid <= 0;
            axi.rready  <= 1;
            @(posedge axi.aclk);
            while (!axi.rvalid) @(posedge axi.aclk);
            axi.rready  <= 0;
            rdata       <= axi.rdata;
            err         <= (axi.rresp != 2'b00);
            @(posedge axi.aclk);
        end
    endtask



    // Stimulus
    logic [PIN_COUNT-1:0] _gpio;
    initial begin
        while (rst);
        #100;
        @(posedge clk);
        while (1) begin

            // Always tri-state before each test
            _en <= 'h0000;
            @(posedge clk)

            // Set mode
            _mode = $random();
            if (_mode) begin
                // Set output
                $write("clk=%4d    Testing output mode:\n", clk_count);
                $fwrite(fid,"clk=%4d    Testing output mode:\n", clk_count);
                axi_wr(GPIOx_MODE, 'hFFFF, _err);
                if (_err) begin
                    fail_count++;
                    $write("clk=%4d    FAILED! Error writing to mode register\n", clk_count);
                    $fwrite(fid,"clk=%4d    FAILED! Error writing to mode register\n", clk_count);
                end
                else begin
                    // Write output register
                    _gpio = $random() & 'hFFFF;
                    $write("clk=%4d        Writing 0x%04X to ODATA register\n", clk_count, _gpio);
                    $fwrite(fid,"clk=%4d        Writing  0x%04X to ODATA register\n", clk_count, _gpio);
                    axi_wr(GPIOx_ODATA, _gpio, _err);
                    if (_err) begin
                        fail_count++;
                        $write("clk=%4d    FAILED! Error writing to output register", clk_count);
                        $fwrite(fid,"clk=%4d    FAILED! Error writing to output register", clk_count);
                    end
                    else begin
                        // Check output
                        @(posedge clk)
                        $write("clk=%4d        Measured 0x%04X from GPIO pins\n", clk_count, io_pins);
                        $fwrite(fid,"clk=%4d        Measured 0x%04X from GPIO pins\n", clk_count, io_pins);
                        if (_gpio != io_pins) begin
                            fail_count++;
                            $write("clk=%4d    FAILED! Register write and pin outputs do not match\n", clk_count);
                            $fwrite(fid,"clk=%4d    FAILED! Register write and pin outputs do not match\n", clk_count);
                        end
                        else begin
                            pass_count++;
                        end
                    end
                end
            end
            else begin
                // Set input
                $write("clk=%4d    Testing input mode:\n", clk_count);
                $fwrite(fid,"clk=%4d    Testing input mode:\n", clk_count);
                axi_wr(GPIOx_MODE, 0, _err);
                if (_err) begin
                    fail_count++;
                    $write("clk=%4d    FAILED! Error writing to mode register\n", clk_count);
                    $fwrite(fid,"clk=%4d    FAILED! Error writing to mode register\n", clk_count);
                end
                else begin
                    // Check tri-state
                    if (io_pins != 'hzz) begin
                        fail_count++;
                        $write("clk=%4d    FAILED! One or more pins is not high-impedance\n", clk_count);
                        $fwrite(fid,"clk=%4d    FAILED! One or more pins is not high-impedance\n", clk_count);
                    end
                    else begin
                        
                        $write("clk=%4d        All input pins are high-impedance\n", clk_count);
                        $fwrite(fid,"clk=%4d        All input pins are high-impedance\n", clk_count);
                        // Enable testbench outputs
                        // Set input and enable
                        _out <= $random();
                        _en  <= 'hFFFF;
                        @(posedge clk);
                        $write("clk=%4d        Setting 0x%04X as input\n", clk_count, _out);
                        $fwrite(fid,"clk=%4d        Setting 0x%04X as input\n", clk_count, _out);
                        // Check input
                        axi_rd(GPIOx_IDATA, _gpio, _err);
                        if (_err) begin
                            fail_count++;
                            $write("clk=%4d    FAILED! Error reading input register\n", clk_count);
                            $fwrite(fid,"clk=%4d    FAILED! Error reading input register\n", clk_count);
                        end
                        else begin
                            if (_gpio !== _out) begin
                                fail_count++;
                                $write("clk=%4d    FAILED! IDATA register contains %04X but should be %04X\n",
                                    clk_count, _gpio, _out);
                                $fwrite(fid,"clk=%4d    FAILED! IDATA register contains %04X but should be %04X\n",
                                    clk_count, _gpio, _out);
                            end
                            else begin
                                pass_count++;
                                $write("clk=%4d        IDATA read 0x%04X\n", clk_count, _gpio);
                                $fwrite(fid,"clk=%4d        IDATA read 0x%04X\n", clk_count, _gpio);
                            end
                        end
                    end
                end
            end

            $write("\n");
            $fwrite(fid,"\n");

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
