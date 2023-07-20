# Read-Only Memory (ROM)

The ROM servers as the CPU's program instruction memory.
It features dual asynchronous read ports.

## Ports

#### Parameters

- **`WIDTH = 32`** data width (from rv32)
- **`ADDR_WIDTH = 10`** word-addressable address width (default 4kB)

#### Inputs

- **`rd_en1`** read enable 1
- **`addr1[ADDR_WIDTH-1:0]`** read address 1 (word-addressable)
- **`rd_en2`** read enable 2
- **`addr2[ADDR_WIDTH-1:0]`** read address 2 (word-addressable)

#### Outputs

- **`rd_data1[WIDTH-1:0]`** read data 1
- **`rd_data2[WIDTH-1:0]`** read data 2


## Behavior

The ROM is programmed using vendor-specific methods.
