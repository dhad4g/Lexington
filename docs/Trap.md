# Trap Unit

The Trap Unit manages exceptions and interrupts.
Reset conditions are also handles by the trap unit.
This implementation uses purely combinatorial logic, except for trap CSRs.

This document uses the RISC-V Specification definitions of *trap*, *exception*,
and *interrupt*.
- *trap*: the synchronous transfer of control to a trap handler caused by an
  *exception* or *interrupt*
- *exception*: an unusual condition occurring at run time associated with an
  instruction in the current hart.
- *interrupt*: an external event that occurs asynchronously to the current hart.

## Ports

### Parameters

- **`XLEN=32`** data width

### Inputs

- **`clk`** core clock
- **`rst_n`** active-low reset
- **`pc[WIDTH-1:0]`** current program counter value
- **`decoder_next_pc[WIDTH-1:0]`** next PC calculated by decoder
- **`global_mie`** global machine-mode interrupt enable from mstatus CSR
- **`csr_rd_en`** CSR read enable
- **`csr_wr_en`** CSR write enable
- **`csr_addr[CSR_ADDR_WIDTH-1:0]`** CSR read/write address
- **`csr_wr_data[WIDTH-1:0]`** CSR write data
- **`mret`** machine-mode return flag
- **`dbus_wait`** flag indicating dbus transaction requires extra cycle

*exception flags*
- **`inst_access_fault`** instruction access fault flag, from fetch
- **`inst_misaligned`** instruction address misaligned flag, from Decode
- **`illegal_inst`** illegal instruction flag, from decoder
- **`illegal_csr`** illegal CSR instruction flag, from CSR
- **`inst[WIDTH-1:0]`** instruction bits, from decoder
- **`ecall`** environment call flag, from decoder
- **`ebreak`** breakpoint flag, from decoder
- **`data_misaligned`** load/store address misaligned flag, from LSU
- **`data_access_fault`** load/store access fault flag, from LSU
- **`load_store_n`** indicates source of load/store exception, from LSU (0=store,1=load)
- **`data_addr[WIDTH-1:0]`** data address from LSU

*interrupt flags*
- **`mtime_int`** machine timer interrupt
- **`gpioa_int_0`** GPIOA interrupt 0
- **`gpioa_int_1`** GPIOA interrupt 1
- **`gpiob_int_0`** GPIOA interrupt 0
- **`gpiob_int_1`** GPIOA interrupt 1
- **`gpioc_int_0`** GPIOA interrupt 0
- **`gpioc_int_1`** GPIOA interrupt 1
- **`uart0_rx_int`** UART0 RX interrupt
- **`uart0_tx_int`** UART0 TX interrupt
- **`tim0_int`** timer0 interrupt
- **`tim1_int`** timer1 interrupt


### Outputs

- **`next_pc[WIDTH-1:0]`** next PC
- **`csr_rd_data[WIDTH-1:0]`** CSR read data
- **`exception`** exception flag
- **`trap`** trap taken flag

## Behavior

At reset, the Trap Unit sets the PC to `BOOT_ADDR`.
During operation, if no exception or interrupt flags are asserted, `next_pc` gets `decoder_next_pc` and the `trap` flag is low

If the `dbus_wait` flag is asserted, the Trap Unit must always wait for the instruction to complete by assigning `next_pc` to `pc`.

### Exceptions

When exception flag is asserted, a trap immediately occurs.
Exception priority is in Table 1.

**Table 1.** Exception priority

| Priority | Trap Code | Description |
| --- | --- | --- |
| *Highest* | 3 | Instruction address breakpoint |
| | 1 | Instruction access fault |
| | 2<br>0<br>8, 9, 11<br>3<br>3 | Illegal instruction<br>Instruction address misaligned<br>Environment call<br>Environment break<br>Load/store/AMO address breakpoint |
| | 4, 6 | Load/store/AMO address misaligned |
| *Lowest* | 5, 7 | Load/store/AMO access fault |

Exceptions always have priority over interrupts.
<br>

*Note: instruction address misaligned exceptions are raised by control-flow instructions with misaligned targets, rather than by the act of fetching an instruction*

### Interrupts

If an interrupt flag is asserted, the appropriate bit in `mip` is set.
Interrupt conditions are continually evaluated, and an interrupt will trap if:
1) global interrupts are enabled, indicated by `mstatus_mie` being asserted,
2) an interrupt is both pending and enabled, indicated by the same bit being asserted in `mip` and `mie` respectively.
3) an exception is not occurring

All interrupts, standard and non-standard, are registered and are thus delayed
by 1 cycle.

Interrupts use a static priority scheme where lower trap codes have higher interrupt priority (i.e. highest priority is trap code 0).

## Traps

When a trap occurs:
- `next_pc` <= *base* of `mtvec`
- `mepc` <= address of instruction causing the exception or interrupted instruction
- `mcause` <= exception code (see [CSR](./CSR.md) documentation)
- `mtval` <= see Table 2
- `trap` <= 1

*Note: see the [CSR](./CSR.md) documentation for details of how a trap affects the global interrupt enable bits in `mstatus`.*

**Table 2.** `mtval` encoding
| Exception | Value |
| --- | --- |
| breakpoint    | faulting address |
| misaligned    | faulting address |
| access-fault  | faulting address |
| illegal inst  | faulting instruction |
| *other*       | 0 |


### CSRs

The trap unit contains several CSRs.
See the [CSR](./CSR.md) documentation for more details.

**Table 3.** Trap Unit CSRs
| CSR | Hardware | Software |
| --- | --- | --- |
| `mtvec`   | read  | r/w |
| `mip`     | write | r/w |
| `mie`     | read  | r/w |
| `mepc`    | write | r/w |
| `mcause`  | write | r/w legal |
| `mtval`   | write | r/w |
