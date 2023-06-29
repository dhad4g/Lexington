# Program Counter (PC)

This is the program counter to index the current instruction

## Ports

#### Parameters

- **`WIDTH = 32`** data width

#### Inputs

- **`next_pc[WIDTH-1:0]`** next program counter value

### Outputs

- **`pc[WIDTH-1:0]`** current program counter value

## Behavior

The PC is a register that is always set to `next_pc` on the rising clock edge
Reset value is managed by the [Trap Unit](./Trap.md)
