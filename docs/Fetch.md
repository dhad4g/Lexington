# Fetch

The Instruction Fetch Unit reads the next instruction from the program memory via the instruction bus (ibus).
This implementation is purely combinatorial.


## Ports

#### Parameters

- **`XLEN = 32`** data width (from rv32)

#### Inputs

- **`pc[XLEN-1:0]`** current value of the program counter
- **`ibus_rd_data[XLEN-1:0]`** read data from ibus

#### Outputs
- **`inst[XLEN-1:0]`** current instruction bits
- **`ibus_rd_en`** ibus read enable
- **`ibus_addr[XLEN-1:0]`** ibus read address


## Behavior

This unit only asserts `ibus_rd_en`, passes the PC to `ibus_addr`, and passes the read data to the instruction [Decoder](./Decoder.md) via `inst`.
