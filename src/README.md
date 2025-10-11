# bf8b

A dumb pipelined RISC-V rv32i core + peripherals.

It started off as a stupid simple 8-bit core, but grew from there.
My ultimate goal, assuming I remain interested, is to have a somewhat useful microcontroller design.

## Details

- 4-stage pipeline - Fetch, Decode, Execute, Writeback
- In-order, single-issue
- No branch prediction
- DMA UART peripheral

### Memory

As a challenge, the core was designed with a single memory interface for both instructions and data.
The memory interface performs arbitration internally.

The memory interface itself is 32 bits wide with all 32 address lines broken out, and individual write enables for each byte lane.
This is likely to be shrunk to 12 or 14 bits to save die space.

#### Internal Interface

A `client` is anything that can request memory accesses - the instruction fetch unit, execute stage, or a peripheral (just DMA UART for now).
The memory interface arbitrates between clients using a simple fixed priority scheme:

1. Execute stage
2. Instruction fetch stage
3. UART RX
4. UART TX

Nonaligned accesses are supported, with the memory interface handling the necessary read-modify-write cycles for writes.

##### Ports

| Port Name | Direction | Width | Description |
|-----------|-----------|-------|-------------|
| `mem_data_in` | input     | 32    | Data read from memory |
| `mem_ready` | input     | 1     | Memory ready/ack signal (active high) |
| `mem_req`   | output    | 1     | Memory request signal (active high) |
| `mem_addr`  | output    | 32    | Memory address |
| `mem_data_out` | output    | 32    | Data to write to memory |
| `mem_we`    | output    | 1     | Write enable (1 = write) |
| `mem_width`    | output    | 2     | 8, 16, or 32-bit access specifier |

`mem_width` above is encoded as follows:
- `2'b00` = 8-bit access
- `2'b01` = 16-bit access
- `2'b10` = 32-bit access

A client sets `mem_req` high to request a memory access, with `mem_we`, `mem_addr`, `mem_data_out`, and `mem_width` set appropriately.
The memory interface will assert `mem_ready` when the access is complete, and provide the read data on `mem_data_in` for read accesses.
`mem_req` is deasserted by the client once `mem_ready` is seen and, if relevant, the read data has been latched.
