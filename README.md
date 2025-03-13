# bf8b

**B**aby's **F**irst **8**-**B**it computer.

My first Verilog project. I have no idea what I'm doing.

## Details

- 4-stage pipeline with fetch, decode, execute, and writeback
- 8-bit data bus
- 8-bit address bus
- Two general-purpose registers
- Four single-byte instructions

## Instruction set

| Mnemonic | Opcode | Description |
|----------|--------|-------------|
| JMP | `00 [5:0     ADDRESS]` | Jump to `0b00[ADDRESS]` |
| LOD | `01 DST [4:0 ADDRESS]` | Load from memory address `0b111[ADDRESS]` into register `DST` |
| STR | `10 SRC [4:0 ADDRESS]` | Store from register `SRC` to memory at `0b111[ADDRESS]` |
| ADD | `11 DST x  x  x  x  x` | Add `a` and `b` and store in `DST` |

For `DST`/`SRC`:
- `a` = 0
- `b` = 1

## Programming

Edit [the testbench](/8bit_tb.v). That's right.

Execution begins at address `0x00`.
Jumps can only be performed in the first 64 bytes of memory, and only the last 32 bytes of memory are addressable with `LOD` and `STR`.
Also ensure that you specify an adequate number of clock pulses in the simulation for your program.
Dump bytes of `mem` relevant to you to the VCD file with `$dumpvars(0, mem[ADDR])`.

Build with the Makefile. This is written to use Icarus Verilog and GTKWave.

```sh
make clean
make          # Compile with `iverilog`
make 8bit.vcd # Make value change dump (simulation)
make sim      # View waveforms in GTKWave
```
