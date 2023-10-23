//depend core/*.sv
//depend core/pipeline/*.sv
`timescale 1ns/1ps

`include "rv32.sv"
`include "saratoga.sv"
import saratoga::*;


module core #(
        parameter CLK_PERIOD        = DEFAULT_CLK_PERIOD,           // system clock period in ns
        parameter ROM_ADDR_WIDTH    = DEFAULT_ROM_ADDR_WIDTH,       // ROM address width (word-addressable, default 4kB)
        parameter RAM_ADDR_WIDTH    = DEFAULT_RAM_ADDR_WIDTH,       // RAM address width (word-addressable, default 4kB)
        localparam MTIME_ADDR_WIDTH = 2,
        parameter AXI_ADDR_WIDTH    = DEFAULT_AXI_ADDR_WIDTH,       // AXI bus address space width (byte-addressable)
        parameter ROM_BASE_ADDR     = DEFAULT_ROM_BASE_ADDR,        // ROM base address (must be aligned to ROM size)
        parameter RAM_BASE_ADDR     = DEFAULT_RAM_BASE_ADDR,        // RAM base address (must be aligned to RAM size)
        parameter MTIME_BASE_ADDR   = DEFAULT_MTIME_BASE_ADDR,      // machine timer base address (see [CSR](./CSR.md))
        parameter AXI_BASE_ADDR     = DEFAULT_AXI_BASE_ADDR,        // AXI bus address space base (must be aligned to AXI address space)
        parameter RESET_ADDR        = DEFAULT_RESET_ADDR,           // program counter reset/boot address
        parameter HART_ID           = 0                             // hardware thread id (see mhartid CSR)
    ) (
        input  logic clk,                                           // global system clock
        input  logic rst_n,                                         // global reset, active-low

        // ROM ports
        output logic rom_rd_en1,                                    // IBus
        output logic [ROM_ADDR_WIDTH-1:0] rom_addr1,                // IBus
        input  rv32::word rom_rd_data1,                             // IBus
        output logic rom_rd_en2,                                    // DBus
        output logic [ROM_ADDR_WIDTH-1:0] rom_addr2,                // DBus
        input  rv32::word rom_rd_data2,                             // DBus

        // RAM ports
        output logic ram_rd_en,                                     // DBus
        output logic ram_wr_en,                                     // DBus
        output logic [RAM_ADDR_WIDTH-1:0] ram_addr,                 // DBus
        input  rv32::word ram_rd_data,                              // DBus

        // AXI port
        output logic axi_rd_en,                                     // DBus
        output logic axi_wr_en,                                     // DBus
        output logic [AXI_ADDR_WIDTH-1:0] axi_addr,                 // DBus
        input  rv32::word axi_rd_data,                              // DBus
        input  logic axi_access_fault,                              // DBus
        input  logic axi_busy,                                      // DBus

        output rv32::word wr_data,                                  // share write data
        output logic [(rv32::XLEN/8)-1:0] wr_strobe,                // share write strobe

        // Interrupt flags
        input  logic gpioa_int_0,                                   // GPIOA interrupt 0
        input  logic gpioa_int_1,                                   // GPIOA interrupt 1
        input  logic gpiob_int_0,                                   // GPIOA interrupt 0
        input  logic gpiob_int_1,                                   // GPIOA interrupt 1
        input  logic gpioc_int_0,                                   // GPIOA interrupt 0
        input  logic gpioc_int_1,                                   // GPIOA interrupt 1
        input  logic uart0_rx_int,                                  // UART0 RX interrupt
        input  logic uart0_tx_int,                                  // UART0 TX interrupt
        input  logic timer0_int,                                    // timer0 interrupt
        input  logic timer1_int                                     // timer1 interrupt
    );


    // Interrupt mapping
    rv32::word int_sources;
    assign int_sources = {
        4'b0,
        2'b0, gpioc_int_1, gpioc_int_0,
        gpiob_int_1, gpiob_int_0, gpioa_int_1, gpioa_int_0,
        timer1_int, timer0_int, uart0_tx_int, uart0_rx_int,
        16'b0
    };


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Internal Wires
    ////////////////////////////////////////////////////////////
    // IBus
    logic ibus_rd_en;
    rv32::word ibus_addr;
    rv32::word ibus_rd_data;
    rv32::word inst;
    // DBus
    logic dbus_rd_en;
    logic dbus_wr_en;
    rv32::word dbus_addr;
    rv32::word dbus_rd_data;
    rv32::word dbus_wr_data;
    logic [(rv32::XLEN/8)-1:0] dbus_wr_strobe;
    logic dbus_wait;
    logic dbus_err;
    // Trap
    rv32::word interrupts;      // interrupts pending with masks
    logic trap_req;
    logic trap_is_mret;
    rv32::word mepc;
    rv32::word mtvec;
    rv32::word trap_epc;
    rv32::word trap_cause;
    rv32::word trap_val;
    logic load_store_n;
    // Control
    logic branch;
    logic control_stall_decode;
    logic trap_insert;
    logic atomic_csr;
    logic atomic_csr_pending;
    logic next_pc_en;
    // PC
    rv32::word fetch_pc;
    rv32::word decode_pc;
    rv32::word exec_pc;
    rv32::word branch_addr;
    rv32::word trap_addr;
    rv32::word next_pc;
    // Fetch Stage
    logic bubble_fetch;
    logic stall_fetch;
    // Decode Stage
    logic bubble_decode;
    logic stall_decode;
    logic squash_decode;
    rv32::word decode_src1;
    rv32::word decode_src2;
    rv32::word decode_alt_data;
    rv32::gpr_addr_t decode_dest;
    alu_op_t decode_alu_op;
    lsu_op_t decode_lsu_op;
    // Execute Stage
    logic bubble_exec;
    logic stall_exec;
    logic squash_exec;
    rv32::word exec_src1;
    rv32::word exec_src2;
    rv32::word exec_alu_result;
    rv32::word exec_alt_data;
    // rv32::csr_addr_t exec_csr_addr;
    // rv32::gpr_addr_t exec_dest;
    alu_op_t exec_alu_op;
    lsu_op_t exec_lsu_op;
    // Register File
    logic rs1_en;
    logic rs2_en;
    logic dest_en;
    rv32::gpr_addr_t rs1_addr;
    rv32::gpr_addr_t rs2_addr;
    rv32::gpr_addr_t dest_addr;
    rv32::word rs1_data;
    rv32::word rs2_data;
    rv32::word dest_data;
    // CSR
    logic csr_rd_en;
    logic csr_explicit_rd;
    logic csr_wr_en;
    rv32::csr_addr_t csr_rd_addr;
    rv32::csr_addr_t csr_wr_addr;
    rv32::word csr_rd_data;
    rv32::word csr_wr_data;
    logic csr_addr_is_atomic;
    logic csr_addr_is_illegal;
    // Machine Timer
    logic mtime_rd_en;
    logic mtime_wr_en;
    logic [MTIME_ADDR_WIDTH-1:0] mtime_addr;
    rv32::word mtime_rd_data;
    logic [63:0] time_rd_data;  // unprivileged alias
    logic mtime_interrupt;
    // Misc. control signals
    logic endianness;
    // Exceptions
    logic mret;
    logic inst_access_fault;
    logic inst_misaligned;
    logic data_access_fault;
    logic data_misaligned;
    logic illegal_inst;
    logic ecall;
    logic ebreak;
    ////////////////////////////////////////////////////////////
    // END: Internal Wires
    ////////////////////////////////////////////////////////////


    // Stall logic
    assign stall_fetch  = stall_decode;
    assign stall_decode = control_stall_decode | stall_exec;
    assign stall_exec   = dbus_wait;




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Memory Bus Instantiations
    ////////////////////////////////////////////////////////////
    assign ibus_rd_en = 1;
    assign ibus_addr  = fetch_pc;
    ibus #(
        .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH),
        .ROM_BASE_ADDR(ROM_BASE_ADDR)
    ) IBUS (
        .rd_en(ibus_rd_en),
        .addr(ibus_addr),
        .rd_data(ibus_rd_data),
        .rom_rd_data(rom_rd_data1),
        .rom_rd_en(rom_rd_en1),
        .rom_addr(rom_addr1),
        .inst_access_fault
    );
    dbus #(
        .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .ROM_BASE_ADDR(ROM_BASE_ADDR),
        .RAM_BASE_ADDR(RAM_BASE_ADDR),
        .MTIME_BASE_ADDR(MTIME_BASE_ADDR),
        .AXI_BASE_ADDR(AXI_BASE_ADDR)
    ) DBUS (
        .clk,
        .rst_n,
        .rd_en(dbus_rd_en),
        .wr_en(dbus_wr_en),
        .addr(dbus_addr),
        .wr_data_i(dbus_wr_data),
        .wr_strobe_i(dbus_wr_strobe),
        .rom_rd_data(rom_rd_data2),
        .ram_rd_data,
        .mtime_rd_data,
        .axi_rd_data,
        .axi_access_fault,
        .axi_busy,
        .rd_data(dbus_rd_data),
        .rom_rd_en(rom_rd_en2),
        .rom_addr(rom_addr2),
        .ram_rd_en,
        .ram_wr_en,
        .ram_addr,
        .mtime_rd_en,
        .mtime_wr_en,
        .mtime_addr,
        .axi_rd_en,
        .axi_wr_en,
        .axi_addr,
        .wr_data_o(wr_data),
        .wr_strobe_o(wr_strobe),
        .data_misaligned,
        .data_access_fault,
        .load_store_n,
        .dbus_wait,
        .dbus_err
    );
    ////////////////////////////////////////////////////////////
    // END: Memory Bus Instantiations
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////



    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Pipeline Registers
    ////////////////////////////////////////////////////////////
    if_id IF_ID (
        .clk,
        .rst_n,
        .stall_fetch,
        .stall_decode,
        .bubble_i(bubble_fetch),
        .inst_i(ibus_rd_data),
        .pc_i(fetch_pc),
        .bubble_o(bubble_decode),
        .pc_o(decode_pc),
        .inst_o(inst)
    );
    id_ex ID_EX (
        .clk,
        .rst_n,
        .stall_decode,
        .squash_decode,
        .stall_exec,
        .bubble_i(bubble_decode),
        .pc_i(decode_pc),
        .src1_i(decode_src1),
        .src2_i(decode_src2),
        .alt_data_i(decode_alt_data),
        .csr_addr_i(csr_rd_addr),
        .dest_i(decode_dest),
        .alu_op_i(decode_alu_op),
        .lsu_op_i(decode_lsu_op),
        .bubble_o(bubble_exec),
        .pc_o(exec_pc),
        .src1_o(exec_src1),
        .src2_o(exec_src2),
        .alt_data_o(exec_alt_data),
        .csr_addr_o(csr_wr_addr),
        .dest_o(dest_addr),
        .alu_op_o(exec_alu_op),
        .lsu_op_o(exec_lsu_op)
    );
    ////////////////////////////////////////////////////////////
    // END: Pipeline Registers
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////s




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Register File and CSR
    ////////////////////////////////////////////////////////////
    regfile REGFILE (
        .clk,
        .rs1_en,
        .rs2_en,
        .rs1_addr,
        .rs2_addr,
        .rs1_data,
        .rs2_data,
        .dest_en,
        .dest_addr,
        .dest_data
    );
    csr #(
        .HART_ID(HART_ID)
    ) CSR (
        .clk,
        .rst_n,
        .rd_en(csr_rd_en),
        .explicit_rd(csr_explicit_rd),
        .wr_en(csr_wr_en),
        .rd_addr(csr_rd_addr),
        .wr_addr(csr_wr_addr),
        .rd_data(csr_rd_data),
        .wr_data(csr_wr_data),
        .addr_is_atomic(csr_addr_is_atomic),
        .addr_is_illegal(csr_addr_is_illegal),
        .time_rd_data,
        .trap_insert,
        .trap_is_mret,
        .trap_epc,
        .trap_cause,
        .trap_val,
        .mepc,
        .mtvec,
        .mtime_interrupt,
        .int_sources,
        .interrupts,
        .atomic_csr_pending,
        .bubble_decode,
        .bubble_exec,
        .stall_exec,
        .endianness
    );
    ////////////////////////////////////////////////////////////
    // END: Register File and CSR
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Control and Trap
    ////////////////////////////////////////////////////////////
    control CONTROL (
        .clk,
        .rst_n,
        .branch,
        .branch_addr,
        .trap_req,
        .trap_addr,
        .csr_rd_en,
        .decode_csr_addr(csr_rd_addr),
        .exec_csr_addr(csr_wr_addr),
        .atomic_csr,
        .bubble_decode,
        .squash_decode,
        .bubble_exec,
        .next_pc_en,
        .next_pc,
        .bubble_fetch,
        .stall_decode(control_stall_decode),
        .trap_insert,
        .atomic_csr_pending
    );
    trap TRAP (
        .clk,
        .rst_n,
        .fetch_pc,
        .decode_pc,
        .exec_pc,
        .bubble_fetch,
        .bubble_decode,
        .bubble_exec,
        .trap_insert,
        .interrupts,
        .mepc,
        .mtvec,
        .load_store_n,
        .inst,
        .branch_addr,
        .data_addr(exec_alu_result),
        .trap_req,
        .trap_is_mret,
        .trap_addr,
        .trap_epc,
        .trap_cause,
        .trap_val,
        .squash_decode,
        .squash_exec,
        .mret,
        .inst_access_fault,
        .inst_misaligned,
        .illegal_inst,
        .ecall,
        .ebreak,
        .data_misaligned,
        .data_access_fault
    );
    ////////////////////////////////////////////////////////////
    // END: Control and Trap
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Fetch Stage
    ////////////////////////////////////////////////////////////
    pc #(
        .RESET_ADDR(RESET_ADDR)
    ) PC (
        .clk,
        .rst_n,
        .bubble_fetch,
        .stall_fetch,
        .next_pc_en,
        .next_pc,
        .pc(fetch_pc)
    );
    ////////////////////////////////////////////////////////////
    // END: Fetch Stage
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Decode Stage
    ////////////////////////////////////////////////////////////
    decoder DECODER (
        .inst,
        .pc(decode_pc),
        .branch,
        .branch_addr,
        .rs1_en,
        .rs2_en,
        .rs1_addr,
        .rs2_addr,
        .rs1_data,
        .rs2_data,
        .csr_rd_en,
        .csr_explicit_rd,
        .csr_addr(csr_rd_addr),
        .csr_rd_data,
        .csr_addr_is_atomic,
        .csr_addr_is_illegal,
        .atomic_csr,
        .alu_op(decode_alu_op),
        .src1(decode_src1),
        .src2(decode_src2),
        .lsu_op(decode_lsu_op),
        .alt_data(decode_alt_data),
        .dest_addr(decode_dest),
        .illegal_inst,
        .inst_misaligned,
        .ecall,
        .ebreak,
        .mret
    );
    ////////////////////////////////////////////////////////////
    // END: Decode Stage
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Execute Stage
    ////////////////////////////////////////////////////////////
    alu ALU (
        .alu_op(exec_alu_op),
        .src1(exec_src1),
        .src2(exec_src2),
        .result(exec_alu_result)
    );
    lsu LSU (
        .lsu_op(exec_lsu_op),
        .alu_result(exec_alu_result),
        .alt_data(exec_alt_data),
        .endianness,
        .bubble(bubble_exec),
        .stall(stall_exec),
        .dest_en,
        .dest_addr,
        .dest_data,
        .dbus_rd_data,
        .dbus_rd_en,
        .dbus_wr_en,
        .dbus_addr,
        .dbus_wr_data,
        .dbus_wr_strobe,
        .dbus_err,
        .csr_wr_en,
        .csr_wr_data
    );
    ////////////////////////////////////////////////////////////
    // END: Execute Stage
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Machine Timer
    ////////////////////////////////////////////////////////////
    mtime MTIME (
            .clk,
            .rst_n,
            .rd_en(mtime_rd_en),
            .wr_en(mtime_wr_en),
            .addr(mtime_addr),
            .wr_data,
            .wr_strobe,
            .rd_data(mtime_rd_data),
            .time_rd_data,
            .interrupt(mtime_interrupt)
        );
    ////////////////////////////////////////////////////////////
    // END: Machine Timer
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

endmodule
