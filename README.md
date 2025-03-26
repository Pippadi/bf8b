# bf8b

**B**aby's **F**irst **8**-**B**it computer.

My first Verilog project. I have no idea what I'm doing.

## Details

- 4-stage pipeline with fetch, decode, execute, and writeback
- 8-bit data bus
- 8-bit address bus
- 16 general-purpose registers
- Up to 16 two-byte instructions (8 implemented so far; nothing set in stone)

## Instruction set

| Mnemonic | Instruction Format | Description |
|----------|--------------------|-------------|
| JMP  | `0000  XXXX    [ADDRESS]`   | `PC` to `ADDRESS` |
| LOD  | `0001 [REG0]   [ADDRESS]`   | Load value at `ADDRESS` into `REG0` |
| STR  | `0010 [REG0]   [ADDRESS]`   | Store from `REG0` to `ADDRESS` |
| ADD  | `0011 [REG0] [REG1] [REG2]` | `REG0` = `REG1` + `REG2` |
| ADDI | `0100 [REG0] [REG1] [IMM4]` | `REG0` = `REG1` + `IMM` |
| LODI | `0101 [REG0]     [IMM8]   ` | Load `IMM` into `REG0` |
| NAND | `0110 [REG0] [REG1] [REG2]` | `REG0` = `~(REG1 & REG2)` |
| JEQZ | `0111 [REG0]   [ADDRESS] `  | `PC` to `ADDRESS` if `REG0` = 0 |

- `PC` is the program counter.
- `ADDRESS` is an 8-bit memory address
- `REGn` is the 4-bit address for one of registers `r0` to `r15`
- `IMM4` is a 4-bit immediate sign-extended to 8 bits for the concerned operation
- `IMM8` is an 8-bit immediate

## Programming

Edit [the testbench](/8bit_tb.v). That's right.

Execution begins at address `0x00`.
Ensure that you specify an adequate number of clock pulses in the simulation for your program.
Dump bytes of `mem` relevant to you to the VCD file with `$dumpvars(0, mem[ADDR])`.

Build with the Makefile. This is written to use Icarus Verilog and GTKWave.

```sh
make clean
make          # Compile with `iverilog`
make 8bit.vcd # Make value change dump (simulation)
make sim      # View waveforms in GTKWave
```

## Notes

An 8-bit data bus is a huge bottleneck when fetching 16-bit instructions.
An LRU instruction cache has been implemented to compensate. Its default size is 8 instructions (each cell is 16-bits).
On-the-fly modification of instructions is not supported, as the fetch stage does not check for consistency between cached instructions and memory.

Basic branch prediction is a future goal.

