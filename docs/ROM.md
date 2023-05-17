# Read-Only Memory (ROM)

The ROM servers as the CPU's program instruction memory.
It features asynchronous reads and is programed at device reset.

## Ports

#### Parameters

- **`WIDTH = 32`** data width
- **`ADDR_WIDTH = 10`** word-addressable address width (4kB)

#### Inputs

- **`rd_en`** read enable
- **`rd_addr[ADDR_WIDTH-1:0]`** word-addressable address

#### Outputs

- **`rd_data[WIDTH-1:0]`** read data
