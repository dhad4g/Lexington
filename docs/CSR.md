# CSR

## Machine Level

### Machine ISA Register `misa`

*0x301*

The `misa` reports the ISA supported by the hart.
The register is W/R, but this implementation ignores all write values.
Figure 1 shows the field encoding

![](figures/csr/misa.drawio.svg) \
**Figure 1.** Field encoding for `miso`

The two-bit `MXL` field encodes the native base integer ISA width.
The value of `MXL` is 1 for the 32-bit GPro Lexington core.

The Extensions field encodes the presence of standard ISA extensions.
Each bit encodes one letter of the alphabet with bit 0 encoding the "A" extension and bit 25 encoding the "Z" extensions.
The only extension bit asserted in this implementation is bit eight, the "I" bit.

This implementation ignores writes the `misa` register


### Machine Vendor ID Register `mvendorid`

*0xF11*

A read-only register encoding the JEDEC manufacturer ID.
This implementation returns 0x0, indicating a non-comercial implementation.


### Machine Architecture ID Register `marchid`

*0xF12*

A read-only register encodes the base microarchitecture of this hart.
This implementation returns 0x0, indicating no allocated architecture ID.


### Machine Implementation ID Register `mimpid`

*0xF13*

This read-only register encodes the version of the processor implementation as a subset of the architecture ID.
This implementation returns 0x1, indicating the first iteration of the GPro CPU.


### Hart ID Register `mhartid`

*0xF14*

This read-only register encodes the execution environment unique, integer ID of the hardware thread.
This implementation returns 0x0 as there is only one hardware thread in the GPro Lexington core.


### Machine Status Register `mstatus` and `mstatush`

*0x300* and *0x310*

The read/write registers tracks and controls the hart's current operating state.
Figures 2 and 3 show the encoding of `mstatus` and `mstatush` respectively.


![](figures/csr/mstatus.png) \
**Figure 2.** Encoding of `mstatus` register

![](figures/csr/mstatush.png) \
**Figure 3.** Encoding of `mstatush` register

| Bit(s) | Name | Description | Default Value |
| --- | --- | --- | --- |
| 1     | SIE   | *Unused:* Supervisor-mode interrupt enable |
| 3     | MIE   | Manager-mode interrupt enable | 1
| 5     | SPIE  | *Unused:* Supervisor-mode |
| 6     | UBE   | *Unused:* User-mode data memory endianness
| 7     | MPIE  | *Unused:* Manager-mode previous interrupt enable |
| 8     | SPP   | *Unused:* Supervisor-mode previous privilege mode |
| 10:9  | VS    | *Unused:* Vector extensions state |
| 12:11 | MPP   | *Unused:* Manager-mode previous privilege mode |
| 14:13 | FS    | *Unused:* Floating-point unit state
| 16:15 | XS    | *Unused:* Additional user-mode extensions state |
| 17    | MPRV  | *Unused:* Modify privilege | 
| 18    | SUM   | *Unused:* Permit supervisor user memory access |
| 19    | MXR   | *Unused:* Make executable readable |
| 20    | TVM   | *Unused:* Trap virtual memory |
| 21    | TW    | *Unused:* Timeout wait |
| 22    | TSR   | *Unused:* Trap SRET |
| 31    | SD    | *Unused:* Extensions state summary |
| 36    | SBE   | *Unused:* Supervisor-mode data memory endianness |
| 37    | MBE   | Manager-mode data memory endianness | 0


### Machine Trap-Vector Base-Address Register `mtvec`

*0x305*

This read/write register contains the address of the trap handler function.
All addresses are forced to be 4-byte aligned and the address's 2 LSBs are ignored.
The 2 LSBs of the `mtvec` register contain the addressing mode of the trap-vector table.
The default value on reset is 0x0.

![](figures/csr/mtvec.png)

**Trap-Vector Addressing modes**

| Value | Name | Description |
| --- | --- | --- |
| 0 | Direct | All exceptions set PC to BASE |
| 1 | Vectored | Asynchronous interrupts set PC to BASE+(4*cause) |
| $\ge$2 | - | *Reserved* |

If using vectored mode, the 6 LSBs of BASE are zeroed, thus forcing 64-byte alignment of the trap-vector table.

Reset and NMIs always trap to address 0x0.


### Machine Interrupt Pending `mip`

*0x344*

