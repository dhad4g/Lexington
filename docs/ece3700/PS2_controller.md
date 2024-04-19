# PS/2 Keyboard Controller

This is a submodule to the [PS/2](PS2.md) module. It is deserializes the PS/2
signals from the keyboard and hands the data to the PS/2 module.


## Ports

### Inputs

- **`clk`** Main clock signal
- **`rst_n`** Active-low synchronous reset

- **`ps2_clk`** The PS/2 clock signal
- **`ps2_data`** The PS/2 data signal

### Outputs

- **`data[7:0]`** Deserialized data
- **`valid`** Asserted for one clock cycle when data is received
- **`err`** (optional) Asserted along with the `valid` signal if the parity bit
            was incorrect.


## Behavior
