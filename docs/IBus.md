# Instruction Bus (IBus)

The instruction bus connects the CPU's Fetch Unit to program memory.
It uses purely combinatorial logic.


## Ports

### Parameters

- **`XLEN=32`** data width (from rv32)
- **`ROM_ADDR_WIDTH = 10`** ROM address width (word-addressable, default 4kB)
- **`ROM_BASE_ADDR = 0x0000_0000`** ROM base address (must be aligned to ROM size)

### Inputs

- **`rd_en`** read enable flag from Fetch Unit
- **`addr[XLEN-1:0]`** read address from Fetch Unit (byte-addressable)
- **`rom_rd_data[XLEN-1:0]`** read data from ROM

### Outputs

- **`rom_rd_en`** read enable flag to ROM
- **`rom_addr[ROM_ADDR_WIDTH-1:0]`** read address to ROM (word-addressable)
- **`rd_data[XLEN-1:0]`** read data to Fetch Unit
- **`inst_access_fault`** instruction access fault exception flag


## Behavior

If `addr` is in the ROM address space, then ROM is read and the data passed to the Fetch Unit via `rd_data`.
The `inst_access_fault` flag is kept low in this case.
If `addr` is not in the ROM address space, then `rom_rd_en` is set low and `inst_access_fault` is asserted high.

***Note:** the lower two bits of `addr` are ignored as instruction address misaligned exceptions should be caught during control transfer (jump/branch) instructions.*

