# Data Bus (DBus)

The data bus connects the CPU's LSU to data memory and system peripherals.
It is purely combinatorial logic.


## Ports

### Parameters

- **`WIDTH=32`** data width
- **`ROM_ADDR_WIDTH = 10`** ROM address width (word-addressable, 4kB)
- **`RAM_ADDR_WIDTH = 10`** RAM address width (word-addressable, 4kB)

### Inputs

- **`rd_en`** read enable flag from LSU
- **`wr_en`** write enable flag from LSU
- **`addr[WIDTH-1:0]`** read/write address from LSU
- **`wr_data[WIDTH-1:0]`** write data from LSU
- **`rom_rd_data[WIDTH-1:0]`** ROM read data
- **`ram_rd_data[WIDTH-1:0]`** RAM read data
- **`mtime_rd_data[WIDTH-1:0]`** mtime module read data
- **`axi_rd_data[WIDTH-1:0]`** AXI interface read data
- **`axi_access_fault`** flag indicating AXI transaction access fault
- **`axi_wait`** flag indicating AXI transaction requires extra cycle

#### Outputs

- **`rd_data[WIDTH-1:0]`** read data to LSU
- **`access_fault`** access fault flag to LSU
- **`rom_rd_en`** ROM read enable
- **`rom_addr[]`** ROM address (word-addressable)
- **`ram_rd_en`** RAM read enable
- **`ram_wr_en`** RAM write enable
- **`ram_addr[RAM_ADDR_WIDTH-1:0]`** RAM address (word-addressable)
- **`ram_wr_data[WIDTH-1:0]`** RAM write data
- **`mtime_rd_en`** mtime module read enable
- **`mtime_wr_en`** mtime module write enable
- **`mtime_addr[1:0]`** mtime module address (word-addressable)
- **`mtime_wr_data[WIDTH-1:0]`** mtime module write data
- **`axi_rd_en`** AXI interface read enable
- **`axi_wr_en`** AXI interface write enable
- **`axi_addr[WIDTH-1:0]`** AXI interface address (byte-addressable)
- **`axi_wr_data[WIDTH-1:0]`** AXI interface write data
- **`dbus_wait`** flag indicating dbus transaction requires extra cycle


## Behavior

Addresses are decoded according to the [memory map](./Lexington.md), then transactions are routed to the appropriate device.
Output addresses are hardwired to the appropriate input address bits.
The read/write enable signals are controlled by a memory map address decoder.

The `dbus_wait` signal is hardwired to `axi_wait`.
This works because the AXI interface will not be active during non-AXI transactions.

### Memory Mapped Devices

The DBus routes read/write transactions to memory mapped system devices.
This implementation includes the machine timer (mtime).
The address map is located in Table 1.

**Table 1.** Memory Mapped System Devices

| Address | Device | Description |
| --- | --- | --- |
| 0xC000_000 - 0xC00_000F | `mtime` | system timer

Memory mapped peripheral devices are connected via the AXI interface.
The peripheral address map can be found in the [AXI4-Lite Crossbar](./AXI4-Lite_Crossbar.md) document.
