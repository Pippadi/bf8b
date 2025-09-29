# UART controller

Right now, this UART controller supports only 8N1 (8 data bits, no parity, 1 stop bit) configuration.
It supports memory-mapped I/O for configuration and status monitoring, and DMA for nonblocking data transfer.
Baud rate is configurable via parameters (on the fly configuration coming soon).

Memory accesses are hardcoded to 8-bit width for simplicity.
Given how low UART speeds are, utilizing the full 32-bit memory bus is more trouble than it's worth.
UART data is buffered in FIFOs in the TX and RX paths to handle bursts of data.

## Modules

### [`fifo`](./fifo.v)

This is a simple FIFO module used for buffering data in the TX and RX paths.
This should be moved elsewhere later.

#### Parameters

| Parameter Name | Description | Default Value |
|----------------|-------------|---------------|
| `DATA_WIDTH`  | Width of the data bus | `8`           |
| `FIFO_DEPTH`  | Depth of the FIFO (number of entries) | `16`          |

#### Ports

| Port Name | Direction | Width | Description |
|-----------|-----------|-------|-------------|
| `clk`       | input     | 1     | Main clock signal |
| `rst`       | input     | 1     | Reset signal (active high) |
| `write_en` | input     | 1     | Write enable signal |
| `read_en`  | input     | 1     | Read enable signal |
| `data_in`  | input     | `DATA_WIDTH` | Data input to be written to FIFO |
| `data_out` | output    | `DATA_WIDTH` | Data output from FIFO |
| `full`     | output    | 1     | High when FIFO is full |
| `empty`    | output    | 1     | High when FIFO is empty |

### [`tx_serializer`](./tx_ser.v)

This module serializes parallel data into a serial stream for transmission over UART.

#### Ports

