# Random Access Memory (RAM)

The RAM servers as the CPU's data memory.
It features asynchronous reads and synchronous writes.

## Ports

#### Parameters

- **`WIDTH = 32`** data width
- **`ADDR_WIDTH = 10`** word-addressable address width (4kB)

#### Inputs

- **`rd_en`** read enable
- **`rd_addr[ADDR_WIDTH-1:0]`** word-addressable address
- **`wr_en`** write enable
- **`wr_addr[ADDR_WIDTH-1:0]`** word-addressable address
- **`wr_data[WIDTH-1:0]`** write data

#### Outputs

- **`rd_data[WIDTH-1:0]`** read data
