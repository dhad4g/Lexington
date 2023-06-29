

APP_SRC ?= $(wildcard ./*.c) $(wildcard ./*.cpp) $(wildcard ./*.s) $(wildcard ./*.S)

# Compiler toolchain
RISCV_PREFIX ?= riscv64-unknown-elf-

# CPU architecture and ABI
MARCH ?= rv32i_zicsr
MABI  ?= ilp32

LEXINGTON_HOME ?= ../../..


# --------------------------------------------------
# Lexington software framework
# --------------------------------------------------
# Linker script and startup file
LEXINGTON_COM_PATH = $(LEXINGTON_HOME)/sw/common
# Main library include files
LEXINGTON_INC_PATH = $(LEXINGTON_HOME)/sw/lib/include
# Main library source files
LEXINGTON_SRC_PATH = $(LEXINGTON_HOME)/sw/lib/src


# Core libraries
CORE_SRC  = $(wildcard $(LEXINGTON_SRC_PATH)/*.c) $(wildcard $(LEXINGTON_SRC_PATH)/*.cpp)
# Start-up code
CORE_SRC += $(LEXINGTON_COM_PATH)/startup_lexington.S

# Linker script
LD_SCRIPT ?= $(LEXINGTON_COM_PATH)/lexington.ld

# Main output files
APP_ELF = main.elf
APP_BIN = main.bin
DUMP    = disassemble.dump

SRC  = $(APP_SRC)
SRC += $(CORE_SRC)
#OBJ  = $(SRC:%;%.o)


# --------------------------------------------------
# Tools
# --------------------------------------------------
CC      = $(RISCV_PREFIX)gcc
OBJDUMP	= $(RISCV_PREFIX)objdump
OBJCOPY = $(RISCV_PREFIX)objcopy
SIZE    = $(RISCV_PREFIX)size
GDB     = $(RISCV_PREFIX)gdb


# --------------------------------------------------
# Flags
# --------------------------------------------------
# Main compiler opts
CC_OPTS  = -march=$(MARCH) -mabi=$(MABI) -Wall -Werror -ffunction-sections -fdata-sections -Wl,--gc-sections -nostartfiles -Os
# Compiler warning flags
CC_OPTS += -Wall -Werror -Wshadow -Wdouble-promotion -Wformat-overflow -Wformat-truncation -Wundef -fno-common -Wconversion
# Compiler debug flags
CC_OPTS += -g3
# Linker flags
LD_LIBS = -lm -lc -lgcc


# Targets
build:          $(APP_BIN)
disassemble:    $(DUMP)


$(APP_ELF):
	@$(CC) $(CC_OPTS) -T $(LD_SCRIPT) $(SRC) $(LD_LIBS) -o $@


$(APP_BIN): $(APP_ELF)
	@$(OBJCOPY) -I elf32-little $< -j .text   -O binary text.bin
	@$(OBJCOPY) -I elf32-little $< -j .rodata -O binary rodata.bin
	@$(OBJCOPY) -I elf32-little $< -j .data   -O binary data.bin
	@cat text.bin rodata.bin data.bin > $@
	@rm -f text.bin rodata.bin data.bin


$(DUMP): $(APP_ELF)
	@$(OBJDUMP) -d $< > $@