This read/write register encodes pending interrupts.
Bit *i* corresponds to interrupt cause number *i* as reported in CSR [mcause](#machine-cause-register-mcause).
Pending interrupts are not cleared by hardware but must be cleared by software by clearing the corresponding bit.

The global interrupt enable bit in [`mstatus`](#machine-status-register-mstatus-and-mstatush) and the appropriate enable bit in ['mie'](#machine-interrupt-enable-mie) must be set for an interrupt to trap.
Interrupt conditions are evaluated depend on the current value of `mip`, [`mie`](#machine-interrupt-enable-mie), and [`mstatus`](#machine-status-register-mstatus-and-mstatush).
Interrupts are implicitly disabled during trap handler execution, beginning with the trap and ending with the execution of *x*RET.
Interrupts are immediately enabled at the execution of *x*RET and a pending interrupt may be trapped, i.e. interrupt tail-chaining.

Bits 15:0 encode the standard interrupt causes.
These bits have unique behaviors such as being read-only.

![](figures/csr/mip.png)

**Standard Interrupt Bits**

| Bit | Name | Description |
| --- | --- | --- |
| 1  | SSIP | *Unused* Supervisor-level software interrupt pending (read-only)
| 3  | MSIP | Machine-level software interrupt pending (read-only)
| 5  | STIP | *Unused* Supervisor-level timer interrupt pending (read-only)
| 7  | MTIP | Machine-level timer interrupt pending (read-only)
| 9  | SEIP | *Unused* Supervisor-level external interrupt pending (read-only)
| 11 | MEIP | Machine-level external interrupt pending (read-only)

**Interrupt Priority**
| Priority | Interrupt Type |
| --- | --- |
| *Highest* | MEIP
|           | MSIP
| *Lowest*  | MTIP


### Machine Interrupt Enable `mie`

*0x304*

This read/write register encodes the enable for interrupts.
Bit *i* corresponds to interrupt cause number *i* as reported in CSR [mcause](#machine-cause-register-mcause).
All bits are writable, even if the corresponding interrupt is not supported.
The register is set to 0 at reset.
See ['mip'](#machine-interrupt-pending-mip) for additional information.


### Machine Cycle Counter `mcycle` and `mcycleh`

*0xB00* and *0xB80*

Counts the number of clock cycles executed by this hart.
A 64-bit, read/write register with value zero at reset.
The value is not incremented on cycles where a CSR write occurs.
The `cycle` CSR is a read-only shadow of `mcycle`.


### Machine Instructions Retired Counter `minstret` and `minstreth`

*0xB02* and *0xB82*

Counts the number of instructions retired by this hart.
A 64-bit read-write register with value zero at reset.
The value is not incremented on cycles where a CSR write occurs.
The `instret` CSR is a read-only shadow of `minstret`


### Machine Counter-Inhibit CSR `mcountinhibit`

*0x320*

This register can be used to disable individual performance counters.

![](figures/csr/mcountinhibit.png)


### Machine Scratch Register `mscratch`

*0x340*

A general-purpose read/write register for use by machine mode.


### Machine Exception Program Count `mepc`

*0x341*

This read/write register holds the address of instruction that was interrupted or caused an exception when a trap is encountered in machine mode.
This implementation uses `IALIGN`=32 and thus the least significant two bits are always zero and write values to these bits are ignored.


### Machine Cause Register `mcause`

*0x342*

This read/write register encodes the event type that caused a trap.
Only legal values are allowed to be written.
The MSB is asserted if this trap was caused by an interrupt.
All other bits encode the trap type.

**Interrupt trap codes**
| Trap Code | Description |
| --- | --- |
| 1 | Supervisor software interrupt |
| 3 | Machine software interrupt |
| 5 | Supervisor timer interrupt |
| 7 | Machine timer interrupt |
| 9 | Supervisor external interrupt |
| 11 | Machine external interrupt |

**Exception trap codes**
| Trap Code | Description |
| --- | --- |
| 0 | Instruction address misaligned |
| 1 | Instruction access fault |
| 2 | Illegal instruction |
| 3 | Breakpoint |
| 4 | Load address misaligned |
| 5 | Load access fault |
| 6 | Store/AMO address misaligned |
| 7 | Store/AMO access fault |
| 8 | Environment call from U-mode |
| 9 | Environment call from S-mode |
| 11 | Environment call from M-mode |
| 12 | Instruction page fault |
| 13 | Load page fault |
| 15 | Store/AMO page fault |

**Trap code priority**
| Priority | Trap Code | Description |
| --- | --- | --- |
| *Highest* | 3 | Instruction address breakpoint |
| | 1 | Instruction access fault |
| | 2<br>0<br>8, 9, 11<br>3<br>3 | Illegal instruction<br>Instruction address misaligned<br>Environment call<br>Environment break<br>Load/store/AMO address breakpoint |
| | 4, 6 | Load/store/AMO address misaligned |
| *Lowest* | 5, 7 | Load/store/AMO access fault |

*Instruction address misaligned exceptions are raised by control-flow instructions with misaligned targets, rather than by the act of fetching an instruction*


### Machine Trap Value Register `mtval`

*0x343*

This read/write register contains exception-specific information.

On a breakpoint, address-misaligned, or access-fault exception, `mtval` is set to the faulting address.

On an illegal instruction exception, the `mtval` register is set to the faulting instruction bits.


All other traps write a value of zero to `mtval`.


### Machine Configuration Pointer Register `mconfigptr`

*0xF15*

This is a read-only zero register indicating that a configuration data structure does not exist.

### Machine Timer Registers `mtime` and `mtimecmp`

These are 64-bit, memory-mapped registers.

| Address | Name |
| --- | --- |
| 0xFFFF_FF90 | `mtime` |
| 0xFFFF_FF94 | `mtimeh` |
| 0xFFFF_FF98 | `mtimecmp` |
| 0xFFFF_FF9C | `mtimecmph` |

The `mtime` register is incremented every microsecond.
At reset, `mtime` is reset to 0, thus it counts microseconds since reset.
Writing to `mtime` allows for synchronization with wall-clock time.

The `mtimecmp` register is used to control the machine timer interrupt.
If `mtime` is unsigned greater than or equal to `mtimecmp` an the machine timer interrupt pending bit in [`mip`](#machine-interrupt-pending-mip) is set.
The interrupt can be cleared by writing `mtimecmp` to a value greater than `mtime`, or writing `mtime` to a value less than `mtimecmp`.

The following code sequence should be used for writes to `mtimecmp` to avoid spurious timer interrupts

```asm
# New comparand is in a1:a0.
li t0, -1
la t1, mtimecmp
sw t0, 0(t1) # No smaller than old value.
sw a1, 4(t1) # No smaller than new value.
sw a0, 0(t1) # New value.
```
