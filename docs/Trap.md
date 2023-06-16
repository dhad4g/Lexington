# Trap Unit

The Trap Unit manages exceptions and interrupts.
Reset conditions are also handles by the trap unit.
This implementation uses purely combinatorial logic.

This document uses the RISC-V Specification definitions of *trap*, *exception*, and *interrupt*.
- *trap*: the synchronous transfer of control to a trap handler caused by an *exception* or *interrupt*
- *exception*: an unusual condition occurring at run time associated with an instruction in the current hart.
- *interrupt*: an external event that occurs asynchronously to the current hart.

## Ports

#### Parameters

- **`WIDTH=32`** data width
- **`CSR_ADDR_WIDTH=12`** CSR address width
- **`RESET_ADDR=0x0000_0000`** program counter reset/boot address

#### Inputs

- **`pc[WIDTH-1:0]`** current program counter value
- **`decoder_next_pc[WIDTH-1:0]`** next PC calculated by decoder
- **`mstatus_mie`** global machine-mode interrupt enable
- **`csr_rd_en`** CSR read enable
- **`csr_rd_addr[CSR_ADDR_WIDTH-1:0]`** CSR read address
- **`csr_wr_en`** CSR write enable
- **`csr_wr_addr[CSR_ADDR_WIDTH-1:0]`** CSR write address
- **`csr_wr_data[WIDTH-1:0]`** CSR write data
- **`inst_misaligned`** instruction address misaligned flag
- **`inst_access_fault`** instruction access fault flag
- **`data_misaligned`** load/store address misaligned flag
- **`data_access_fault`** load/store access fault flag
- **`data_load_store_n`** indicates source of load/store exception (0=store,1=load)
- **`mtime_int`** machine timer interrupt
- **`gpio_int_0`** GPIO interrupt 0
- **`gpio_int_1`** GPIO interrupt 1
- **`uart0_rx_int`** UART0 RX interrupt
- **`uart0_tx_int`** UART0 TX interrupt
- **`timer0_int`** timer0 interrupt
- **`timer1_int`** timer1 interrupt


#### Outputs

- **`next_pc[WIDTH-1:0]`** next PC
- **`csr_rd_data[WIDTH-1:0]`** CSR read data
- **`trap`** trap taken flag

## Behavior

At reset, the Trap Unit sets the PC to `BOOT_ADDR`.
During operation, if no exception or interrupt flags are asserted, the simply passes the `decoder_next_pc` value to the `next_pc` output.

### Exceptions

If an exception flag is asserted:
- `mepc` <= address of instruction causing the exception
- `mcause` <= exception code (see [CSR](./CSR.md) documentation)
- `mtval` <= value shown in Table 1
- a trap occurs immediately

**Table 1.** `mtval` encoding
| Exception | Value |
| --- | --- |
| breakpoint    | faulting address |
| misaligned    | faulting address |
| access-fault  | faulting address |
| illegal inst  | faulting instruction |
| *other*       | 0 |

Exception priority is specified in the `mcause` section of the [CSR](./CSR.md) documentation.
Exceptions always have priority of interrupts.

### Interrupts

If an interrupt flag is asserted, the appropriate bit in `mip` is set.
Interrupt conditions are continually evaluated, and an interrupt will trap if:
1) global interrupts are enabled, indicated by `mstatus_mie` being asserted,
2) an interrupt is both pending and enabled, indicated by the same bit being asserted in `mip` and `mie` respectively.
3) an exception is not occurring

Interrupts use a static priority scheme where lower trap codes have higher interrupt priority (i.e. highest priority is trap code 0).

## Traps

When a trap is triggered, `next_pc` is set to `mtvec` *base*.
See the [CSR](./CSR.md) documentation for details of how a trap affects the global interrupt enable bits in `mstatus`.

### CSRs

The trap unit contains several CSRs.
See the [CSR](./CSR.md) documentation for more details.

**Table 2.** Trap Unit CSRs
| CSR | Hardware | Software |
| --- | --- | --- |
| `mtvec`   | read  | r/w |
| `mip`     | write | r/w |
| `mie`     | read  | r/w |
| `mepc`    | write | r/w |
| `mcause`  | write | r/w legal |
| `mtval`   | write | r/w |
