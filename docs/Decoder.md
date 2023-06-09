# Decoder

The decoder constitutes a large portion of the core's logical and generates control signal for many of the other submodules.
It uses purely combinatorial logic.

## Ports

#### Parameters

- **`WIDTH = 32`** data width

#### Inputs

- **`inst[WIDTH-1:0]`** instruction from fetch
- **`pc[WIDTH-1:0]`** current program counter
- **`rd1_data[WIDTH-1:0]`** register file read data 1
- **`rd2_data[WIDTH-1:0]`** register file read data 2
- **`alu_zero`** zero flag from ALU

#### Outputs

- **`next_pc[WIDTH-1:0]`** next value of program counter
- **`rd1_addr[5:0]`** address for register file read 1
- **`rd2_addr[5:0]`** address for register file read 2
- **`dest_addr[5:0]`** address for register file write
- **`src1[WIDTH-1:0]`** ALU left-side operand
- **`src2[WIDTH-1:0]`** ALU right-side operand
- **`alu_op[3:0]`** ALU operation select
- **`lsu_mem_en`** load/store memory access enable
- **`lsu_reg_wr_en`** load/store register file write enable
- **`exception`** exception flag


## Behavior

The decoder receives the ISA binary instruction from the Instruction Fetch Unit and decodes it to the microarchitecture control signals.
ALU microarchitecture opcodes are found in the [ALU](./ALU.md) documentation.


#### OP/OP-IMM Instructions

| `instr[30]` | funct3 `instr[14:12]` | Instruction | Description |
| --- | --- | --- | --- |
| 0 | 000 | ADD[I]  | Addition |
| 1 | 000 | SUB |   | Subtraction |
|   | 001 | SLL[I]  | Shift Left Logical |
|   | 010 | SLT[I]  | Set Less Than |
|   | 011 | SLT[I]U | Set Less Than Unsigned |
|   | 100 | XOR[I]  | Bitwise XOR |
| 0 | 101 | SRL[I]  | Shift Right Logical |
| 1 | 101 | SRA[I]  | Shift Right Arithmetic |
|   | 110 | OR[I]   | Bitwise OR |
|   | 111 | AND[I]  | Bitwise AND |

#### Branch Instructions

| funct3 `instr[14:12]` | Instruction | Description |
| --- | --- | --- |
| 000 | BEQ  | Branch If Equal |
| 001 | BNE  | Branch If Not Equal |
| 100 | BLT  | Branch If Less Than |
| 101 | BGE  | Branch If Greater Than or Equal |
| 110 | BLTU | Branch If Less Than Unsigned |
| 111 | BGEU | Branch If Greater Than or Equal Unsigned |

#### Load/Store Instructions

| funct3 `instr[14:12]` | Instruction | Description |
| --- | --- | ---
| 000 | LB  | Load Byte (8-bits) |
| 001 | LH  | Load Half-Word (16-bits) |
| 010 | LW  | Load Word (32-bits) |
| 100 | LBU | Load Byte Unsigned (8-bits) |
| 101 | LHU | Load Half-Word Unsigned (16-bits) |
| 000 | SB  | Store Byte (8-bits) |
| 001 | SH  | Store Half-Word (16-bits) |
| 010 | SW  | Store Word (32-bits) |


#### System Instructions

| `inst[31:20]` | funct3 `instr[14:12]` | Instruction | Description |
| --- | --- | --- | --- |
| 001100000010 | 000 | MRET | Machine-mode return |
| 0..0  | 000 | ECALL  | Environment call |
| 0..01 | 000 | EBREAK | Environment break |
| `csr` | 001 | CSRRW  | CSR read & write |
| `csr` | 010 | CSRRS  | CSR read & set |
| `csr` | 011 | CSRRC  | CSR read & clear |
| `csr` | 101 | CSRRWI | CSR read & write immediate |
| `csr` | 110 | CSRRSI | CSR read & set immediate |
| `csr` | 111 | CSRRCI | CSR read & clear immediate |

###### `MRET` Instruction

Machine mode trap return instruction.
It sets the `pc` to the value stored in `mepc`

###### `ECALL` and `EBREAK` Instructions

The `ECALL` instruction generates an environment-call-from-M-mode exception.

