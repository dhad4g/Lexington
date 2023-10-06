3# Control Unit

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

## Ports

### Parameters

- **`XLEN=32`** data width

### Inputs

- **`clk`** core clock
- **`rst_n`** active-low reset
- 

### Outputs

<br>

## Behavior

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
