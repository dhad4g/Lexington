# General Purpose Timer (timer*x*)

This is a general purpose 32-bit timer include:

- Output compare interrupt
- GPIO interrupt as count enable
- Prescaler to divide counter clock up to 4096

## Ports

### Parameters

- **`WIDTH=32`** data width
- **`BASE_ADDR=0xFFFF_FF00`** base address for memory mapped registers

### Inputs

- **`rd_en`** read enable
- **`wr_en`** write enable
- **`rd_addr[3:2]`** read address (masked to address space)
- **`wr_addr[3:2]`** write address (masked to address space)
- **`wr_data[WIDTH-1:0]`** write data
- **`gpio[WIDTH-1:0]`** GPIO pins for external clock source
- **`gpio_int0`** interrupt 0 from GPIO
- **`gpio_int1`** interrupt 1 from GPIO

### Outputs

- **`rd_data[WIDTH-1:0]`** read data
- **`int0`** interrupt signal


## Behavior

The timer behavior is configured by the memory mapped registers described in Table 1.
Writes to these registers are synchronous, and reads are asynchronous.

An interrupt is signaled when `TIMERx_COUNT` equals `TIMERx_COMPARE`.
To avoid a spurious interrupt, write both `TIMERx_COUNT` and `TIMERx_COMPARE` before enabling the timer.

**Table 1.** Timer Memory Mapped Registers

| Address | Default Value | R/W | Name | Description |
| --- | --- | --- | --- | --- |
| `BASE_ADDR` + 0x00 |   | r/w | `TIMERx_CTRL`      | control register
| `BASE_ADDR` + 0x04 | 0 | r/w | `TIMERx_COUNT`     | counter value
| `BASE_ADDR` + 0x08 | 0 | r/w | `TIMERx_COMPARE`   | compare value

**Table 2.** Timer `ctrl` register encoding

| Bit(s) | R/W | Name | Description |
| --- | --- | --- | --- |
| 0     | r/w | `TIMERx_CTRL_EN`        | Timer enable |
| 1     | r/w | `TIMERx_CTRL_MODE`      | Mode (0=continuous,1=loop) |
| 3:2   | r/w | `TIMERx_CTRL_PRSCL`     | 3-bit Prescaler select (see Table 3) |
| 6:4   | r/w | `TIMERx_CTRL_CLK_SEL`   | Counter clock source (see Table 4) |
| 11:7  | r/w | `TIMERx_CTRL_EXT_CLK`   | External clock pin |
| 31:12 | r/- | *reserved*              | read-only zero |

Continuous mode counts up and wraps to zero when the counter overflows.
Loop mode counts up, but wraps to zero when the counter equals the compare value.
This results in a `TIMERx_COMPARE` + 1 cycle loop.

**Table 3.** Timer Prescaler Configuration

| `TIMERx_CTRL_PRSCL` | 0b000 | 0b001 | 0b010 | 0b011 | 0b100 | 0b101 | 0b110 | 0b111 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Clock Prescaler Value | 1 | 2 | 4 | 8 | 64 | 128 | 1024 | 4096 |

**Table 4.** Timer Clock Source Configuration

| `TIMERx_CTRL_SOURCE` | 0b00 | 0b01 | 0b10 | 0b11 |
| --- | --- | --- | --- | --- |
| Counter Clock Source | system clock | external clock | GPIOA interrupt 0 | GPIOA interrupt 1 |

If a GPIO interrupt is selected as the clock source, it functions as a clock enable for the system clock.
This can be used to count the number of rising/falling edges, or to determine the duration of a HIGH/LOW pulse.

The `TIMERx_CTRL_EXT_CLK` field selects which pin from GPIOA is used as the external clock source
