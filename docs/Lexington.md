# Lexington Microarchitecture

## Design

The GPro Lexington CPU is a single-cycle RISC-V RV32I implementation.
It features a read-only program memory and separate read/write data memory.
The system diagram is shown in Figure 1.

![](figures/BlockDiagram.drawio.svg) \
**Figure 1.** GPro Lexington block diagram

## Behavior

Detailed behavior of each submodule is documented in these documents:

- [ROM](./ROM.md)
- [RAM](./RAM.md)
- [Register File](./RegisterFile.md)
- [PC](./PC.md)
- [Fetch](./Fetch.md)
- [Decoder](./Decoder.md)
- [ALU](./ALU.md)
- [Load/Store](./Load_Store.md)
- [Control and Status Registers (CSR)](./CSR.md)

The following sections detail some of the general behavior of the device.

#### Reset

Upon reset, the `pc` is set to 0x0.


#### Non-Maskable Interrupts (NMI)

NMIs are triggered by hardware error conditions.
They case an immediate jump to 0x0 and set the `mepc` CSR to the address of the instruction that was interrupted.
Additionally, the MSB of `mcause` is set to one, indicating an interrupt, and all other bits are set to zero.
