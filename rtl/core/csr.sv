`timescale 1ns/1ps

`include "rv32.sv"
`include "saratoga.sv"
import rv32::CSR_ADDR;
import saratoga::*;


module csr #(
        parameter HART_ID   = 0                         // hardware thread ID
    ) (
        input  logic clk,                               // global system clock
        input  logic rst_n,                             // global reset, active-low

        // CSR read/write
        input  logic rd_en,                             // read enable
        input  logic explicit_rd,                       // indicates explicit CSR read
        input  logic wr_en,                             // write enable
        input  rv32::csr_addr_t rd_addr,                // read address
        input  rv32::csr_addr_t wr_addr,                // write address
        output rv32::word rd_data,                      // read data
        input  rv32::word wr_data,                      // write data
        output logic addr_is_atomic,                    // indicates read to atomic CSR
        output logic addr_is_illegal,                   // indicates illegal CSR address or access permission

        // Time CSR
        input  logic [63:0] time_rd_data,               // read-only unprivileged time/timeh CSR

        // Trap related signals
        input  logic trap_insert,
        input  logic trap_is_mret,
        input  rv32::word trap_epc,
        input  rv32::word trap_cause,
        input  rv32::word trap_val,
        output rv32::word mepc,
        output rv32::word mtvec,

        // Interrupts
        input  logic mtime_interrupt,
        input  rv32::word int_sources,
        output rv32::word interrupts,

        // Misc. Inputs
        input  logic atomic_csr_pending,                // asserted if atomic CSR write is in progress
        input  logic stall_exec,                        // asserted if the Execute Stage is stalled
        input  logic bubble_exec,                       // asserted if the Execute Stage has a bubble

        // Misc. Outputs
        output logic endianness                         // effective data memory endianness
    );

    // Current privilege mode
    rv32::priv_mode_t priv;

    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: CSR Declarations
    ////////////////////////////////////////////////////////////
    rv32::word misa;
    rv32::word mvendorid;
    rv32::word marchid;
    rv32::word mimpid;
    rv32::word mhartid;
    struct packed {
        logic [25:0] reserved63_38;
        logic MBE;
        logic SBE;
        logic [3:0] reserved45_32;
        logic SD;
        logic [7:0] reserved40_23;
        logic TSR;
        logic TW;
        logic TVM;
        logic MXR;
        logic SUM;
        logic MPRV;
        logic [1:0] XS;
        logic [1:0] FS;
        rv32::priv_mode_t MPP;
        logic [1:0] VS;
        logic SPP;
        logic MPIE;
        logic UBE;
        logic SPIE;
        logic reserved4;
        logic MIE;
        logic reserved2;
        logic SIE;
        logic reserved0;
    } mstatus;
    // rv32::word mtvec;   // already defined as output port
    interrupt_csr_t mip;
    interrupt_csr_t mie;
    logic [63:0] mcycle;
    logic [63:0] minstret;
    struct packed {
        logic [31:3] HPMx;
        logic IR;
        logic reserved;
        logic CY;
    } mcountinhibit;
    rv32::word mscratch;
    // rv32::word mepc;    // already defined as output port
    rv32::word mcause;
    rv32::word mtval;
    rv32::word mconfigptr;
    ////////////////////////////////////////////////////////////
    // END: CSR Declarations
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Effective Endianness
    ////////////////////////////////////////////////////////////
    always_comb begin
        case (priv)
            rv32::MMODE: begin
                if (mstatus.MPRV) begin
                    // Effective data memory privilege is MPP
                    case (mstatus.MPP)
                        rv32::MMODE: begin
                            endianness = mstatus.MBE;
                        end
                        // rv32::SMODE begin
                        // end
                        default: begin
                            endianness = mstatus.UBE;
                        end
                    endcase
                end
                else begin
                    endianness = mstatus.MBE;
                end
            end
            // rv32::SMODE: begin
            // end
            default: begin // user mode
                endianness = mstatus.UBE;
            end
        endcase
    end
    ////////////////////////////////////////////////////////////
    // END: Effective Endianness
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Interrupt Masks
    ////////////////////////////////////////////////////////////
    always_comb begin
        if (!rst_n) begin
            interrupts  = 0;
        end
        else begin
            if (atomic_csr_pending) begin
                interrupts = 0;
            end
            else begin
                case (priv)
                    rv32::MMODE: begin
                        interrupts = (mstatus.MIE) ? (int_sources & mie) : 0;
                    end
                    // rv32::SMODE: begin
                    // end
                    default: begin // user mode
                        interrupts = int_sources & mie;
                    end
                endcase
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Interrupt Masks
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Read-Only CSRs
    ////////////////////////////////////////////////////////////
    assign misa = {2'b1, 4'b0, 1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
                // MXL    0     z    y    x    w    v    u    t    s    r
                               1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,
                // extensions:   q    p    o    n    m    l    k    j    i
                               1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
                // extensions:   h    g    f    e    d    c    b    a
    assign mvendorid = 32'h0;
    assign marchid = 32'h0;
    assign mimpid = 32'h1;
    assign mhartid = HART_ID;
    // mstatus
    assign mstatus.reserved63_38 = 0;
    assign mstatus.SBE = 0;
    assign mstatus.reserved45_32 = 0;
    assign mstatus.SD = 0;
    assign mstatus.reserved40_23 = 0;
    assign mstatus.TSR = 0;
    assign mstatus.TW = 0;
    assign mstatus.TVM = 0;
    assign mstatus.MXR = 0;
    assign mstatus.SUM = 0;
    assign mstatus.XS = 0;
    assign mstatus.FS = 0;
    assign mstatus.VS = 0;
    assign mstatus.SPP = 0;
    assign mstatus.SPIE = 1;
    assign mstatus.reserved4 = 0;
    assign mstatus.reserved2 = 0;
    assign mstatus.SIE = 1;
    assign mstatus.reserved0 = 0;
    // mip
    assign mip.reserved15_12 = 0;
    assign mip.reserved8 = 0;
    assign mip.reserved6 = 0;
    assign mip.reserved4 = 0;
    assign mip.reserved2 = 0;
    assign mip.reserved0 = 0;
    assign mip.MEI = 0;
    assign mip.SEI = 0;
    assign mip.MTI = mtime_interrupt;
    assign mip.STI = 0;
    assign mip.MSI = 0;
    assign mip.SSI = 0;
    // mie
    assign mie.reserved15_12 = 0;
    assign mie.reserved8 = 0;
    assign mie.reserved6 = 0;
    assign mie.reserved4 = 0;
    assign mie.reserved2 = 0;
    assign mie.reserved0 = 0;
    assign mie.MEI = 0;
    assign mie.SEI = 0;
    assign mie.STI = 0;
    assign mie.MSI = 0;
    assign mie.SSI = 0;
    assign mconfigptr = 0;
    ////////////////////////////////////////////////////////////
    // END: Read-Only CSRs
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Combinatorial Logic
    ////////////////////////////////////////////////////////////
    always_comb begin
        if (!rst_n) begin
            addr_is_atomic  = 0;
            addr_is_illegal = 0;
            rd_data = 0;
        end
        else begin
            logic addr_is_atomic;  // read enable not applied
            logic _rd_data; // read data before bypass
            // default addr_is_illegal to 0
            addr_is_illegal = 0;
            // User-Mode CSRs
            case (rd_addr)
                rv32::csr_addr_cycle: begin
                    addr_is_atomic  = 0;
                    _rd_data = mcycle[31:0];
                end
                rv32::csr_addr_cycleh: begin
                    addr_is_atomic  = 0;
                    _rd_data = mcycle[63:32];
                end
                rv32::csr_addr_instret: begin
                    addr_is_atomic  = 0;
                    _rd_data = minstret[31:0];
                end
                rv32::csr_addr_instreth: begin
                    addr_is_atomic  = 0;
                    _rd_data = minstret[63:32];
                end
                rv32::csr_addr_time: begin
                    addr_is_atomic  = 0;
                    _rd_data = time_rd_data[31:0];
                end
                rv32::csr_addr_timeh: begin
                    addr_is_atomic  = 0;
                    _rd_data = time_rd_data[63:32];
                end
                default: begin
                    _rd_data = 0;
                    addr_is_illegal = 1;
                end
            endcase
            // Supervisor-Mode CSRs
            if (addr_is_illegal && priv >= rv32::SMODE) begin
                addr_is_illegal = 0;
                case (rd_addr)
                    default: begin
                        addr_is_atomic  = 0;
                        addr_is_illegal = 1;
                        _rd_data = 0;
                    end
                endcase
            end // if (priv >= smode)
            // Machine-Mode CSRs
            if (addr_is_illegal && priv >= rv32::MMODE) begin
                addr_is_illegal = 0;
                case (rd_addr)
                    rv32::csr_addr_misa: begin
                        addr_is_atomic  = 0;
                        _rd_data = misa;
                    end
                    rv32::csr_addr_mvendorid: begin
                        addr_is_atomic  = 0;
                        _rd_data = mvendorid;
                    end
                    rv32::csr_addr_marchid: begin
                        addr_is_atomic  = 0;
                        _rd_data = marchid;
                    end
                    rv32::csr_addr_mimpid: begin
                        addr_is_atomic  = 0;
                        _rd_data = mimpid;
                    end
                    rv32::csr_addr_mhartid: begin
                        addr_is_atomic  = 0;
                        _rd_data = mhartid;
                    end
                    rv32::csr_addr_mstatus: begin
                        addr_is_atomic  = 1;
                        _rd_data = mstatus[31:0];
                    end
                    rv32::csr_addr_mstatush: begin
                        addr_is_atomic  = 1;
                        _rd_data = mstatus[63:32];
                    end
                    rv32::csr_addr_mtvec: begin
                        addr_is_atomic  = 1;
                        _rd_data = mtvec;
                    end
                    rv32::csr_addr_mip: begin
                        addr_is_atomic  = 1;
                        _rd_data = mip;
                    end
                    rv32::csr_addr_mie: begin
                        addr_is_atomic  = 1;
                        _rd_data = mie;
                    end
                    rv32::csr_addr_mcycle: begin
                        addr_is_atomic  = 1;
                        _rd_data = mcycle[31:0];
                    end
                    rv32::csr_addr_mcycleh: begin
                        addr_is_atomic  = 1;
                        _rd_data = mcycle[63:32];
                    end
                    rv32::csr_addr_minstret: begin
                        addr_is_atomic  = 1;
                        _rd_data = minstret[31:0];
                    end
                    rv32::csr_addr_minstreth: begin
                        addr_is_atomic  = 1;
                        _rd_data = minstret[63:32];
                    end
                    rv32::csr_addr_mcountinhibit: begin
                        addr_is_atomic  = 1;
                        _rd_data = mcountinhibit;
                    end
                    rv32::csr_addr_mscratch: begin
                        addr_is_atomic  = 0;
                        _rd_data = mscratch;
                    end
                    rv32::csr_addr_mepc: begin
                        addr_is_atomic  = 1;
                        _rd_data = mepc;
                    end
                    rv32::csr_addr_mcause: begin
                        addr_is_atomic  = 0;
                        _rd_data = mcause;
                    end
                    rv32::csr_addr_mtval: begin
                        addr_is_atomic  = 0;
                        _rd_data = mtval;
                    end
                    rv32::csr_addr_mconfigptr: begin
                        addr_is_atomic  = 0;
                        _rd_data = mconfigptr;
                    end
                    default: begin
                        addr_is_atomic  = 0;
                        _rd_data = 0;
                        addr_is_illegal = 1;
                    end
                endcase
            end // if(priv >= mmode)
            // else omitted because it is covered by User-Mode default case
            // Apply read enable and data bypass
            rd_data = (wr_en && (rd_addr==wr_addr))
                    ? wr_data
                    : _rd_data;
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Combinatorial Logic
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Write & Counter Logic
    ////////////////////////////////////////////////////////////
    logic [rv32::XLEN-1:16] _interrupt_buff;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            priv <= rv32::MMODE;
            // CSR reset values
            mstatus.MBE     <= 0;
            mstatus.MPRV    <= 0;
            mstatus.MPP     <= rv32::UMODE;
            mstatus.MPIE    <= 1;
            mstatus.UBE     <= 0;
            mstatus.MIE     <= 1;
            mtvec           <= 0;
            mip[rv32::XLEN-1:16] <= 0;
            mie[rv32::XLEN-1:16] <= 0;
            mie.MTI         <= 0;
            mcycle          <= 0;
            minstret        <= 0;
            mcountinhibit   <= 0;
            mscratch        <= 0;
            mepc            <= 0;
            mcause          <= 0;
            mtval           <= 0;
            _interrupt_buff     <= 0;
        end
        else begin

            // mcycle behavior, overwritten by CSR write instructions
            if (!mcountinhibit.CY) begin
                mcycle <= mcycle + 1;
            end

            // minstret behavior, overwritten by CSR write instructions
            if (!mcountinhibit.IR) begin
                if (!stall_exec & !bubble_exec) begin
                    minstret <= minstret + 1;
                end
            end

            if (wr_en & !stall_exec & !bubble_exec) begin
                // User-Mode CSRs
                case (wr_addr)
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
                    default: begin
                        // nothing
                    end
                endcase
                // Machine-Mode CSRs
                if (priv >= rv32::MMODE) begin
                    case (wr_addr)
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
                            mstatus.MPRV    <= wr_data[17];
                            mstatus.MPP     <= rv32::priv_mode_t'(wr_data[12:11]);
                            mstatus.MPIE    <= wr_data[7];
                            mstatus.UBE     <= wr_data[6];
                            mstatus.MIE     <= wr_data[3];
                        end
                        rv32::csr_addr_mstatush: begin
                            mstatus.MBE     <= wr_data[5];
                        end
                        rv32::csr_addr_mtvec: begin
                            if (wr_data[1:0] == rv32::MTVEC_MODE_VECTORED) begin
                                localparam _msb = rv32::XLEN-1;
                                localparam _lsb = MTVEC_ADDR_BIT_ALIGN;
                                mtvec[1:0]      <= wr_data[1:0];
                                mtvec[_lsb-1:2] <= 0;
                                mtvec[_msb:_lsb]<= wr_data[_msb:_lsb];
                            end
                            else begin // default invalid modes to direct
                                mtvec[1:0]  <= rv32::MTVEC_MODE_DIRECT;
                                mtvec[rv32::XLEN-1:2] <= wr_data[rv32::XLEN-1:2];
                            end
                        end
                        rv32::csr_addr_mip: begin
                            mip[rv32::XLEN-1:16] <= wr_data[rv32::XLEN-1:16];
                        end
                        rv32::csr_addr_mie: begin
                            mie[rv32::XLEN-1:16] <= wr_data[rv32::XLEN-1:16];
                            mie.MTI <= wr_data[7];
                        end
                        rv32::csr_addr_mcycle: begin
                            mcycle[31:0] <= wr_data;
                        end
                        rv32::csr_addr_mcycleh: begin
                            mcycle[63:32] <= wr_data;
                        end
                        rv32::csr_addr_minstret: begin
                            minstret[31:0] <= wr_data;
                        end
                        rv32::csr_addr_minstreth: begin
                            minstret[63:32] <= wr_data;
                        end
                        rv32::csr_addr_mcountinhibit: begin
                            mcountinhibit <= wr_data;
                        end
                        rv32::csr_addr_mscratch: begin
                            mscratch <= wr_data;
                        end
                        rv32::csr_addr_mepc: begin
                            mepc[rv32::XLEN-1:2] <= wr_data[rv32::XLEN-1:2];
                        end
                        rv32::csr_addr_mcause: begin
                            mcause <= wr_data;
                        end
                        rv32::csr_addr_mtval: begin
                            mtval <= wr_data;
                        end
                        rv32::csr_addr_mconfigptr: begin
                            // read-only
                        end
                        default: begin
                            // nothing
                        end
                    endcase
                end // if(priv >= mmode)
            end // if(wr_en)

            // process interrupt sources
            if (atomic_csr_pending & !bubble_exec) begin
                // interrupts are disabled, new interrupts are buffered
                _interrupt_buff = int_sources[rv32::XLEN-1:16]; // use blocking assignment
                if (!bubble_exec) begin
                    // write buffered interrupts
                    mip[rv32::XLEN-1:16] <= _interrupt_buff | mip[rv32::XLEN-1:16];
                end
            end
            else begin
                // normal interrupt behavior
                mip[rv32::XLEN-1:16] <= int_sources[rv32::XLEN-1:16];
            end

            // trap behavior, overwrites CSR write instructions
            if (trap_insert) begin
                if (trap_is_mret) begin
                    priv            <= mstatus.MPP;
                    mstatus.MIE     <= mstatus.MPIE;
                    mstatus.MPIE    <= 1;
                    mstatus.MPP     <= rv32::UMODE;
                    if (mstatus.MPP != rv32::MMODE) begin
                        mstatus.MPRV <= 0;
                    end
                end
                else begin
                    mstatus.MPIE    <= mstatus.MIE;
                    mstatus.MIE     <= 0;
                    mstatus.MPP     <= priv;
                    mepc            <= trap_epc;
                    mcause          <= trap_cause;
                    mtval           <= trap_val;
                end
            end

        end
    end
    ////////////////////////////////////////////////////////////
    // END: Write Logic
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

endmodule