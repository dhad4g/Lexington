# Load/Store Unit

The Load/Store Unit (LSU) interfaces the CPU with the following data sources:
- Writes to the Register File
- Writes to CSRs
- Read/Write access to the Data Bus (dbus)

Any instruction writing to the register file does so through the LSU.
Load and store instructions move data between the register file and data memory.
CSR instructions save data to the register file and optionally write to a CSR.

This implementation uses purely combinatorial logic


## Ports

#### Parameters

- **`XLEN = 32`** data width (from rv32)
- **`REG_ADDR_WIDTH = 5`** register address width (from rv32)
- **`CSR_ADDR_WIDTH = 12`** CSR address width (from rv32)

#### Inputs

- **`lsu_op[3:0]`** encodes lsu operation
- **`alu_result[XLEN-1:0]`** data from ALU or calculated memory address
- **`alt_data[XLEN-1:0]`** data source for store and CSR read instructions
- **`dest_addr[REG_ADDR_WIDTH-1:0]`** destination register
- **`dbus_rd_data[XLEN-1:0]`** data from memory
- **`endianness`** data memory endianness (0=little,1=big)

#### Outputs

- **`dest_en`** register file write enable output
- **`dest_data[XLEN-1:0]`** register file write data
- **`dbus_rd_en`** data bus read enable
- **`dbus_wr_en`** data bus write enable
- **`dbus_addr[XLEN-1:0]`** memory read address (byte-addressable)
- **`dbus_wr_data[XLEN-1:0]`** memory write data
- **`dbus_wr_strobe[(XLEN/8)-1:0]`** write strobes, indicate which byte lanes hold valid data
- **`csr_wr_en`** CSR write enable
- **`csr_wr_data`** CSR write data


## Behavior

The `lsu_op` signal controls the operation of the LSU.
Control encoding is shown in Table 1.
The output truth table is shown in Table 2.

*Note: CSR address is handled by decode*

**Table 1.** LSU operations

| `lsu_op` | Name | Operation |
| --- | --- | --- |
| 0000 | LSU_LB     | Load **sign-extended** byte (8-bit) from memory at `alu_result` to `dest_reg`
| 0001 | LSU_LH     | Load **sign-extended** half-word (16-bit) from memory at `alu_result` to `dest_reg`
| 0010 | LSU_LW     | Load word (32-bit) from memory at `alu_result` to `dest_reg`
| 0011 | *reserved* | undefined *(reserved for 64-bit)*
| 0100 | LSU_LBU    | Load **zero-extended** byte (8-bit) from memory at `alu_result` to `dest_reg`
| 0101 | LSU_LHU    | Load **zero-extended** half-word (16-bit) from memory at `alu_result` to `dest_reg`
| 0110 | *reserved* | undefined *(reserved for 64-bit)*
| 0111 | *reserved* | undefined
| 1000 | LSU_SB     | Store byte (8-bit) of `ald_data` to memory at `alu_result`
| 1001 | LSU_SH     | Store half-word (16-bit) of `ald_data` to memory at `alu_result`
| 1010 | LSU_SW     | Store word (32-bit) of `ald_data` to memory at `alu_result`
| 1011 | *reserved* | undefined *(reserved for 64-bit)*
| 1100 | LSU_CSRR   | CSR read-only; Save `alt_data` to `dest_reg`
| 1101 | LSU_CSRRW  | CSR read/write: Save `alt_data` to `dest_reg`, and write `alu_result` to CSR
| 1110 | LSU_REG    | Save `alu_result` to `dest_reg`
| 1111 | LSU_NOP    | Do nothing

**Table 2.** LSU truth table

| Port | Output Logic |
| --- | --- |
| `dest_en`         | asserted for ops writing to Register File
| `dest_data`       | routed based on Table 1 *(endian corrected)*
| `dbus_rd_en`      | high if lsu_op is a load, else low
| `dbus_wr_en`      | high if lsu_op is a store, else low
| `dbus_addr`       | `alu_result`
| `dbus_wr_data`    | `alt_data` *(endian corrected)*
| `csr_wr_en`       | `lsu_op` == LSU_CSRRW
| `csr_wr_data`     | `alu_result`

### Memory Mapped Devices

Memory mapped system devices and peripherals are handled the the DBus and AXI interface respectively.
The address map tables for each can be found in the [DBus](./DBus.md) and [AXI4-Lite Crossbar](./AXI4-Lite_Crossbar.md) documents.
