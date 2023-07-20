# Random Access Memory (RAM)

The RAM servers as the CPU's data memory.
It features asynchronous reads and synchronous writes.

## Ports

### Parameters

- **`XLEN = 32`** data width (from rv32)
- **`ADDR_WIDTH = 10`** word-addressable address width (default 4kB)

### Inputs

- **`rd_en`** read enable
- **`wr_en`** write enable
- **`addr[ADDR_WIDTH-1:0]`** word-addressable address
- **`wr_data[XLEN-1:0]`** write data
- **`wr_strobe((XLEN/8)-1):0]`** write strobe, indicates which byte lanes hold valid data

### Outputs

- **`rd_data[XLEN-1:0]`** read data