The `EBREAK` instruction generates a breakpoint exception.

Sets the `mepc` CSR to the address of *this* instruction.
This instruction is not considered retired and should not increment `minstret` CSR.


###### `WFI` Instruction

The wait for interrupt (`WFI`) instruction is a microarchitecture hint instruction.
This implementation treats `WFI` as a `NOP`.




## Decoder Truth Table

| Instruction| funct7 `inst[31:25]` | funct3 `inst[14:12]` | ISA opcode | | `next_pc` | `alu_op` | `src1` | `src2` | `dest_addr` | `lsu_mem_en` | `lsu_reg_wr_en` | `exception` | | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD   | 0000000 | 000 | 0110011 (OP)       | | `pc`+4                  | ALU_ADD  | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| SUB   | 0100000 | 000 | 0110011 (OP)       | | `pc`+4                  | ALU_SUB  | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| SLL   | 0000000 | 001 | 0110011 (OP)       | | `pc`+4                  | ALU_SLL  | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| SLT   | 0000000 | 010 | 0110011 (OP)       | | `pc`+4                  | ALU_SLT  | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| SLTU  | 0000000 | 011 | 0110011 (OP)       | | `pc`+4                  | ALU_SLTU | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| XOR   | 0000000 | 100 | 0110011 (OP)       | | `pc`+4                  | ALU_XOR  | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| SRL   | 0000000 | 101 | 0110011 (OP)       | | `pc`+4                  | ALU_SRL  | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| SRA   | 0100000 | 101 | 0110011 (OP)       | | `pc`+4                  | ALU_SRA  | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| OR    | 0000000 | 110 | 0110011 (OP)       | | `pc`+4                  | ALU_OR   | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| AND   | 0000000 | 111 | 0110011 (OP)       | | `pc`+4                  | ALU_AND  | `rs1` | `rs2`        | `rd` | 0 | 1 | never |
| |
| ADDI  | 0000000 | 000 | 0010011 (OP-IMM)   | | `pc`+4                  | ALU_ADD  | `rs1` | `imm[11:0]`  | `rd` | 0 | 1 | never |
| SLLI  | 0000000 | 001 | 0010011 (OP-IMM)   | | `pc`+4                  | ALU_SLL  | `rs1` | `imm[4:0]`   | `rd` | 0 | 1 | never |
| SLTI  | 0000000 | 010 | 0010011 (OP-IMM)   | | `pc`+4                  | ALU_SLT  | `rs1` | `imm[11:0]`  | `rd` | 0 | 1 | never |
| SLTUI | 0000000 | 011 | 0010011 (OP-IMM)   | | `pc`+4                  | ALU_SLTU | `rs1` | `imm[11:0]`  | `rd` | 0 | 1 | never |
| XORI  | 0000000 | 100 | 0010011 (OP-IMM)   | | `pc`+4                  | ALU_XOR  | `rs1` | `imm[11:0]`  | `rd` | 0 | 1 | never |
| SRLI  | 0000000 | 101 | 0010011 (OP-IMM)   | | `pc`+4                  | ALU_SRL  | `rs1` | `imm[4:0]`   | `rd` | 0 | 1 | never |
| SRAI  | 0100000 | 101 | 0010011 (OP-IMM)   | | `pc`+4                  | ALU_SRA  | `rs1` | `imm[4:0]`   | `rd` | 0 | 1 | never |
| ORI   | 0000000 | 110 | 0010011 (OP-IMM)   | | `pc`+4                  | ALU_OR   | `rs1` | `imm[11:0]`  | `rd` | 0 | 1 | never |
| ANDI  | 0000000 | 111 | 0010011 (OP-IMM)   | | `pc`+4                  | ALU_AND  | `rs1` | `imm[11:0]`  | `rd` | 0 | 1 | never |
| |
| LUI   |         |     | 0110111 (LUI)      | | `pc`+4                  | ALU_ADD  | 0     | `imm[31:12]` | `rd` | 0 | 1 | never |
| AUIPC |         |     | 0010111 (AUIPC)    | | `pc`+4                  | ALU_ADD  | `pc`  | `imm[31:12]` | `rd` | 0 | 1 | never |
| |
| JAL   |         |     | 1101111 (JAL)      | | `pc`+`imm[20:1]`        | ALU_ADD  | `pc`  | 4            | `rd` | 0 | 1 | never (caught in fetch) | |
| JALR  |         |     | 1100111 (JALR)     | | `rs1[31:0]`+`imm[11:0]` | ALU_ADD  | `pc`  | 4            | `rd` | 0 | 1 | never (caught in fetch) | | lowest bit is ignored
| |
| BEQ   |         | 000 | 1100011 (BRANCH)   | | *see note ->            | ALU_XOR  | `rs1` | `rs2`        |      | 0 | 0 | never | | `next_pc` <= (`alu_zero`)  ? (`pc`+`imm[12:1]`) : (`pc`+4)
| BNE   |         | 001 | 1100011 (BRANCH)   | | *see note ->            | ALU_XOR  | `rs1` | `rs2`        |      | 0 | 0 | never | | `next_pc` <= (`!alu_zero`) ? (`pc`+`imm[12:1]`) : (`pc`+4)
| BLT   |         | 100 | 1100011 (BRANCH)   | | *see note ->            | ALU_SLT  | `rs1` | `rs2`        |      | 0 | 0 | never | | `next_pc` <= (`!alu_zero`) ? (`pc`+`imm[12:1]`) : (`pc`+4)
| BGE   |         | 101 | 1100011 (BRANCH)   | | *see note ->            | ALU_SGE  | `rs1` | `rs2`        |      | 0 | 0 | never | | `next_pc` <= (`!alu_zero`) ? (`pc`+`imm[12:1]`) : (`pc`+4)
| BLTU  |         | 110 | 1100011 (BRANCH)   | | *see note ->            | ALU_SLTU | `rs1` | `rs2`        |      | 0 | 0 | never | | `next_pc` <= (`!alu_zero`) ? (`pc`+`imm[12:1]`) : (`pc`+4)
| BGEU  |         | 111 | 1100011 (BRANCH)   | | *see note ->            | ALU_SGEU | `rs1` | `rs2`        |      | 0 | 0 | never | | `next_pc` <= (`!alu_zero`) ? (`pc`+`imm[12:1]`) : (`pc`+4)
| |
| FENCE   |       | 000 | 0001111 (MISC-MEM) | | `pc`+4                  | ALU_NOP  |       |              |      | 0 | 0 | never |
| FENCE.I |       | 001 | 0001111 (MISC-MEM) | | `pc`+4                  | ALU_NOP  |       |              |      | 0 | 0 | never |
| |
| LB    |         | 000 | 0000011 (LOAD)     | | `pc`+4                  | ALU_ADD | `rs1`  | `imm[11:0]`  |      | 0 | 1 | never (caught by LSU) |
| LH    |         | 001 | 0000011 (LOAD)     | | `pc`+4                  | ALU_ADD | `rs1`  | `imm[11:0]`  |      | 0 | 1 | never (caught by LSU) |
| LBU   |         | 100 | 0000011 (LOAD)     | | `pc`+4                  | ALU_ADD | `rs1`  | `imm[11:0]`  |      | 0 | 1 | never (caught by LSU) |
| LW    |         | 010 | 0000011 (LOAD)     | | `pc`+4                  | ALU_ADD | `rs1`  | `imm[11:0]`  |      | 0 | 1 | never (caught by LSU) |
| LHU   |         | 101 | 0000011 (LOAD)     | | `pc`+4                  | ALU_ADD | `rs1`  | `imm[11:0]`  |      | 0 | 1 | never (caught by LSU) |
| SB    |         | 000 | 0100011 (STORE)    | | `pc`+4                  | ALU_ADD | `rs1`  | `imm[11:0]`  |      | 0 | 1 | never (caught by LSU) |
| SH    |         | 001 | 0100011 (STORE)    | | `pc`+4                  | ALU_ADD | `rs1`  | `imm[11:0]`  |      | 0 | 1 | never (caught by LSU) |
| SW    |         | 010 | 0100011 (STORE)    | | `pc`+4                  | ALU_ADD | `rs1`  | `imm[11:0]`  |      | 0 | 1 | never (caught by LSU) |