| Port Name | Direction | Width | Description |
|-----------|-----------|-------|-------------|
| `clk`       | input     | 1     | Main clock signal |
| `rst`       | input     | 1     | Reset signal (active high) |
| `tx_clk_posedge` | input     | 1     | See [`clockgen`](#clockgen) |
| `data_available` | input     | 1     | Indicates new data available for TX |
| `data`   | input     | 8     | Parallel data input to be serialized |
| `req`     | output   | 1     | Set high for 1 `clk` cycle to request new data  |
| `busy`    | output    | 1     | Signals high when transmitting |
| `tx`      | output    | 1     | Serial data output |

### [`rx_deserializer`](./rx_deser.v)

This module deserializes incoming serial data from UART into parallel data.

| Port Name | Direction | Width | Description |
|-----------|-----------|-------|-------------|
| `clk`       | input     | 1     | Main clock signal |
| `rst`       | input     | 1     | Reset signal (active high) |
| `rx_clk_posedge` | input     | 1     | See [`clockgen`](#clockgen) |
| `rx`      | input     | 1     | Serial data input |
| `data`   | output    | 8     | Parallel data output |
| `latch_data` | output    | 1     | Set high for 1 `clk` cycle to signal available |

### [`tx_manager`](./tx_manager.v)

This module manages retrieval of data from memory, and dispatching it to `tx_serializer`.
It instantiates `tx_serializer`.

| Port Name | Direction | Width | Description |
|-----------|-----------|-------|-------------|
| `clk`       | input     | 1     | Main clock signal |
| `rst`       | input     | 1     | Reset signal (active high) |
| `tx_clk_posedge` | input     | 1     | See [`clockgen`](#clockgen) |
| `tx_en`    | input     | 1     | Enable transmission |
| `tx_ptr_rst` | input     | 1     | Reset TX pointer to `tx_src_start` |
| `tx_src_start` | input     | 32 | Start address in memory for TX |
| `tx_src_stop` | input     | 32 | Stop address in memory for TX |
| `tx_mem_data_in` | input     | 32    | Data read from memory |
| `tx_mem_ready` | input     | 1     | High when memory data is valid |
| `tx_mem_req` | output    | 1     | Set high to request data from memory |
| `tx_mem_addr` | output    | 32    | Address to read data from memory |
| `tx_mem_width` | output    | 2     | Width of memory access |
| `tx_done`  | output    | 1     | Set high when transmission is complete |
| `tx`      | output    | 1     | Serial data output |

### [`rx_manager`](./rx_manager.v)

This module manages storing data received from `rx_deserializer` into memory.
It instantiates `rx_deserializer`.

| Port Name | Direction | Width | Description |
|-----------|-----------|-------|-------------|
| `clk`       | input     | 1     | Main clock signal |
| `rst`       | input     | 1     | Reset signal (active high) |
| `rx`      | input     | 1     | Serial data input |
| `en`        | input     | 1     | Enable reception |
| `deser_clk_posedge` | input     | 1     | See [`clockgen`](#clockgen) |
| `ptr_rst`   | input     | 1     | Reset RX pointer to `dma_buf_start` |
| `dma_buf_start` | input     | 32    | Start address in memory for RX |
| `dma_buf_end` | input     | 32    | End address in memory for RX |
| `mem_ready` | input     | 1     | Acknowledgement signal from memory |
| `mem_req`  | output    | 1     | Set high to request memory write |
| `mem_addr` | output    | 32    | Address to write data to memory |
| `mem_width` | output    | 2     | Width of memory access |
| `mem_data_in` | output    | 32    | Data to write to memory |
| `dma_buf_full` | output    | 1     | High when RX buffer is full |
| `ptr`      | output    | 32    | Current RX pointer address |

### [`clockgen`](./clockgen.v)

This module generates clock signals for the TX and RX serializers/deserializers based on the baud rate.

To avoid creating new clock domains, it generates a single-cycle pulse at the desired frequency, indicating the positive edge of the generated clock.
Circuits using this signal should operate on the main `clk` domain, but trigger their operations on the `*_clk_posedge` signal.

#### Parameters

| Parameter Name | Description | Default Value |
|----------------|-------------|---------------|
| `CLK_FREQ`     | Frequency of the main clock in Hz | `50_000_000` |
| `BAUD_RATE`    | Desired baud rate for UART communication | `115200` |
| `RX_CLKS_PER_BIT` | Number of oversampling clock cycles per bit for RX | `8` |

#### Ports

| Port Name | Direction | Width | Description |
|-----------|-----------|-------|-------------|
| `clk`       | input     | 1     | Main clock signal |
| `rst`       | input     | 1     | Reset signal (active high) |
| `tx_clk_posedge` | output    | 1     | Pulse indicating TX clock positive edge |
| `rx_clk_posedge` | output    | 1     | Pulse indicating RX clock positive edge |

`rx_clk_posedge` is generated at `BAUD_RATE * RX_CLKS_PER_BIT`, allowing for oversampling in the RX path.
`tx_clk_posedge` is generated at `BAUD_RATE`.

### [`uart`](./uart.v)

This is the top-level UART module that integrates the TX and RX managers along with the clock generator.
It instantiates `clockgen`, `tx_manager`, and `rx_manager`.

It also contains a register interface for configuration and status monitoring.
These registers are meant to be accessed as memory-mapped I/O, and support the same protocol as the memory interface.

#### Parameters

| Parameter Name | Description | Default Value |
|----------------|-------------|---------------|
| `CLK_FREQ`     | Frequency of the main clock in Hz | `50_000_000` |
| `BAUD_RATE`    | Desired baud rate for UART communication | `115200` |

#### Ports

| Port Name | Direction | Width | Description |
|-----------|-----------|-------|-------------|
| `clk`       | input     | 1     | Main clock signal |
| `rst`       | input     | 1     | Reset signal (active high) |
| `reg_req`  | input     | 1     | Register interface request signal |
| `reg_we`   | input     | 1     | Register interface write enable signal |
| `reg_select` | input     | 3     | Register select signal |
| `reg_data_in` | input     | 32 | Data input for register writes |
| `reg_data_out` | output    | 32    | Data output for register reads |
| `reg_ready` | output    | 1     | Signals acknowledgement/validity on register interface |

Other ports are passed through to the TX and RX managers.

#### Registers

| Register Name | Address | Description |
|---------------|---------|-------------|
| `GENERAL_CFG` | `0x0`  | General configuration register. Bits: <br> - Bit 0: TX Enable (1 to enable transmission) <br> - Bit 1: RX Enable (1 to enable reception) <br> - Bit 2: TX Done (read-only, set when transmission is complete) <br> - Bit 3: RX Buffer Full (read-only, set when RX buffer is full) <br> - Bit 4: RX Pointer Reset (write 1 to reset RX pointer to start address) |
| `TX_DMA_BUF_START` | `0x1`  | Start address in memory for TX DMA buffer. |
| `TX_DMA_BUF_END`  | `0x2`  | Stop address in memory for TX DMA buffer. |
| `RX_DMA_BUF_START` | `0x3`  | Start address in memory for RX DMA buffer. |
| `RX_DMA_BUF_END`   | `0x4`  | End address in memory for RX DMA buffer. |
| `RX_DMA_BUF_PTR`   | `0x5`  | Current RX pointer address (read-only). |

All registers are 32 bits wide.
