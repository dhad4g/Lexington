# Fetch

The Instruction Fetch Unit reads the next instruction from the program memory via the instruction bus (ibus).
This implementation is purely combinatorial.


## Ports

#### Parameters

- **`WIDTH = 32`** data width
- **`ROM_ADDR_WIDTH = 10`** word-addressable address width matching size of ROM (4kB)

#### Inputs

- **`pc[WIDTH-1:0]`** current value of the program counter
- **`ibus_rd_data[WIDTH-1:0]`** read data from ibus

#### Outputs
- **`inst[WIDTH-1:0]`** current instruction bits
- **`ibus_rd_en`** ibus read enable
- **`ibus_rd_addr[ROM_ADDR_WIDTH-1:0]`** ibus read address (word-addressable)
- **`access_fault`** asserted if the PC is outside the ibus address space


## Behavior

Instruction fetching occurs as combinatorial logic.
The responsibility of the Instruction Fetch Unit is then only to detect instruction address misaligned and access fault exceptions.
