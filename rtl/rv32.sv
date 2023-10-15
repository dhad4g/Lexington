`ifndef __RV32_SV
`define __RV32_SV

package rv32;

    localparam XLEN                 = 32;       // data width, word size in bits
    localparam REG_ADDR_WIDTH       = 5;        // register address width
    localparam CSR_ADDR_WIDTH       = 12;       // CSR address width

    localparam BYTES_IN_WORD        = XLEN / 8;                     // number of bytes in XLEN word
    localparam ADDR_BITS_IN_WORD    = $clog2(BYTES_IN_WORD);        // number of address bits used by XLEN word
    localparam REG_COUNT            = 2 ** rv32::REG_ADDR_WIDTH;

    localparam MTVEC_MODE_DIRECT    = 2'b00;
    localparam MTVEC_MODE_VECTORED  = 2'b01;

    typedef logic [XLEN-1:0] word;
    typedef logic signed [XLEN-1:0] signed_word;

    typedef logic [REG_ADDR_WIDTH-1:0] gpr_addr_t;
    typedef logic [CSR_ADDR_WIDTH-1:0] csr_addr_t;


    typedef enum csr_addr_t {
        csr_addr_misa           = 12'h301,
        csr_addr_mvendorid      = 12'hF11,
        csr_addr_marchid        = 12'hF12,
        csr_addr_mimpid         = 12'hF13,
        csr_addr_mhartid        = 12'hF14,
        csr_addr_mstatus        = 12'h300,
        csr_addr_mstatush       = 12'h310,
        csr_addr_mtvec          = 12'h305,
        csr_addr_mip            = 12'h344,
        csr_addr_mie            = 12'h304,
        csr_addr_mcycle         = 12'hB00,
        csr_addr_mcycleh        = 12'hB80,
        csr_addr_cycle          = 12'hC00,
        csr_addr_cycleh         = 12'hC80,
        csr_addr_minstret       = 12'hB02,
        csr_addr_minstreth      = 12'hB82,
        csr_addr_instret        = 12'hC02,
        csr_addr_instreth       = 12'hC82,
        csr_addr_mcountinhibit  = 12'h320,
        csr_addr_mscratch       = 12'h340,
        csr_addr_mepc           = 12'h341,
        csr_addr_mcause         = 12'h342,
        csr_addr_mtval          = 12'h343,
        csr_addr_mconfigptr     = 12'hF15,
        csr_addr_time           = 12'hC01,
        csr_addr_timeh          = 12'hC81
    } CSR_ADDR;


    // RISC-V privilege is encoded as a 2-bit value
    typedef enum logic [1:0] {
        UMODE   = 2'b00,    // user-mode
        SMODE   = 2'b01,    // supervisor-mode
        MMODE   = 2'b11     // machine-mode
    } priv_mode_t;


    // Interrupts and Exceptions
    localparam TRAP_CODE_NMI                    = 0;        // non-maskable interrupt
    localparam TRAP_CODE_SSI                    = 1;        // supervisor software interrupt
    localparam TRAP_CODE_MSI                    = 3;        // machine software interrupt
    localparam TRAP_CODE_STI                    = 5;        // supervisor timer interrupt
    localparam TRAP_CODE_MTI                    = 7;        // machine timer interrupt
    localparam TRAP_CODE_SEI                    = 9;        // supervisor external interrupt
    localparam TRAP_CODE_MEI                    = 11;       // machine external interrupt
    localparam TRAP_CODE_INST_MISALIGNED        = 0;        // instruction address misaligned exception
    localparam TRAP_CODE_INST_ACCESS_FAULT      = 1;        // instruction access fault exception
    localparam TRAP_CODE_ILLEGAL_INST           = 2;        // illegal instruction exception
    localparam TRAP_CODE_BREAKPOINT             = 3;        // breakpoint exception
    localparam TRAP_CODE_LOAD_MISALIGNED        = 4;        // load address misaligned exception
    localparam TRAP_CODE_LOAD_ACCESS_FAULT      = 5;        // load access fault exception
    localparam TRAP_CODE_STORE_MISALIGNED       = 6;        // store address misaligned exception
    localparam TRAP_CODE_STORE_ACCESS_FAULT     = 7;        // store access fault exception
    localparam TRAP_CODE_ENV_CALL_UMODE         = 8;        // environment call from u-mode exception
    localparam TRAP_CODE_ENV_CALL_SMODE         = 9;        // environment call from s-mode exception
    localparam TRAP_CODE_ENV_CALL_MMODE         = 11;       // environment call form m-mode exception
    localparam TRAP_CODE_INST_PAGE_FAULT        = 12;       // instruction page fault exception
    localparam TRAP_CODE_LOAD_PAGE_FAULT        = 13;       // load page fault exception
    localparam TRAP_CODE_STORE_PAGE_FAULT       = 15;       // store page fault exception

endpackage

`endif //__RV32_SV
