# Pipeline Control

This section specifies the pipeline control behavior, including hazards detection,
data forwarding, branching, and traps.

A typical 5-stage pipeline is implemented.
1. Fetch
2. Decode
3. Execute
4. Memory/CSR
5. Write Back

![Pipeline\label{pipeline}](./figures/Pipeline.drawio.svg) \
**Figure 1.** Saratoga Pipeline

<br>

When analyzing the pipeline, this document uses the term *cycle* to refer to the
number cycles not stalled by other factors such as hazards of other instructions
or memory operation latency.

<br>

## Pipeline Registers

The registers separating each pipeline stage are listed below. Additionally, the
following registers are present between all* stages:
- `bubble` asserted if no valid instruction is being executed
- `pc[XLEN-1:0]` current program counter
- `priv[1:0]` current privilege mode
- `mem_priv[1:0]` *effective* privilege mode for data memory access
- `endianness` *effective* data memory endianness

\* only the `bubble` register is required for the MEM/WB

### IF/ID
- `inst[31:0]` instruction bits

### ID/EX
- `src1[XLEN-1:0]` left side operator
- `src2[XLEN-1:0]` right side operator
- `alt_data[XLEN-1:0]` alternate data for store or CSR write
- `csr_addr[11:0]` address for CSR write
- `dest[4:0]` destination register
- `mem_en` asserted if instruction is load or store
- `csr_wr` asserted if instruction is a CSR write
- `alu_forward[1:0]` data forwarding ([see Data Forwarding](#data-forwarding))
- `load_forward_alu[1:0]` data forwarding ([see Data Forwarding](#data-forwarding))
- `load_forward_mem` data forwarding ([see Data Forwarding](#data-forwarding))

### EX/MEM
- `alu_result[XLEN-1:0]` result from ALU
- `alt_data[XLEN-1:0]` alternate data for store or CSR write
- `csr_addr[11:0]`  address for CSR write
- `dest[4:0]` destination register
- `mem_en` asserted if instruction is a load or store
- `csr_wr` asserted if instruction is a CSR write
- `load_forward_mem` data forwarding ([see Data Forwarding](#data-forwarding))

### MEM/WB
- `dest_data[XLEN-1:0]` result for ALU or load data
- `dest[4:0]` destination register

<br>

## Data Hazards

As this is an in-order pipeline, only read-after-write (RAW) data hazards occur.
Both General Purpose Registers (GPR) and Control and Status Registers (CSR)
support writing and reading to/from the same destination in the same cycle. The
value read is the same as the value written.

### GPR Raw Hazards

0-2 cycle delay

GPR RAW hazards can occur any time a GPR read occurs within 2 cycles of a
matching GPR write. Forwarding is used when possible to increase performance.

The [Hazard Map](#hazard-map) contains details about each class of instruction,
including: if one or more GPR read is required, if a GPR write occurs, and
when in the pipeline the GPR read data is actually needed. This map helps to
determine the forwarding logic. See [Data Forwarding](#data-forwarding)
for details.

### CSR RAW Hazards

0-1 cycle delay

CSR RAW hazards can occur any time a *Scratch* CSR read occurs within 1 cycle
of a matching CSR write. Forwarding is NOT used for CSR hazards and the pipeline
always stalls until the *Scratch* CSR write reaches the Mem/CSR stage. The result
is a maximum delay of 1 cycle.

This includes implicit read of trap related Scratch CSR during execution of an
`xRET` instruction. More specifically, `xRET` instructions are stalled for 1 cycle
in the decode stage if immediately preceded by a trap related Scratch CSR write.

*Atomic* CSR RAW hazards do not occur as Atomic CSR writes require the pipeline
to stall until the write is complete
(see [CSR Writes to *Atomic* Register](#csr-writes-to-atomic-registers)).

#### Memory RAW hazards

Memory RAW hazards do not occur as all memory access happens in the Memory stage.
A store after load hazard still exists but is a GPR RAW hazard
(see [GPR RAW Hazards](#gpr-raw-hazards)).

<br>

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

Writes to *Atomic* CSRs can affect the execution environment. Thus, the pipeline
must be flushed until the Atomic CSR write has been committed. This is called an
Atomic CSR flush, and stalls for a total of 3 cycles (the Fetch stage must be
squashed).

### Traps

For the purposes of this pipeline, an `xRET` instruction is treated as a unique
synchronous exceptions.

When a synchronous exception occurs, the stage at which the exception is encountered
and all previous stages are squashed. Traps do not require the pipeline to be
flushed and can be executed speculatively. See [Trap Insertion](#trap-insertion)
for details.

<br>

## Control Unit

The Control Unit manages the flow of instructions and data through the pipeline.
It's primary purpose is to detect and manage hazards.

### Data Forwarding

The Control Unit works with the decoder to detect data hazards and plan data
forwarding. If forwarding is not possible, the Control Unit inserts a bubble
into the pipeline. The following signals are used to control the forwarding
behavior through the pipeline: `alu_forward[1:0]`, `load_forward_alu[1:0]`, and
`load_forward_mem`. Their locations in the pipeline is shown in
[Pipeline Registers](#pipeline-registers). Two bit signals are used to specify
the destination of the forwarded data when applicable. Bits 0 and 1 enable data
forwarding for the `src1` and `src2` operands respectively.

- `alu_forward[1:0]` signal is used to forward data from the ALU/MEM registers
to ALU input operands.

- `load_forward_alu[1:0]` signal is used to forward data from the MEM/WB registers
to the ALU input operands.

- `load_forward_mem` signal is used to forward data from the MEM/WB registers
to the MEM stage, specifically, from a LOAD instruction to a STORE instruction.

A CSR read instruction will stall in decode when a matching CSR dependency is in
the Execute or Mem/CSR stages.

**Table 1.** GPR Forwarding and Stalls

| Data Required Stage | Worst-Case Delay | Stall Condition(s) | Forwarding |
|---------------------|------------------|--------------------|------------|
| Decode    | 2 | Mem dependency in pipeline $\\or\\$ ALU dependency in Execute | EX/MEM -> Decode
| Execute   | 1 | Mem dependency in Execute stage | EX/MEM -> Execute $\\and/or\\$ MEM/WB -> Execute
| Memory    | 0 | N/A | MEM/WB -> Execute *or* MEM/WB -> Memory

<br>

### Trap Insertion

To avoid the need to flush the pipeline before trapping, traps are speculatively
executed. When a trap enters the pipeline, it is considered *speculative* until
the leading instruction is committed in Write Back. When a trap enters the pipeline,
the trap related CSR changes (i.e. `xepc`, `xcause`, etc.) are buffered as speculative.
When the speculative trap reaches the Mem/CSR stage, the buffered CSR changes
are committed. This is possible because no exception are generated in Write Back.
At this point, the trap is no longer considered speculative.

During speculative execution of a trap, any read from a trap related CSR is
sourced from the speculative trap buffer. If the first instruction of a trap
handler writes to a Trap CSR, then this write overwrites the speculative trap CSR
write for that CSR.

Only one speculative trap may be in the pipeline at a time. There are three ways
a second trap can be encountered during speculative execution of a trap. (1) If
an exception occurs in a stage ahead of the speculative trap, all stages behind
the exception are squashed as usual and the speculative trap CSR changes are
over-written with the new exception. (2) If any instruction in the speculative
trap encounters an exception, that instruction stalls until the speculative-trap
is resolved and committed as described above. (3) Asynchronous interrupts are
not allowed to occur during speculative execution of a trap. They will be resolved
after the speculative trap is committed.

To support speculative execution of traps, state information such as the current
privilege level must be bound to each instruction in the pipeline<sup>1</sup>.
The list of such attributes is:
- Current privilege mode
- *Effective* privilege mode
- Data memory endianness (*effective*)

<br>

1. The Write Back stage does not require state information

<br>

## Hazard Map

**Table 2.** Hazard Map

| Instruction | Decode | Execute | Mem/CSR | Write-Back | Dependency Source |
|-------------|--------|---------|---------|------------|-----------------|
| OP        | $\textcolor{yellow}{GPR~Read(2)}$ | $\textcolor{yellow}{_{Requires~src1/src2}}$ | $\textcolor{cyan}{_{GPR~Write~Ready}}$ | $\textcolor{cyan}{GPR~Write}$ | ALU Dependency
| OP-IMM    | $\textcolor{yellow}{GPR~Read}$ | $\textcolor{yellow}{_{Requires~src1}}$ | $\textcolor{cyan}{_{GPR~Write~Ready}}$ | $\textcolor{cyan}{GPR~Write}$ | ALU Dependency
| LUI/AUIPC | | | $\textcolor{cyan}{_{GPR~Write~Ready}}$ | $\textcolor{cyan}{GPR~Write}$ | ALU Dependency
| JAL       | Squash Fetch $\\\textcolor{red}{Misaligned^1}$ | | $\textcolor{cyan}{_{GPR~Write~Ready}}$ | $\textcolor{cyan}{GPR~Write}$ | ALU Dependency
| JALR      | Squash Fetch $\\\textcolor{yellow}{GPR~Read}\\\textcolor{yellow}{_{Requires~src1}}\\\textcolor{red}{Misaligned^1}$ | | $\textcolor{cyan}{_{GPR~Write~Ready}}$ | $\textcolor{cyan}{GPR~Write}$ | ALU Dependency
| BRANCH    | Squash Fetch$^1$ $\\\textcolor{yellow}{GPR~Read(2)}\\\textcolor{yellow}{_{Requires~src1/src2}}\\\textcolor{red}{Misaligned^1}$ | | |
| LOAD      | $\textcolor{yellow}{GPR~Read}$ | $\textcolor{yellow}{_{Requires~src1}}\\\textcolor{red}{Misaligned^1}$ | $\textcolor{red}{Access~Fault^1}$ | $\textcolor{cyan}{_{GPR~Write~Ready}}\\\textcolor{cyan}{GPR~Write}$ | Mem Dependency
| STORE     | $\textcolor{yellow}{GPR~Read(2)}$ | $\textcolor{yellow}{_{Requires~src1}}\\\textcolor{red}{Misaligned^1}$ | $\textcolor{yellow}{_{Requires~src2}}\\\textcolor{red}{Access~Fault^1}$ |
| FENCE$\\$FENCE.I | | | | | |
| CSRR      | $\textcolor{orange}{CSR~Read}\\\textcolor{red}{Illegal~Inst.^1}$ | | $\textcolor{cyan}{_{GPR~Write~Ready}}$ | $\textcolor{cyan}{GPR~Write}$ | ALU Dependency
| CSRW      | $\textcolor{yellow}{GPR~Read}\\\textcolor{red}{Illegal~Inst.^1}$ | $\textcolor{yellow}{_{Requires~src1}}$ | $\textcolor{cyan}{CSR~Write}$ | | CSR Dependency
| CSRS$\\$CSRC |$\textcolor{yellow}{GPR~Read}\\\textcolor{orange}{CSR~Read}\\\textcolor{red}{Illegal~Inst.^1}$ | $\textcolor{yellow}{_{Requires~src1}}$ | $\textcolor{cyan}{CSR~Write}$ | | CSR Dependency
| CSRRW$\\$CSRRS$\\$CSRRC | $\textcolor{yellow}{GPR~Read}\\\textcolor{orange}{CSR~Read}\\\textcolor{red}{Illegal~Inst.^1}$ | $\textcolor{yellow}{_{Requires~src1}}$ | $\textcolor{cyan}{_{GPR~Write~Ready}}\\\textcolor{cyan}{CSR~Write}$ | $\textcolor{cyan}{GPR~Write}$ | ALU Dependency$\\$CSR Dependency
| CSRWI     | $\textcolor{red}{Illegal~Inst.^1}$ | | $\textcolor{cyan}{CSR~Write}$ | | CSR Dependency
| CSRSI$\\$CSRCI |$\textcolor{orange}{CSR~Read}\\\textcolor{red}{Illegal~Inst.^1}$ | | $\textcolor{cyan}{_{GPR~Write~Ready}}\\\textcolor{cyan}{CSR~Write}$ | $\textcolor{cyan}{GPR~Write}$ | ALU Dependency$\\$CSR Dependency
| ECALL     | $\textcolor{red}{Env.~Call}$ | | |
| EBREAK    | $\textcolor{red}{Breakpoint}$ | | |
| xRET      | $\textcolor{red}{xRET}$ | | |
| WFI       | | | |

<br>

1. These actions occur conditionally
