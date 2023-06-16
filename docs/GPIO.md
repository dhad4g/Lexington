# General Purpose Input/Output (GPIO*x*)

There are 32 general purpose, memory mapped I/O ports.
All ports support both input and output.
There are two fully configurable interrupts that can be sourced from any of the 32 ports.
Interrupts support both edge and level triggers.

## Ports

### Parameters

- **`WIDTH=32`** data width
- **`BASE_ADDR=0xFFFF_FFA0`** base address for memory mapped registers

### In/Out

- **`io_pins[WIDTH-1:0]`** I/O pins

### Inputs

- **`rd_en`** read enable
- **`wr_en`** write enable
- **`rd_addr[3:2]`** read address (masked to address space)
- **`wr_addr[3:2]`** write address (masked to address space)
- **`wr_data[WIDTH-1:0]`** write data

### Outputs

- **`rd_data[WIDTH-1:0]`** read data
- **`int0`** interrupt 0
- **`int1`** interrupt 1


## Behavior

The behavior of the GPIO pins is determined by the memory mapped registers described in Table 1.
Write to these registers are synchronous, and reads are asynchronous.

**Table 1.** GPIO Memory Mapped Registers
| Address | Default Value | R/W | Name | Description |
| --- | --- | --- | --- | --- |
| 0xFFFF_FFA0 | 0 | r/w | `GPIOx_MODE`      | sets each pin as input or output (0=input,1=output)
| 0xFFFF_FFA4 | - | r/- | `GPIOx_IDATA`     | input value for each pin (0=low,1=high)
| 0xFFFF_FFA8 | 0 | r/w | `GPIOx_ODATA`     | output value for each pin (0=low,1=high)
| 0xFFFF_FFAC | 0 | r/w | `GPIOx_INT_CONF`  | interrupt configuration register

Bit *i* of the `mode`, `idata`, and `odata` registers corresponds to pin *i*.
Data in the `idata` register is read asynchronously from the I/O pins.
The *int_conf* register encoding is shown in Figure 1.

![](figures/GPIO_interrupt_register.drawio.svg)

**Figure 1.** `GPIOx_INT_CONF` register encoding

The int*x*_mode fields set the mode of interrupt *x*.

**Table 2.** GPIO Interrupt Modes
| Value | Mode | Description |
| --- | --- | --- |
| 0b000 | DISABLE | Disables the interrupt source |
| 0b100 | RISING  | Interrupt triggers on rising-edge |
| 0b101 | FALLING | Interrupt triggers on falling-edge |
| 0b110 | HIGH    | Interrupt triggers when high |
| 0b111 | LOW     | Interrupt triggers when low |
| *other* | *reserved* | 

The int*x*_pin fields select the source pin for interrupt *x*.
