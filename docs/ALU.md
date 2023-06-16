# Arithmetic Logic Unit (ALU)

The ALU conducts calculation and comparison operations for the core.
It is purely combinatorial logic.


## Ports

#### Parameters

- **`WIDTH=32`** data width

#### Inputs

- **`src1[WIDTH-1:0]`** left-side operand
- **`src2[WIDTH-1:0]`** right-side operand
- **`op[3:0]`** operation select

#### Outputs

- **`result[WIDTH-1:0]`** ALU operation result
- **`carry`** carry out flag
- **`zero`** result zero flag


## Behavior

The ALU performs the selected operation on the two input operands and puts the output on `result`.
The operation selection is decoded using the `ALU_*` local parameters.
Illegal operation select results in undefined behavior.

The output flags are set based on the result.
The carry output is set during add, subtract, or left shift operations.
For all other operations the carry output is undefined.
The zero output is always set as the bitwise or of all result bits.

**Table 1.** ALU Op Codes
| `alu_op`| Name | Operation |
| --- | --- | --- |
| 4'b0000 | ALU_ADD  | add
| 4'b0001 | ALU_SLL  | shift left logical
| 4'b0010 | ALU_SLTU | set if less than unsigned
| 4'b0011 | ALU_SGEU | set if greater than or equal unsigned
| 4'b0100 | ALU_XOR  | XOR
| 4'b0101 | ALU_SRL  | shift right logical
| 4'b0110 | ALU_OR   |  OR
| 4'b0111 | ALU_AND  | AND
| 4'b1000 | ALU_SUB  | subtract
| 4'b1010 | ALU_SLT  | set if less than signed
| 4'b1011 | ALU_SGE  | set if greater than or equal signed
| 4'b1101 | ALU_SRA  | shift right arithmetic
