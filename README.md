# GPro Lexington RISC-V CPU

The GPro Lexington CPU is the first generation of RISC-V processors designed by [Gerber Prototyping](https://g-proto.com)

## Features

- RV32I instruction set
- Machine-mode only
- Harvard architecture
- Single cycle execution
- Machine timer with interrupt support
- 2 General purpose timer with interrupt support
- 48 GPIO (3 banks of 16 pins)
- 6 external interrupt pins (2 per GPIO bank)
- UART interface with interrupt support

The microarchitecture design is documented in [docs/Lexington.md](./docs/Lexington.md).

<br><br>

## Progress

### Documentation

- [x] ROM
- [x] RAM
- [ ] Core
  - [x] Register File
  - [x] PC
  - [x] Fetch Unit
  - [x] Decode Unit
  - [x] ALU
  - [x] Load/Store Unit (LSU)
  - [x] Instruction Bus (IBus)
  - [x] Data Bus (DBus)
  - [x] CSR
  - [x] Trap Unit
  - [ ] Machine Timer
- [ ] Peripherals
  - [x] AXI Manager
  - [ ] AXI Interconnect
  - [ ] GP Timer
  - [x] GPIO
  - [ ] UART

### Implementation

- [x] ROM
- [x] RAM
- [x] Core
  - [x] Register File
  - [x] PC
  - [x] Fetch Unit
  - [x] Decode Unit
  - [x] ALU
  - [x] Load/Store Unit (LSU)
  - [x] Instruction Bus (IBus)
  - [x] Data Bus (DBus)
  - [x] CSR
  - [ ] Trap Unit
  - [ ] Machine Timer
- [ ] Peripherals
  - [x] AXI Manager
  - [ ] AXI Interconnect
  - [ ] GP Timer
  - [x] GPIO
  - [ ] UART

### Testing

- [ ] ROM
- [ ] RAM
- [ ] Core
  - [x] Register File
  - [ ] PC
  - [x] Fetch Unit
  - [ ] Decode Unit
  - [x] ALU
  - [ ] Load/Store Unit (LSU)
  - [ ] Instruction Bus (IBus)
  - [ ] Data Bus (DBus)
  - [ ] CSR
  - [ ] Trap Unit
  - [ ] Machine Timer
- [ ] Peripherals
  - [ ] AXI Manager
  - [ ] AXI Interconnect
  - [ ] GP Timer
  - [ ] GPIO
  - [ ] UART