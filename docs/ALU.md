# Arithmetic Logic Unit (ALU)

The ALU conducts calculation and comparison operations for the core.
It is purely combinatorial logic.


## Ports

#### Parameters

- **`WIDTH=32`** data width

*Local Parameters*

- `ALU_ADD=4'b0000` add
- `ALU_SLL=4'b0001` shift left logical
- `ALU_SLTU=4'b0010` set if less than unsigned
- `ALU_SGEU=4'b0011` set if greater than or equal unsigned
- `ALU_XOR=4'b0100` XOR
- `ALU_SRL=4'b0101` shift right logical
- `ALU_OR=4'b0110`  OR
- `ALU_AND=4'b0111` AND
- `ALU_SUB=4'b1000` subtract
- `ALU_SLT=4'b1010` set if less than signed
- `ALU_SGE=4'b1011` set if greater than or equal signed
- `ALU_SRA=4'b1101` shift right arithmetic

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
