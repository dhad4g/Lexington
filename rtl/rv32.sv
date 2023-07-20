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

endpackage

`endif //__RV32_SV
