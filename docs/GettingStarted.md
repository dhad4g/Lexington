# Getting Started

This guide will cover how to prepare the build environment and run implementation
for the `blink` software project targeting the Digilent Basys3 FPGA. Additionally,
simulating RTL testbenches is covered.

## Dependencies

- Lexington repository
- Xilinx Vivado
- RISC-V GNU compiler toolchain compiled from source

## Compiler Installation

The following is a condensed installation guide for the toolchain.
The complete guide can be found at https://github.com/riscv-collab/riscv-gnu-toolchain

***Note: compiling the RISC-V GNU toolchain may take over an hour***

***Warning: installation takes around 6.65 GB of disk and download size***

### Getting the source

The RISC-V GNU toolchain repository uses submodules, but submodules will fetch
automatically on demand and do not need to be downloaded/initialized by the user.

```bash
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
```

### Prerequisites

Several standard packages are needed to build the toolchain.

**Ubuntu**
```bash
sudo apt-get install autoconf automake autotools-dev curl python3 python3-pip libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev
```

**Fedora/CentOS/Rocky/RHEL**
```bash
sudo yum install autoconf automake python3 libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel
```

**Arch**
```bash
sudo pacman -Syyu autoconf automake curl python3 libmpc mpfr gmp gawk base-devel bison flex texinfo gperf libtool patchutils bc zlib expat
```

**OS X** using [Homebrew](https://brew.sh/)
```bash
brew install python3 gawk gnu-sed gmp mpfr libmpc isl zlib expat texinfo flock
```
*To build the glibc (Linux) on OS X, you will need to build within a case-sensitive
file system. The simplest approach is to create and mount a new disk image with
a case sensitive format. Make sure that the mount point does not contain spaces.
This is not necessary to build newlib or gcc itself on OS X.*

### Build and Install (Newlib multilib)

To build the Newlib cross-compiler with support for both 32-bit and 64-bit, pick
an install path (that is writeable). If you choose, say, `/opt/riscv`, then add
`/opt/riscv/bin` to your PATH. Then, simply run the following command:

```bash
mkdir build
cd build
sudo mkdir /opt/riscv
../configure --prefix=/opt/riscv --with-arch=rv32i_zicsr --with-abi=ilp32
sudo make
```

The installation can be completed without root privilege by choosing an installation
directory other than `/opt/riscv/`.

The `--with-arch` and `--with-abi` options must be used when targeting the
`zicsr` extension (used by Lexington).

### Add to PATH

You can add the RISC-V GNU toolchain to all user's PATH in either the `/etc/profile`
or `/etc/environment` file, depending on you platform. If neither file exists,
search for how to add to all user's PATH for you OS or distribution.

If you do not have root access, or only want to add the toolchain to your user's
path, you can add the following line to your `.bashrc` file.

```bash
export PATH="/opt/riscv/bin:$PATH"
```

You can check if the installation succeeded and was added to you path by
*restarting you terminal* then running `which riscv64-unknown-elf-gcc`. It will
print something like `/opt/riscv/bin/riscv64-unknown-elf-gcc` if it was successful.

<br><br>

## Building a Software Project

Compiling for the GPro Lexington requires that the RISC-V GNU toolchain is installed
as specified above. After the toolchain has been installed, projects can be compiled
using a Makefile.

### Platform Files

The software compile process relies on several key files platform files. These
files are located in the `sw/common` directory.

- `startup_lexington.S` This assembly files contains startup code for Lexington.
- `lexington.ld` This is the linker script that tells the compiler how to organize machine code and data for Lexington's memory layout.
- `lexington.mk` This is the base Makefile required to be included in all Lexington project Makefile's.

### Makefile

Example projects with Makefile's can be in the `sw/examples` directory.
These each include a minimal Makefile.

```makefile
LEXINGTON_HOME = ../../..

include $(LEXINGTON_HOME)/sw/common/lexington.mk
```

The first line sets the `LEXINGTON_HOME` variable to three directories above the
current directory. The next line includes the lexington platform Makefile required
by all projects.

The project can be built by running the following command from the software project
directory.

```bash
make build
```

This will generate the necessary machine code file `rom.hex` as well as other
intermediate build files.


## Implementation

Generating a `.bit` file can be done by using the `./fpga.sh` script in the
repository root directory. A target board and software project must both be
selected. To implement the `blink` project for the `Basys3` target, the following
command should be run.

```bash
./fpga.sh Basys3 blink
```

This will create the file `./build/implement/Basys3.bit` which can be used to
program the board. The 16 LEDs should flash from right to left then back again.

## Running Testbenches

Testbenches can be run using the `./sim.sh` script. The `alu` module found in
`./rtl/core/alu.sv` has it's associated testbench in `./testbench/core/alu_TB.sv`.
The filenames and module names are important for the scripts to automatically find
all necessary files. The testbench can be run with the following command

```bash
./sim.sh core/alu
```

This testbench includes behavior to automatically check the outputs for correct
behavior. The output should be followed by a `PASSED all tests` line. Any generated
files (i.e. log outputs, vcd dump files) will located in `./build/sim/core/alu/`.

## RTL Dependency Include

Some RTL modules require others modules for simulation and implementation. These
dependencies can be included using specially formatted Verilog comments typically
located at the top of a file. The `core` module depends on many other modules, all
of which are located in `./rtl/core/`. The first line of `./rtl/core.sv` includes
these dependencies with the syntax `//depend core/*.sv`. This will recursively
include all files in the `./rtl/core/` directory. It is important to note that
dependency parsing is not hierarchical (yet), i.e. `//depend` statements inside
files included using `//depend` are not included. All dependencies for a module
must be specified in the that module.

The `core_TB` testbench file shows additional examples of dependency resolution
mechanism. When running `./sim.sh core`, both `./rtl/core.sh` and `./testbench/core_TB.sh`
will be included in the source files as well as all `//depend` statements inside
those two files. All `//depend` file paths are relative the RTL root directory
`./rtl` (even for testbench files). It is not currently possible to include another
testbench file as a dependency. The `core_TB` also depends on the `rom` and `ram`
modules as these are not included in the `core` module.

Additionally, commands can be run before simulation or implementation by using
a `//cmd` statement. Each command is run in it's own bash sub-shell. The location
of repository root directory can be accessed using the `${PROJ_DIR}` variable.
A demonstration of this is found in `core_TB.sv` which compiles the `core_test`
project the copies it to the build directory.


