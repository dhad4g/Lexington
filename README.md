# GPro 2 (Saratoga) RISC-V CPU

![Status](https://img.shields.io/badge/status-initial_design-blue)
<!-- ![Sim](https://img.shields.io/badge/simulation-passing-green) -->
<!-- ![FPGA](https://img.shields.io/badge/FPGA-failing-red) -->


The GPro 2 (Saratoga) is the second generation of RISC-V processors designed by
[Gerber Prototyping](https://g-proto.com). Intended both FPGA implementation and
physical design. Originally intended to include a 5-stage pipeline has been
changed to a 3-stage pipeline. This processor is currently in the initial design phase as
the focus of a Graduate Independent Study course.

## Features

- RV32I instruction set
- Modified-Harvard architecture
- Machine-mode and User-mode privilege levels
- 3-stage pipeline

## Pipeline

The pipeline design can be found in [docs/Pipeline.md](./docs/Pipeline.md).
