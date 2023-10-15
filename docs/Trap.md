# Trap Unit

The Trap Unit manages exceptions and interrupts. Reset conditions are also
handled by the trap unit. For details on trap insertion into the pipeline see
the [Control Unit](./Control.md).

The values for `trap_req`, `trap_epc`, `trap_cause`, and `trap_val` must be saved
using registers and latches. These signals must be set the same cycle an exception
or interrupt occurs and must be held until the rising clock-edge after `trap_insert`
is asserted.

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
- **`fetch_pc[XLEN-1:0]`** PC of Fetch Stage
- **`decode_pc[XLEN-1:0]`** PC of Decode Stage
- **`exec_pc[XLEN-1:0]`** PC of Execute Stage
- **`trap_insert`** asserted by Control Unit when a trap is inserted into the pipeline
- **`interrupts[XLEN-1:0]`** interrupts pending with all appropriate enable masks applied
- **`mtvec[XLEN-1:0]`** value of mtvec CSR (see [`mtvec CSR`](./CSR.md#machine-trap-vector-base-address-register-mtvec))
- **`load_store_n`** indicates source of load/store exception (Execute Stage; 0=store,1=load)
- **`inst[XLEN-1:0]`** instruction bits (Decode Stage)
- **`jump_pc[XLEN-1:0]`** misaligned instruction address (Decode Stage)
- **`data_addr[XLEN-1:0]`** data load/store address (Execute Stage)

*exception flags*
- **`mret`** machine-mode trap return instruction (Decode Stage)
- **`inst_access_fault`** instruction access fault flag (Fetch Stage)
- **`inst_misaligned`** instruction address misaligned flag (Decode Stage)
- **`illegal_inst`** illegal instruction flag (Decode Stage)
- **`illegal_csr`** illegal CSR instruction flag (Decode Stage)
- **`ecall`** environment call flag (Decode Stage)
- **`ebreak`** breakpoint flag (Decode Stage)
- **`data_misaligned`** load/store address misaligned flag (Execute Stage)
- **`data_access_fault`** load/store access fault flag (Execute Stage)


### Outputs

- **`trap_req`** request to the Control Unit to insert trap into the pipeline
- **`trap_addr[XLEN-1:0]`** destination of a trap; only valid if `trap_req` is asserted
- **`trap_epc[XLEN-1:0]`** address of faulting or interrupted instruction
- **`trap_cause[XLEN-1:0]`** trap cause (see [`mcause` CSR](./CSR.md#machine-cause-register-mcause))
- **`trap_val[XLEN-1:0]`** trap value (see [`mtval` CSR](./CSR.md#machine-trap-value-register-mtval))
- **`squash_decode`** squash instruction in Decode Stage
- **`squash_exec`** squash instruction in Execute Stage

<br>

## Behavior

During operation, if an exception or interrupt flag is asserted, the trap unit
behaves as specified below.

### Exceptions

When exception flag is asserted, the `trap_req` signal is immediately asserted.
Instructions are squashed starting at the stage the exception occurred. The values
for `trap_epc`, `trap_cause`,  and `trap_val` are latched. The `trap_req` signal
must remain asserted until `trap_insert` is asserted by the Control Unit (i.e.
must be latched). If another exception occurs while the pipeline is being flushed
(i.e. while `trap_req` is asserted, but before `trap_insert`) then the new exception
has priority and the latched output values are updated as well as any additional
squashing.

Trap CSR signals are assigns as follows:
- `trap_epc` <= PC of the faulting instruction
- `trap_cause` <= see [`mcause` CSR](./CSR.md/#machine-cause-register-mcause)
- `trap_val` <= see [`mtval` CSR](./CSR.md#machine-trap-value-register-mtval)

The `xRET` instruction is treated as a pseudo trap. When `mret` is asserted, both
`trap_req` and `trap_is_mret` are asserted. The `trap_epc`, `trap_cause` and
`trap_val` outputs do not need to be set. The `mret` instruction is NOT squashed.

Exception priority is listed in Table 1. Exceptions for an instructions ahead
of another always has priority, and exception always have priority of interrupts.

**Table 1.** Exception priority

| Priority | Trap Code | Description | Pipeline Stage |
| --- | --- | --- | --- |
| *Highest* | 3 | ~~Instruction address breakpoint~~ |
| | 1 | Instruction access fault | Fetch Stage
| | 2<br>0<br>8, 9, 11<br>3<br>3 | Illegal instruction<br>Instruction address misaligned<br>Environment call<br>Environment break<br>~~Load/store/AMO address breakpoint~~ | Decode Stage
| | 4, 6 | Load/store/AMO address misaligned | Execute Stage
| *Lowest* | 5, 7 | Load/store/AMO access fault | Execute Stage

<br>

*Note: instruction address misaligned exceptions are raised by control-flow instructions with misaligned targets, rather than by the act of fetching an instruction*

### Interrupts

The `interrupts` input vector has already had all appropriate enable masks applied.
When an interrupt request occurs, the `trap_req` flag is asserted and the values
for `trap_epc`, `trap_cause`, `trap_val` are latched. Just as when an exception
trap is triggered, the `trap_req` signal must remain asserted until `trap_insert`
is asserted (i.e. the pipeline is flushed). If an exception occurs while the
pipeline is draining, the exception takes priority and the interrupt trap does
not occur.

Trap CSR signals are assigns as follows:
- `trap_epc` <= PC of the interrupted instruction
- `trap_cause` <= see [`mcause` CSR](./CSR.md/#machine-cause-register-mcause)
- `trap_val` <= 0

Interrupts use a static priority scheme where lower trap codes have higher
interrupt priority (i.e. highest priority is trap code 0).

