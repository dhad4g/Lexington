# Trap Unit

The Trap Unit manages exceptions and interrupts.
Reset conditions are also handles by the trap unit.
This implementation uses purely combinatorial logic.

## Ports

#### Parameters

- **`WIDTH=32`** data width
- **`BOOT_ADDR=0x0000_0000`** initial PC boot address

#### Inputs

- **`inst_misaligned`** instruction address misaligned flag
- **`inst_access_fault`** instruction access fault flag
- **`data_misaligned`** load/store address misaligned flag
- **`data_access_fault`** load/store access fault flag
- **`data_load_store_n`** indicates source of load/store exception (0=store,1=load)
- **`decoder_next_pc[WIDTH-1:0]`** next PC calculated by decoder
- **`ext_int_0`** external interrupt 0
- **`ext_int_1`** external interrupt 1
- **`timer_int`** machine timer interrupt
- **`uart_int`** UART interrupt
- **`csr_mtvec`** machine trap-vector base-address CSR
- **`csr_mip`** machine interrupt pending CSR
- **`csr_mie`** machine interrupt enable CSR
- **`csr_mepc`** machine exception program counter CSR
- **`csr_mcause`** machine trap cause CSR
- **`csr_mtval`** machine trap value CSR
- **`csr_wr_en`** csr write enable
- **`csr_wr_sel[]`** csr wr select address
- **`csr_wr_data[WIDTH-1:0]`** csr write data

#### Outputs

- **`next_pc[WIDTH-1:0]`** next PC

## Behavior

At reset, the Trap Unit sets the PC to `BOOT_ADDR`.
During operation, if no exception or interrupt flags are asserted, the simply passes the `decoder_next_pc` value to the `next_pc` output.
If an exception/interrupt flag is asserted, 
