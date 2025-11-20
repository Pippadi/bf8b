# bf8b

A simple RISC-V CPU core. Currently implements barebones `rv32i`.

> Formerly **B**aby's **F**irst **8**-**B**it computer

## Details

- 4-stage pipeline with fetch, decode, execute, and writeback
- 32-bit data bus
- 32-bit address bus
- LRU Instruction cache
- In-order execution
- No exceptions or interrupts yet

For lower-level documentation, see the README files in the [`src`](/src) directory.

## Programming

The [`test/prog2verilog.py`](/test/prog2verilog.py) script converts a RISC-V assembly program into a set of hex files that can be read by the simulator.
The process it uses is based off of what I learned [here](https://www.youtube.com/watch?v=n8g_XKSSqRo).
You need the RISC-V GCC toolchain installed to use it (called `cross-riscv64-elf-gcc15` for me on openSUSE).

Use like so:

```sh
python3 test/prog2verilog.py test/fibonacci.s -d
```

Edit [the testbench](/src/bf8b_tb.v) so that the `$readmemh` directives read the correct hex files.

Execution begins at address `0x00000000` (specified in the [linker script](/test/bf8b.ld)).
Ensure that you specify an adequate number of clock pulses in the simulation for your program.
Dump bytes of `mem` relevant to you to the VCD file with `$dumpvars(0, mem[ADDR])`.

Build with the Makefile. This is written to use Icarus Verilog and GTKWave.
The latest commits on the `main` branch _should_ synthesize in Vivado as well.

```sh
make clean
make
make bf8b.vcd
make sim
```

## Architectural Notes

The LRU instruction cache has a default size of 32 instructions.
On-the-fly modification of instructions is not supported, as the fetch stage does not check for consistency between cached instructions and memory.

LRU behavior is implemented by building the cache around a modified shift register.
Each level in the shift register holds an address and the corresponding data.
Further, each level can be enabled or disabled individually, meaning that shifts can be selectively performed within the register.

Data to be cached is shifted in.
Writing data whose address is not present in the cache results in the oldest data getting shifted out.
When there is a hit on a line, the hit data is shifted into the top, and all the data above it, is shifted.
In other words, the hit data is shifted to the top of the shift register, its old position being overwritten while all the older cells remain untouched.
It is the position of the data within the shift register that determines age. There are no separate bits spent on tracking age.
