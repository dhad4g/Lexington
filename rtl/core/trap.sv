`timescale 1ns/1ps

`include "rv32.sv"
`include "saratoga.sv"
import saratoga::*;


module trap (
        input  logic clk,                                   // core clock
        input  logic rst_n,                                 // active-low reset

        // PC inputs
        input  rv32::word fetch_pc,                         // PC of Fetch Stage
        input  rv32::word decode_pc,                        // PC of Decode Stage
        input  rv32::word exec_pc,                          // PC of Execute Stage

        // Bubbles
        input  logic bubble_fetch,
        input  logic bubble_decode,
        input  logic bubble_exec,

        // Trap related inputs
        input  logic trap_insert,                           // asserted by Control Unit when a trap is inserted into the pipeline
        input  rv32::word interrupts,                       // interrupts pending with all appropriate enable masks applied
        input  rv32::word mepc,                             // value of mepc CSR for trap returns
        input  rv32::word mtvec,                            // value of mtvec CSR for traps
        input  logic load_store_n,                          // indicates source of load/store exception (Execute Stage; 0=store,1=load)
        input  rv32::word inst,                             // instruction bits (Decode Stage)
        input  rv32::word branch_addr,                      // misaligned instruction address (Decode Stage)
        input  rv32::word data_addr,                        // data load/store address (Execute Stage)

        // Trap related outputs
        output logic trap_req,                              // request to the Control Unit to insert trap into the pipeline
        output logic trap_is_mret,                          // asserted if this is an MRET pseudo trap
        output rv32::word trap_addr,                        // destination of a trap
        output rv32::word trap_epc,                         // address of faulting or interrupted instruction
        output rv32::word trap_cause,                       // trap cause (see mcause CSR)
        output rv32::word trap_val,                         // trap value (see mtval CSR)

        // Squash instructions
        output logic squash_decode,                         // squash instruction in Decode Stage
        output logic squash_exec,                           // squash instruction in Execute Stage

        // Exception flags
        input  logic mret,                                  // MRET instruction
        input  logic inst_access_fault,                     // instruction access fault (Fetch Stage)
        input  logic inst_misaligned,                       // instruction misaligned (Decode Stage)
        input  logic illegal_inst,                          // illegal instruction (Decode Stage)
        input  logic ecall,                                 // environment call (Decode Stage)
        input  logic ebreak,                                // breakpoint (Decode Stage)
        input  logic data_misaligned,                       // load/store address misaligned (Execute Stage)
        input  logic data_access_fault                      // load/store access fault (Execute Stage)
    );

    // Internal signals
    rv32::word _pc [0:2];
    logic _trap_req;                        // trap request shadow register
    logic _exception, _interrupt, _trap;    // combined exception/interrupt flags
    integer _except_stage;
    rv32::word _except_cause, _int_cause;
    rv32::word _val;

    assign trap_req = _trap_req | _trap;

    // Put PC from each stage into an array
    assign _pc = {fetch_pc, decode_pc, exec_pc};

    // Generate internal signals
    always_comb begin
        if (mret & !bubble_decode) begin
            _exception = 1;
            _except_stage = 0;
            _except_cause = 0;
            _val = 0;
        end
        else if (inst_access_fault & !bubble_exec) begin
            _exception = 1;
            _except_stage = 0;
            _except_cause = rv32::TRAP_CODE_INST_ACCESS_FAULT;
            _val = fetch_pc;
        end
        else if (inst_misaligned & !bubble_decode) begin
            _exception = 1;
            _except_stage = 1;
            _except_cause = rv32::TRAP_CODE_INST_MISALIGNED;
            _val = branch_addr;
        end
        else if (illegal_inst & !bubble_decode) begin
            _exception = 1;
            _except_stage = 1;
            _except_cause = rv32::TRAP_CODE_ILLEGAL_INST;
            _val = inst;
        end
        else if (ecall & !bubble_decode) begin
            _exception = 1;
            _except_stage = 1;
            _except_cause = rv32::TRAP_CODE_ENV_CALL_MMODE;
            _val = 0;
        end
        else if (ebreak & !bubble_decode) begin
            _exception = 1;
            _except_stage = 1;
            _except_cause = rv32::TRAP_CODE_BREAKPOINT;
            _val = 0;
        end
        else if (data_misaligned & !bubble_exec) begin
            _exception = 1;
            _except_stage = 2;
            _except_cause = (load_store_n) ? rv32::TRAP_CODE_LOAD_MISALIGNED
                                    : rv32::TRAP_CODE_STORE_MISALIGNED;
            _val = data_addr;
        end
        else if (data_access_fault & !bubble_exec) begin
            _exception = 1;
            _except_stage = 2;
            _except_cause = (load_store_n) ? rv32::TRAP_CODE_LOAD_ACCESS_FAULT
                                    : rv32::TRAP_CODE_STORE_ACCESS_FAULT;
            _val = data_addr;
        end
        else begin
            _exception = 0;
            _except_stage = 0;
            _except_cause = 0;
        end
        _interrupt = |interrupts;
        _trap = _exception | _interrupt;
    end

    // Interrupt cause decode function
    always_comb begin
        rv32::word msb_mask;
        msb_mask = (~0) << (rv32::XLEN-1);
        if (!rst_n) begin
            _int_cause = 0;
        end
        else begin
            _int_cause = 0;
            for (int i=rv32::XLEN-1; i>=0; i--) begin
                if (interrupts[i]) begin
                    _int_cause = i;
                end
            end
            _int_cause = _int_cause | msb_mask;
        end
    end


    // Shadow register control
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            _trap_req <= 0;
        end
        else begin
            if (!_trap_req) begin
                _trap_req <= _trap & !trap_insert;
            end
            else if (trap_insert) begin
                _trap_req <= 0;
            end
        end
    end

    // Latch trap output data
    always_latch begin
        if (!rst_n) begin
            trap_is_mret<= 0;
            trap_epc    <= 0;
            trap_cause  <= 0;
            trap_val    <= 0;
        end
        else begin
            if (_exception) begin
                trap_is_mret<= mret;
                trap_epc    <= _pc[_except_stage];
                trap_cause  <= _except_cause;
                trap_val    <= _val;
            end
            else if (_interrupt) begin
                trap_is_mret<= 0;
                trap_epc    <= fetch_pc;
                trap_cause  <= _int_cause;
                trap_val    <= 0;
            end
        end
    end

    // Combinatorial output data
    always_comb begin
        if (!rst_n) begin
            trap_addr       = 0;
            squash_decode   = 0;
            squash_exec     = 0;
        end
        else begin

            // Squashes
            if (_exception) begin
                squash_decode   = (_except_stage >= DECODE_STAGE_ID);
                squash_exec     = (_except_stage >= EXEC_STAGE_ID);
            end
            else begin
                squash_decode   = 0;
                squash_exec     = 0;
            end

            // Trap destination PC
            if (trap_is_mret) begin
                // Trap return
                trap_addr = mepc;
            end
            else if (trap_cause[rv32::XLEN-1]) begin
                // interrupt
                if (mtvec[1:0] == 2'b01) begin
                    // vectored
                    localparam _msb = rv32::XLEN-1;
                    localparam _lsb = MTVEC_ADDR_BIT_ALIGN;
                    trap_addr[_msb:_lsb] = mtvec[_msb:_lsb];
                    trap_addr[_lsb-1:0]  = trap_cause[_lsb-3:0] << 2;
                end
                else begin
                    // direct
                    trap_addr = {mtvec[rv32::XLEN-1:2], 2'b00};
                end
            end
            else begin
                // exception
                trap_addr = {mtvec[rv32::XLEN-1:2], 2'b00};
            end

        end
    end

endmodule
