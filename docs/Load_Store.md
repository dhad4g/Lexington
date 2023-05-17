# Load/Store Unit

The Load/Store Unit (LSU) interfaces the core with RAM data memory.
When a load or store instruction is issued, it moves data between the register file and data memory.
This implementation uses purely combinatorial logic


## Ports

#### Parameters

- **`WIDTH = 32`** data width
- **`RAM_ADDR_WIDTH = 10`** word-addressable address width matching size of RAM (4kB)

#### Inputs

- **`mem_en_i`** memory access enable
- **`reg_wr_en_i`** register file write enable input
- **`alu_data[WIDTH-1:0]`** data from ALU or calculated memory address
- **`src2[WIDTH-1:0]`** src2 value for store instruction
- **`mem_rd_data[WIDTH-1:0]`** data from memory
- **`dest_addr_i[5:0]`** destination register

#### Outputs

- **`reg_wr_en_o`** register file write enable output
- **`reg_wr_data[WIDTH-1:0]`** register file write data
- **`reg_wr_addr[5:0]`** register file write address
- **`mem_rd_addr[RAM_ADDR_WIDTH-1:0]`** memory read address (word-addressable)
- **`mem_rd_en_o`** memory read enable
- **`mem_wr_addr[RAM_ADDR_WIDTH-1:0]`** memory write address (word-addressable)
- **`mem_wr_data[WIDTH-1:0]`** memory write data
- **`mem_wr_en_o`** memory write enable
- **`misaligned`** asserted if memory address is not 4-byte aligned
- **`access_fault`** asserted if the memory address is outside the address space of the RAM


## Behavior

The LSU performs three tasks:
1. Write the result of ALU operations to the register file
2. Store data from the register file to memory
3. Load data from memory to the register file

Additionally, it detects and signals misaligned memory accesses as well as memory access faults.
The `misaligned` flag should be asserted if `mem_en_i` is high and the address from `alu_data` is not four-byte aligned.
The `access_fault` flag should be asserted if `mem_en_i` is high and the address from `alu_data` has any bit at or higher than bit `RAM_ADDR_WIDTH` set.
If either `misaligned` or `access_fault` is asserted, the outputs `reg_wr_en_o`, `mem_rd_en_o`, and `mem_wr_en_o` should all be low.

The `mem_en_i` and `reg_wr_en_i` control the operation of the LSU.
Table 1. shows how these signal control its behavior.

**Table 1.** LSU operations
| `mem_en_i` | `reg_wr_en_i` | | operation |
| --- | --- | - | --- |
| 0 | 0 | | nop |
| 0 | 1 | | write ALU output to destination register
| 1 | 0 | | store src2 value to memory
| 1 | 1 | | load from memory to destination register
