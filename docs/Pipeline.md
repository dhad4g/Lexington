# Pipeline Control

This section specifies the pipeline control behavior, including hazards detection,
data forwarding, branching, and traps.

A 3-stage pipeline is implemented.
1. Fetch
2. Decode
3. Execute

![Pipeline\label{pipeline}](./figures/Pipeline.drawio.svg) \
**Figure 1.** Saratoga Pipeline

<br>

When analyzing the pipeline, this document uses the term *cycle* to refer to the
number cycles not stalled by other factors such as hazards of other instructions
or memory operation latency.

<br>

## Pipeline Registers

### IF/ID
- `bubble` asserted if no valid instruction is being executed
- `pc[XLEN-1:0]` current program counter
- `pc4[XLEN-1:0]` PC + 4
- `inst[31:0]` instruction bits

### ID/EX
- `bubble` asserted if no valid instruction is being executed
- `pc[XLEN-1:0]` current program counter
- `src1[XLEN-1:0]` left side operator
- `src2[XLEN-1:0]` right side operator
- `alt_data[XLEN-1:0]` alternate data for store or CSR write
- `csr_addr[11:0]` address for CSR write
- `dest[4:0]` destination register
- `alu_op[3:0]` ALU operation select
- `lsu_op[2:0]` asserted if instruction is a CSR write

<br>

## Data Hazards

To avoid all data hazards, both General Purpose Registers (GPR) and Control and
Status Registers (CSR) support writing and reading to the same destination in
the same cycle. The value read will be the same as the value written.

## Control Hazards

There are several groups of instructions that cause control hazards within the
pipeline.

### Jump `JAL`, `JALR`

1 cycle delay

Jump address is calculated in Decode stage with dedicated adder (`pc`+`imm` or `rs1`+`imm`).
Link address (`pc`+4) is forwarded from the Fetch stage.

### Branch `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`

0-1 cycle delay (0: not taken, 1: taken)

Branch address calculated in Decode stage with dedicated adder (`pc`+`imm`).
Branch condition evaluated in Decode Stage with dedicated logic.

### CSR Writes to *Atomic* Registers

3 cycle delay

Writes to *Atomic* CSRs can affect the execution environment. Thus, the pipeline
must be flushed after this instruction and before the next instruction enters
the Fetch Stage. See the [Atomic CSR Write](./Control.md#atomic-csr-write)
section of the Control Unit for details about flushing the pipeline. See
[CSR](./CSR.md) for information about Atomic CSRs.

### Traps

1-3 cycle delay (dependent on source of trap)

Trap behavior is specified in the [Trap Unit](./Trap.md).
