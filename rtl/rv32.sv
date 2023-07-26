`ifndef __RV32_SV
`define __RV32_SV

package rv32;

    localparam XLEN                 = 32;       // data width, word size in bits
    localparam REG_ADDR_WIDTH       = 5;        // register address width
    localparam CSR_ADDR_WIDTH       = 12;       // CSR address width

    localparam BYTES_IN_WORD        = XLEN / 8;                     // number of bytes in XLEN word
    localparam ADDR_BITS_IN_WORD    = $clog2(BYTES_IN_WORD);           // number of address bits used by XLEN word
    localparam REG_COUNT            = 2 ** rv32::REG_ADDR_WIDTH;

    typedef logic [XLEN-1:0] word;
    typedef logic signed [XLEN-1:0] signed_word;

    typedef logic [REG_ADDR_WIDTH-1:0] reg_addr_t;
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
    // This implemetation uses a third bit to encode debug-mode
    typedef enum logic [2:0] {
        umode   = 3'b000,    // user-mode
        smode   = 3'b001,    // supervisor-mode
        mmode   = 3'b011,    // machine-mode
        dmode   = 3'b111     // debug-mode
    } priv_mode_t;

endpackage

`endif //__RV32_SV
