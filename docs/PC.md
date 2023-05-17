# Program Counter (PC)

This is the program counter to index the current instruction

## Ports

#### Parameters

- **`WIDTH = 32`** data width

#### Inputs

- **`en`** increment enable
- **`d[WIDTH-1:0]`** next program counter value

### Outputs

- **`q[WIDTH-1:0]`** current program counter value

## Behavior

If `incr_en` is high, `pc` is set to `incr_base`+`incr_offset`.
