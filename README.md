# bf8b

**B**aby's **F**irst **8**-**B**it computer.

My first Verilog project. I have no idea what I'm doing.

## Details

- 4-stage pipeline with fetch, decode, execute, and writeback
- 8-bit data bus
- 8-bit address bus
- 16 general-purpose registers
- Up to 16 two-byte instructions (8 implemented so far; nothing set in stone)
- LRU Instruction cache

Vivado says 368 LUTs and 454 FFs.

## Instruction set

| Mnemonic | Instruction Format | Description |
|----------|--------------------|-------------|
| JMP  | `0000 [REG0]     [OFF8]   ` | `PC` to address `REG0 + OFF` |
| LOD  | `0001 [REG0] [REG1] [OFF4]` | Load value at address `REG1 + OFF` into `REG0` |
| STR  | `0010 [REG0] [REG1] [OFF4]` | Store from `REG0` to address `REG1 + OFF` |
| ADD  | `0011 [REG0] [REG1] [REG2]` | `REG0` = `REG1` + `REG2` |
| ADDI | `0100 [REG0] [REG1] [IMM4]` | `REG0` = `REG1` + `IMM` |
| LODI | `0101 [REG0]     [IMM8]   ` | Load `IMM` into `REG0` |
| NAND | `0110 [REG0] [REG1] [REG2]` | `REG0` = `~(REG1 & REG2)` |
| JEQZ | `0111 [REG0] [REG1] [OFF4]` | `PC` to address `REG0 + OFF` if `REG1` = 0 |

- `REGn` is the 4-bit address for one of registers `r0` to `r15`
- `PC` is the program counter
- `OFF8` is a signed 8-bit offset to be added to the target address
- `OFF4` is a 4-bit offset, sign-extended to 8 bits, to be added to the target address
- `IMM8` is an 8-bit immediate
- `IMM4` is a 4-bit immediate, sign-extended to 8 bits, for the concerned operation

## Programming

Edit [the testbench](/8bit_tb.v). That's right.

Execution begins at address `0x00`.
Ensure that you specify an adequate number of clock pulses in the simulation for your program.
Dump bytes of `mem` relevant to you to the VCD file with `$dumpvars(0, mem[ADDR])`.

Build with the Makefile. This is written to use Icarus Verilog and GTKWave.
The latest commits on the `main` branch _should_ synthesize in Vivado as well.

```sh
make clean
make
make 8bit.vcd
make sim
```

## Architectural Notes

An 8-bit data bus is a huge bottleneck when fetching 16-bit instructions.
Making the memory bus wider would be boring, so an LRU instruction cache has been implemented.
Its default size is 8 instructions (each cell is 16 bits).
On-the-fly modification of instructions is not supported, as the fetch stage does not check for consistency between cached instructions and memory.

LRU behavior is implemented by building the cache around a modified shift register.
Each level in the shift register holds an address and the corresponding data.
Further, each level can be enabled or disabled individually, meaning that shifts can be selectively performed within the register.

Data to be cached is shifted in.
Writing data whose address is not present in the cache results in the oldest data getting shifted out.
When there is a hit on data, the hit data is shifted into the top, and all the data above it, are shifted.
In other words, the hit data is shifted to the top of the shift register, its old position being overwritten while all the older cells remain untouched.
It is the position of the data within the shift register that determines age. There are no separate bits spent on tracking age.

Basic branch prediction and a D cache are future goals.
