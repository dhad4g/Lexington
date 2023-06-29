# AXI4-Lite Crossbar

The AXI4-Lite Crossbar connects multiple subordinates to a single manager.


## Ports

### Parameters

- **`WIDTH = 32`** data width
- **`ADDR_WIDTH = 32`** address width

### Inputs

- **`axi_crossbar_s`** subordinate interface to connect to upstream manager

### Outputs

- **`axi_crossbar_m01`** manager interface to connect to downstream subordinate 1
- **`axi_crossbar_m02`** manager interface to connect to downstream subordinate 2
- **`axi_crossbar_m03`** manager interface to connect to downstream subordinate 3
- **`axi_crossbar_m04`** manager interface to connect to downstream subordinate 4


## Behavior

**TODO**

### Memory Map

**Table 1.** Memory Mapped I/O
| Address | Device | Description |
| --- | --- | --- |
| 0xFFFF_FF00 | `timer0` |
| 0xFFFF_FF04 | `timer1` |
| 0xFFFF_FFA0 - 0xFFFF_FFAF | `GPIOA` |
