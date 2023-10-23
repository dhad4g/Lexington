# Control Unit

The Control Unit manages the flow of instructions and data through the pipeline.
It's primary purpose is to detect and manage hazards. For trap triggers see
the [Trap Unit](./Trap.md).

This document uses the RISC-V Specification definitions of *trap*, *exception*,
and *interrupt*.
- *trap*: the synchronous transfer of control to a trap handler caused by an
  *exception* or *interrupt*
- *exception*: an unusual condition occurring at run time associated with an
  instruction in the current hart.
- *interrupt*: an external event that occurs asynchronously to the current hart.

This module uses combinatorial logic with the exception of the
`atomic_csr_pending` register.

## Ports

### Parameters

- **`XLEN=32`** data width

### Inputs

- **`clk`** core clock
- **`rst_n`** active-low reset
- **`branch`** asserted by Decode Stage when a jump or taken branch is encountered
- **`branch_addr[XLEN-1:0]`** destination of jump or taken branch; only valid if `branch` is asserted
- **`trap_req`** asserted by Trap Unit when a trap is to occur
- **`trap_addr[XLEN-1:0]`** destination of a trap; only valid if `trap_req` is asserted
- **`csr_rd_en`** asserted by Decode Stage when any CSR read occurs (including implicit)
- **`decode_csr_addr`** CSR address in Decode Stage
- **`exec_csr_addr`** CSR address in Execute Stage
- **`atomic_csr`** asserted by Decode Stage during an Atomic CSR write instruction
- **`bubble_decode`** bubble status of Decode Stage (i.e. IF/ID bubble_o)
- **`bubble_exec`** bubble status of Execute Stage (i.e. ID/EX bubble_o)

### Outputs
- **`next_pc_en`** enable override of next PC
- **`next_pc[XLEN-1:0]`** override value for next PC; only valid if `next_pc_en` is asserted
- **`bubble_fetch`** inserts a bubble at the Fetch Stage (i.e. IF/ID bubble_i)
- **`stall_decode`** stalls the Decode Stage
- **`trap_insert`** asserted when a trap is inserted into the pipeline; triggers trap CSRs
- **`atomic_csr_pending`** asserted if an atomic CSR write is in progress

<br>

## Behavior

The Control Unit is responsible for handling pipeline flow in the following
situations: (1) jump and branch taken, (2) traps, (3) CSR read hazards, and
(4) Atomic CSR writes.

### Jump and Branch Taken

If the `branch` signal from the Decode Stage is asserted, a bubble is inserted at
IF/ID by asserting `bubble_fetch`. Additionally, `next_pc_en` is asserted and
`next_pc` is set to `branch_addr`.

### Trap Insertion

If the `trap_req` signal from the Trap Unit is asserted, the pipeline is flushed
before continuing. Bubbles are inserted into the pipeline at the Fetch Stage by
asserting `bubble_fetch`. Squashes are handles by the [Trap Unit](./Trap.md).
Once both `bubble_decode` and `bubble_exec` are high, `trap_insert` is asserted,
`next_pc_en` is asserted, and `next_pc` is set to `trap_addr`.

### Atomic CSR Write

If the `atomic_csr` signal is asserted then the pipeline must be flushed. Bubbles
are inserted into the pipeline at the Fetch Stage by asserting `bubble_fetch`.
One cycle after both `bubble_decode` and `bubble_exec` are asserted, `bubble_fetch`
is set low and forward progress resumes.
