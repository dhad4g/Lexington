# GPro Lexington RISC-V CPU

![Status](https://img.shields.io/badge/status-active_development-blue)
![Sim](https://img.shields.io/badge/simulation-passing-green)
![FPGA](https://img.shields.io/badge/FPGA-failing-red)


The GPro 1 (Lexington) is the first generation of RISC-V processors designed by
[Gerber Prototyping](https://g-proto.com).
Intended for educational use for simulation, FPGA implementation, and physical design.
The current toolchain uses AMD Xilinx Vivado:registered: and the
[RISC-V GNU Compiler toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain).
Supported target hardware is the [Digilent:registered: Basys 3 Artix-7 FPGA](https://digilent.com/shop/basys-3-artix-7-fpga-trainer-board-recommended-for-introductory-users/).
The project is made to be easily adaptable to any Xilinx product.

The GPro 2 (Saratoga) is currently in early development. The current status can be found at
[https://github.com/GProCPU/Saratoga](https://github.com/GProCPU/Saratoga),

## Features

- RV32I instruction set
- CSR extension
- Machine-mode only
- Modified-Harvard architecture
- Single cycle execution
- Machine timer with interrupt support
- 2 General purpose timer with interrupt support
- 48 GPIO (3 banks of 16 pins)
- 6 external interrupt pins (2 per GPIO bank)
- UART interface with interrupt support

## Project Status

| Component | Docs | Sim | FPGA |
| --- | --- | --- | --- |
| Core  | ![](https://img.shields.io/badge/complete-g)      | ![](https://img.shields.io/badge/passing-g)       | ![](https://img.shields.io/badge/failing-red)
| Debug | ![](https://img.shields.io/badge/missing-grey)    | ![](https://img.shields.io/badge/missing-grey)    | ![](https://img.shields.io/badge/missing-grey)
| AXI   | ![](https://img.shields.io/badge/complete-g)      | ![](https://img.shields.io/badge/passing-g)       | ![](https://img.shields.io/badge/failing-red)
| GPIO  | ![](https://img.shields.io/badge/complete-g)      | ![](https://img.shields.io/badge/passing-g)       | ![](https://img.shields.io/badge/failing-red)
| Timers| ![](https://img.shields.io/badge/partial-yellow)  | ![](https://img.shields.io/badge/untested-orange) | ![](https://img.shields.io/badge/untested-orange)
| UART  | ![](https://img.shields.io/badge/missing-grey)    | ![](https://img.shields.io/badge/missing-grey)    | ![](https://img.shields.io/badge/missing-grey)

## Design and Microarchitecture

Complete design documentation can be found in [docs/Lexington.md](./docs/Lexington.md)

## Getting Started

The toolchain can be set up using either a Linux environment or a hybrid Windows/WSL environment.
Some Linux is required as the RISC-V GNU toolchain does not support Windows.

### Vivado

Install Vivado on either Linux or Windows.
If using Windows, you must also install git for Windows using the default install directory.

### GCC

To install the RISC-V GNU toolchain by following [these instruction](./docs/Toolchain.md).
If using Windows, this must installed in WSL.
