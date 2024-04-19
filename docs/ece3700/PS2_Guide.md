# PS/2 Keyboard Project

This document serves as a guide intended for Utah State University ECE 3700
students working on the PS/2 keyboard project. It provides information about
integrating a PS/2 keyboard AXI peripheral that can be used with the VGA demo
software project.


## Getting Started

It is recommended that you use a GitHub account so that you can fork the repository
and push your changes. Open the GitHub repository in a web browser using the link
below. In the top right corner, beneath the navigation bar, click `Fork`. On the
next page, select what you would like your fork to be called (or leave default),
then click `Create fork`.

[https://github.com/GProCPU/Lexington](https://github.com/GProCPU/Lexington)

You should now be redirected to your fork (copy) of the repository. Take note
of the URL so you can easily access it later. Click the green `<> Code` button,
then select `SSH` and copy link the link. Open a terminal in genesys in the
directory you would like to clone the repository to, then run `git clone <link>`.

To be able to push your changes, you will need to set up an ssh key in GitHub.
You can follow [this](https://www.inmotionhosting.com/support/server/ssh/how-to-add-ssh-keys-to-your-github-account/)
tutorial to do that.

Refer to the Building a Software Project, Implementation, and Running Testbenches
sections of the main
[Getting Started](https://github.com/GProCPU/Lexington/blob/master/docs/GettingStarted.md#building-a-software-project)
guide for information about the repository workflow. Also, check out the
[Repository Structure](https://github.com/GProCPU/Lexington/blob/master/docs/Repo.md)
document to get acquainted with how the file structure is organized.


## Tasks

You have the following tasks that need to be completed for this project:

### 1. Study PS/2 Interface Specification

You should become acquainted with the PS/2 interface specification. the
[Basys3 Reference Manual](https://digilent.com/reference/programmable-logic/basys-3/reference-manual#hid_controller)
HID Controller section contains the information you will need. Pay attention
to the waveform diagram, but don't worry about the timing table as our clock
will be running much faster than needed and we are only reading data.

### 2. PS/2 Controller

#### 2a. Document PS/2 Controller Design

You will need to complete the Behavior section of `PS2_controller.md`. The intent
is to logically design the module before being bogged down by implementing the
HDL. This section should include a state transition diagram. You can add an image
to this directory then include it in `PS2_controller.md` using this syntax:
`![](ps2_controller_state_diagram.png)`.

#### 2b. Implement PS/2 Controller

Implement the PS/2 controller as a SystemVerilog module name `ps2_controller` in
`rtl/peripheral/ps2_controller.sv`. Note that all Verilog syntax is valid in
SystemVerilog. You should lean heavily on the design you documented in Step 2.

The UART RX module (`rtl/peripherals/uart_rx.sv`) has a very similar design. You
may want to use this as a starting point and reference. Note that it does use
oversampling by 8 (i.e. 8 samples are taken per bit and the middle three are
*averaged*).

#### 2c. Test PS/2 Controller

Move `ps2_controller_TB.sv` from this directory to
`rtl/peripheral/ps2_controller_TB.sv`. Complete the TODO for the data bits in
the stimulus block. Verify your module received the correct key codes.

Run the testbench by navigating to the root of the repository and running:

```./sim.sh peripheral/ps2_controller```

The following files need to be in the right place with the right module name
for this to work:
- `rtl/peripheral/ps2_controller.sv` with module `ps2_controller`
- `testbench/peripheral/ps2_controller_TB.sv` with module `ps2_controller_TB`

### 3. PS/2 AXI module

TBD

### 4. Integrate with Processor and Software

TBD

