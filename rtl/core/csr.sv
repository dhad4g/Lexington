`timescale 1ns/1ps

`include "rv32.sv"
`include "lexington.sv"
import rv32::CSR_ADDR;
import lexington::*;


module csr #(
        parameter HART_ID       = 0                     // hardware thread ID
    ) (
        input  logic clk,                               // global system clock
        input  logic rst_n,                             // global reset, active-low

        // CSR read/write
        input  logic rd_en,                             // read enable
        input  logic explicit_rd,                       // indicates explicit CSR read
        input  logic wr_en,                             // write enable
        input  rv32::csr_addr_t addr,                   // read/write address
        output rv32::word rd_data,                      // read data
        input  rv32::word wr_data,                      // write data

        // Trap Unit CSRs
        output logic trap_rd_en,                        // read enable for Trap CSRs
        output logic trap_wr_en,                        // write enable for Trap CSRs
        input  rv32::word trap_rd_data,                 // read data from Trap CSRs

        // Time CSR
        input  logic [63:0] time_rd_data,               // read-only unprivileged time/timeh CSR

        // Flags
        output logic global_mie,                        // global machine-mode interrupts enable
        output logic endianness,                        // data memory endianness (0=little,1=big)
        output logic illegal_csr,                       // illegal CSR address or access permission
        input  logic dbus_wait,
        input  logic mret,                              // mret instruction flag
        input  logic trap                               // signals trap occured this cycle
    );

    // Current privilege level (not visible)
    rv32::priv_mode_t priv;

    // CSR definitions
    rv32::word misa;
    rv32::word mvendorid;
    rv32::word marchid;
    rv32::word mimpid;
    rv32::word mhartid;
    struct packed {
        logic [25:0] reserved6;
        logic MBE;
        logic SBE;
        logic [3:0] reserved5;
        logic SD;
        logic [7:0] reserved4;
        logic TSR;
        logic TW;
        logic TVM;
        logic MXR;
        logic SUM;
        logic MPRV;
        logic [1:0] XS;
        logic [1:0] FS;
        logic [1:0] MPP;
        logic [1:0] VS;
        logic SPP;
        logic MPIE;
        logic UBE;
        logic SPIE;
        logic reserved3;
        logic MIE;
        logic reserved2;
        logic SIE;
        logic reserved1;
    } mstatus;
    logic [63:0] mcycle;
    logic [64:0] minstret;
    struct packed {
        logic [31:3] HPMx;
        logic IR;
        logic reserved;
        logic CY;
    } mcountinhibit;
    rv32::word mscratch;
    rv32::word mconfigptr;

    // Output flag assignments
    assign global_mie = mstatus.MIE;
    assign endianness = mstatus.MBE;

    // Read-Only CSR assignments
    assign misa = {2'b1, 4'b0, 1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
                // extensions:   q    p    o    n    m    l    k    j    i
                               1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
                // extensions:   h    g    f    e    d    c    b    a
                               1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
    assign mvendorid = 32'h0;
    assign marchid = 32'h0;
    assign mimpid = 32'h1;
    assign mhartid = HART_ID;
    assign mstatus.reserved6 = 0;
    assign mstatus.SBE = 0;
    assign mstatus.reserved5 = 0;
    assign mstatus.SD = 0;
    assign mstatus.reserved4 = 0;
    assign mstatus.TSR = 0;
    assign mstatus.TW = 0;
    assign mstatus.TVM = 0;
    assign mstatus.MXR = 0;
    assign mstatus.SUM = 0;
    assign mstatus.MPRV = 0;
    assign mstatus.XS = 0;
    assign mstatus.FS = 0;
    assign mstatus.MPP = 3;
    assign mstatus.VS = 0;
    assign mstatus.SPP = 0;
    assign mstatus.UBE = 0;
    assign mstatus.SPIE = 1;
    assign mstatus.SIE = 1;
    assign mconfigptr = 0;


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Combinatorial Logic
    ////////////////////////////////////////////////////////////
    always_comb begin
        if (!rst_n) begin
            rd_data     = 0;
            illegal_csr = 0;
            trap_rd_en  = 0;
            trap_wr_en  = 0;
        end
        else begin
            // default illegal_csr, trap_rd_en, & trap_wr_en to 0
            illegal_csr = 0;
            trap_rd_en  = 0;
            trap_wr_en  = 0;
            case (addr)
                rv32::csr_addr_cycle: begin
                    rd_data = mcycle[31:0];
                end
                rv32::csr_addr_cycleh: begin
                    rd_data = mcycle[63:32];
                end
                rv32::csr_addr_instret: begin
                    rd_data = minstret[31:0];
                end
                rv32::csr_addr_instreth: begin
                    rd_data = minstret[63:32];
                end
                rv32::csr_addr_time: begin
                    rd_data = time_rd_data[31:0];
                end
                rv32::csr_addr_timeh: begin
                    rd_data = time_rd_data[63:32];
                end
            endcase
            // Machine-Mode CSRs
            if (priv >= rv32::mmode) begin
                case (addr)
                    rv32::csr_addr_misa: begin
                        rd_data = misa;
                    end
                    rv32::csr_addr_mvendorid: begin
                        rd_data = mvendorid;
                    end
                    rv32::csr_addr_marchid: begin
                        rd_data = marchid;
                    end
                    rv32::csr_addr_mimpid: begin
                        rd_data = mimpid;
                    end
                    rv32::csr_addr_mhartid: begin
                        rd_data = mhartid;
                    end
                    rv32::csr_addr_mstatus: begin
                        rd_data = mstatus[31:0];
                    end
                    rv32::csr_addr_mstatush: begin
                        rd_data = mstatus[63:32];
                    end
                    rv32::csr_addr_mtvec: begin
                        trap_rd_en  = rd_en;
                        trap_wr_en  = wr_en;
                        rd_data     = trap_rd_data;
                    end
                    rv32::csr_addr_mip: begin
                        trap_rd_en  = rd_en;
                        trap_wr_en  = wr_en;
                        rd_data     = trap_rd_data;
                    end
                    rv32::csr_addr_mie: begin
                        trap_rd_en  = rd_en;
                        trap_wr_en  = wr_en;
                        rd_data     = trap_rd_data;
                    end
                    rv32::csr_addr_mcycle: begin
                        rd_data = mcycle[31:0];
                    end
                    rv32::csr_addr_mcycleh: begin
                        rd_data = mcycle[63:32];
                    end
                    rv32::csr_addr_minstret: begin
                        rd_data = minstret[31:0];
                    end
                    rv32::csr_addr_minstreth: begin
                        rd_data = minstret[63:32];
                    end
                    rv32::csr_addr_mcountinhibit: begin
                        rd_data = mcountinhibit;
                    end
                    rv32::csr_addr_mscratch: begin
                        rd_data = mscratch;
                    end
                    rv32::csr_addr_mepc: begin
                        trap_rd_en  = rd_en;
                        trap_wr_en  = wr_en;
                        rd_data     = trap_rd_data;
                    end
                    rv32::csr_addr_mcause: begin
                        trap_rd_en  = rd_en;
                        trap_wr_en  = wr_en;
                        rd_data     = trap_rd_data;
                    end
                    rv32::csr_addr_mtval: begin
                        trap_rd_en  = rd_en;
                        trap_wr_en  = wr_en;
                        rd_data     = trap_rd_data;
                    end
                    rv32::csr_addr_mconfigptr: begin
                        rd_data = mconfigptr;
                    end
                    default: begin
                        rd_data = 0;
                        illegal_csr = rd_en | wr_en;
                    end
                endcase
            end // if(priv >= mmode)
            else begin
                rd_data = 0;
                illegal_csr = rd_en | wr_en;
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Read Logic
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Write & Counter Logic
    ////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            priv <= rv32::mmode;
            // CSR reset values
            mstatus.MBE <= 0;
            mstatus.MPIE <= 1;
            mstatus.MIE <= 1;
            mcycle <= 0;
            minstret <= 0;
            mcountinhibit <= 0;
            mscratch <= 0;
        end
        else begin
            if (wr_en) begin
                // User-Mode CSRs
                case (addr)
                    rv32::csr_addr_cycle: begin
                        // read-only
                    end
                    rv32::csr_addr_cycleh: begin
                        // read-only
                    end
                    rv32::csr_addr_instret: begin
                        // read-only
                    end
                    rv32::csr_addr_instreth: begin
                        // read-only
                    end
                    rv32::csr_addr_time: begin
                        // read-only
                    end
                    rv32::csr_addr_timeh: begin
                        // read-only
                    end
                endcase
                // Machine-Mode CSRs
                if (priv >= rv32::mmode) begin
                    case (addr)
                        rv32::csr_addr_misa: begin
                            // read-only
                        end
                        rv32::csr_addr_mvendorid: begin
                            // read-only
                        end
                        rv32::csr_addr_marchid: begin
                            // read-only
                        end
                        rv32::csr_addr_mimpid: begin
                            // read-only
                        end
                        rv32::csr_addr_mhartid: begin
                            // read-only
                        end
                        rv32::csr_addr_mstatus: begin
                            mstatus.MPIE <= wr_data[7];
                            mstatus.MIE  <= wr_data[3];
                        end
                        rv32::csr_addr_mstatush: begin
                            mstatus.MBE <= wr_data[5];
                        end
                        rv32::csr_addr_mtvec: begin
                            // delegated to trap
                        end
                        rv32::csr_addr_mip: begin
                            // delegated to trap
                        end
                        rv32::csr_addr_mie: begin
                            // delegated to trap
                        end
                        rv32::csr_addr_mcycle: begin
                            mcycle[31:0] <= rd_data;
                        end
                        rv32::csr_addr_mcycleh: begin
                            mcycle[63:32] <= rd_data;
                        end
                        rv32::csr_addr_minstret: begin
                            minstret[31:0] <= rd_data;
                        end
                        rv32::csr_addr_minstreth: begin
                            minstret[63:32] <= rd_data;
                        end
                        rv32::csr_addr_mcountinhibit: begin
                            mcountinhibit <= rd_data;
                        end
                        rv32::csr_addr_mscratch: begin
                            mscratch <= rd_data;
                        end
                        rv32::csr_addr_mepc: begin
                            // delegated to trap
                        end
                        rv32::csr_addr_mcause: begin
                            // delegated to trap
                        end
                        rv32::csr_addr_mtval: begin
                            // delegated to trap
                        end
                        rv32::csr_addr_mconfigptr: begin
                            // read-only
                        end
                        default: begin
                        end
                    endcase
                end // if(priv >= mmode)
            end // if(wr_en)

            // mstatus behavior
            if (trap) begin
                mstatus.MPIE <= mstatus.MIE;
                mstatus.MIE  <= 0;
                // no MPP, only m-mode supported
            end
            else if (mret) begin
                mstatus.MIE  <= mstatus.MPIE;
                mstatus.MPIE <= 1;
            end

            // mcycle behavior
            if (!mcountinhibit.CY) begin
                mcycle <= mcycle + 1;
            end

            // minstret behavior
            if (!mcountinhibit.IR) begin
                if (!dbus_wait) begin
                    minstret <= minstret + 1;
                end
            end

        end
    end
    ////////////////////////////////////////////////////////////
    // END: Write Logic
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

endmodule