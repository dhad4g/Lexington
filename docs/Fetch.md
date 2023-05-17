# Fetch

The Instruction Fetch Unit reads the next instruction from the program memory.
This implementation is purely combinatorial.


## Ports

#### Parameters

- **`WIDTH = 32`** data width
- **`ROM_ADDR_WIDTH = 10`** word-addressable address width matching size of ROM (4kB)

#### Inputs

- **`pc[WIDTH-1:0]`** current value of the program counter
- **`mem_rd_data[WIDTH-1:0]`** data from the program memory ROM

#### Outputs
- **``**
- **`inst[WIDTH-1:0]`** current instruction
- **`mem_rd_addr[ROM_ADDR_WIDTH-1:0]`** memory read address (word-addressable)
- **`mem_rd_en`** memory read enable
- **`misaligned`** asserted if the PC value is not 4-byte aligned
- **`access_fault`** asserted if the PC is outside the address space of the ROM


## Behavior

Instruction fetching occurs as combinatorial logic.
The responsibility of the Instruction Fetch Unit is then only to detect instruction address misaligned and access fault exceptions.
