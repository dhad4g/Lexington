# AXI4-Lite Manager

The AXI4-Lite manager is the interface between the processing core data bus (DBus) and the system's AXI bus.
It converts DBus transaction to AXI4-Lite transactions.
This implementation uses combinatorial logic.

## Ports

### Parameters

- **`WIDTH = 32`** bus width (from rv32)
- **`ADDR_WIDTH`** address width
- **`TIMEOUT = 17`** bus timeout in number of cycles

### Inputs

- **`rd_en`** read enable from DBus
- **`wr_en`** write enable from DBus
- **`addr[ADDR_WIDTH-1:0]`** byte-addressable AXI address
- **`wr_data[WIDTH-1:0]`** write data from DBus
- **`wr_strobe[(WIDTH/8)-1:0]`** write strobe from DBus

### Outputs

- **`axi_m`** AXI4-Lite Manager interface
- **`rd_data[WIDTH-1:0]`** read data to DBus
- **`access_fault`** indicates either an invalid address or a AXI SLVERR response
- **`busy`** asserted when an AXI transaction is in progress and requires additional cycles to complete


## Behavior

When the `rd_en` or `wr_en` signal is asserted, an AXI read or write should be performed respectively.
This module should support simultaneous read and write transactions.

All transactions must complete within `TIMEOUT` number of cycles.
If a transaction does not complete within in this number of cycles, an `access_fault` exception is raised and the transaction is dropped.

While an AXI transaction is progress, the `busy` signal should be asserted.
It can be assumed that if the busy signal is asserted then the `rd_en` and `wr_en` signals will remain stable.
<!-- An example read transaction waveform  is shown in Figure 1. -->
The waveform depicts a load instruction immediately follows by another load instruction.
Notice how the `busy` signal extends these instructions across multiple cycles.
<!-- A complimentary write transaction waveform is shown in Figure 2. -->

<!-- ```wavedrom
{signal: [
    {name: 'clk',       wave: 'p.........'},
    {name: 'rd_en',     wave: '01...1...0'},
    {},
    {name: 'busy',      wave: '01..01..0.'},
    {name: 'rd_data',   wave: 'x...2x..2x'},
    {},
    {name: 'arvalid',   wave: '010..1.0..'},
    {name: 'arready',   wave: 'x1x..01x..'},
    {},
    {name: 'rvalid',    wave: '0...10..10'},
    {name: 'rready',    wave: '0.1..0.1.0'}
]}
```
**Figure 1.** Read transactions

```wavedrom
{signal: [
    {name: 'clk',       wave: 'p.........'},
    {name: 'wr_en',     wave: '01...1.0..'},
    {name: 'wr_data',   wave: 'x2...2.x..'},
    {},
    {name: 'busy',      wave: '01..010...'},
    {},
    {name: 'awvalid',   wave: '010..10...'},
    {name: 'awready',   wave: 'x1x..1x...'},
    {},
    {name: 'wvalid',    wave: '01.0.10...'},
    {name: 'wready',    wave: 'x01x.1x...'},
    {},
    {name: 'bvalid',    wave: '0...1010..'},
    {name: 'bready',    wave: '0..1.010..'}
]}
```
**Figure 2.** Write transactions -->
