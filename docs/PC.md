# Program Counter (PC)

This is the program counter to index the current instruction

## Ports

### Parameters

- **`XLEN = 32`** data width (from rv32)

### Inputs

- **`next_pc[XLEN-1:0]`** next program counter value

## Outputs

- **`pc[XLEN-1:0]`** current program counter value

## Behavior

The PC is a register that is always set to `next_pc` on the rising clock edge
Reset value is managed by the [Trap Unit](./Trap.md)
