# Read-Only Memory (ROM)

The ROM servers as the CPU's program instruction memory.
It features dual asynchronous read ports.

## Ports

#### Parameters

- **`WIDTH = 32`** data width
- **`ADDR_WIDTH = 10`** address width (word-addressable, 4kB)

#### Inputs

- **`ibus_rd_en`** instruction bus (ibus) read enable
- **`ibus_addr[ADDR_WIDTH-1:0]`** ibus address (word-addressable)
- **`dbus_rd_en`** data bus (dbus) read enable
- **`dbus_addr[ADDR_WIDTH-1:0]`** dbus address (word-addressable)

#### Outputs

- **`ibus_rd_data[WIDTH-1:0]`** ibus read data
- **`dbus_rd_data[WIDTH-1:0]`** dbus read data


## Behavior

The ROM is programmed using vendor-specific methods.
