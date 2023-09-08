# UART Transceiver

This is a memory-mapped, full-duplex UART transceiver with FIFOs and interrupt support for both transmit and receive.
This implementation uses fixed parameters of 8 bits per word, 1 stop bit, and now parity of flow control support.
The BAUD rate is static at runtime, but can be configured at compile time with a default of 9600.

## Ports

### Parameters

- **`WIDTH = 32`** bus width
- **`BUS_CLK = 40_000_000`** bus clock frequency in Hz
- **`BAUD = 9600`** baud rate
- **`FIFO_DEPTH = 8`** FIFO depth for both TX and RX (depth 0 is invalid)

### Inputs

- **`rx`** UART RX signal
- **`axi_s`** AXI subordinate interface

### Outputs

- **`tx`** UART TX signal
- **`rx_int`** receive interrupt
- **`tx_int`** transmit interrupt

## Behavior

The memory-mapped registers shown in Table 1 control the behavior of the UART transceiver and interrupt signals.

**Table 1.** Memory-Mapped Registers

| Address Offset | Default | R/W | Name | Description |
| --- | --- | --- | --- | --- |
| 0x0 | 0 | r/w | `uartx_data`    | Passes send or receive 8 bits of data when written or read from respectively
| 0x4 | - | r/w | `uartx_conf`  | Config and status register

<br>

The `uartx_data` register is shown in Figure 1.
The lowest 8 bits are read/write and are used for data transmission.
The upper bits [31:9] are read-only zero.
A write to this register inserts data into the TX FIFO.
If the TX FIFO is full, the new write data is discarded.
A read from this register removes data from the RX FIFO.
If the RX FIFO is empty, `0x00` is read.
Additionally, if new RX data is received and the RX FIFO is full, the new data will be discarded.

![uartx_data register](../figures/UART_data_register.drawio.svg) \
**Figure 1.** Data register

<br>

The `uartx_conf` register is shown in Figure 2.
This register is used to configure the UART transceiver as well as read it's status.
Table 2 contains detailed information about each field.

![uartx_conf register](../figures/UART_config_register.drawio.svg) \
**Figure 2.** Config register

<br>

**Table 2.** Config Register Fields
| Index | Size | Default | R/W | Name | Description |
| --- | --- | --- | --- | --- | --- |
| 0 | 1 | 0 | ro | `rx_busy`    | Asserted when the data is currently being received
| 1 | 1 | 0 | ro | `tx_busy`    | Asserted the data is currently being transmitted
| 2 | 1 | 0 | ro | `rx_full`    | Asserted when the RX FIFO is full
| 3 | 1 | 1 | ro | `rx_empty`   | Asserted when the RX FIFO is empty
| 4 | 1 | 0 | ro | `tx_full`    | Asserted when the TX FIFO is full
| 5 | 1 | 1 | ro | `tx_empty`   | Asserted when the RX FIFO is empty
| 7:6 | 2 | 0 | r/w | `rx_int`  | RX interrupt configuration (*see Table 3*)
| 9:8 | 2 | 0 | r/w | `tx_int`  | TX interrupt configuration (*see Table 3*)
| 29:10 | 20 | 0 | ro | *reserved* | read-only zero
| 30 | 1 | 0 | ro | `rx_err`    | Sticky bit indicating an RX error. A read clears the bit
| 31 | 1 | 0 | wo | `rst`       | Writing a 1 to this bit resets the UART module. Reads always return zero.

<br>

**Table 3.** Interrupt Configuration
| Value | Mode |
| --- | --- |
| 0b00 | Interrupt disabled
| 0b01 | RX/TX done (single byte)
| 0b10 | FIFO full interrupt
| 0b11 | FIFO empty interrupt
