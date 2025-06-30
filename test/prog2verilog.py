#!/usr/bin/python3

import subprocess
import os
import argparse


def main():
    parser = argparse.ArgumentParser(
        description="Generate hex files from RISC-V assembly"
    )
    parser.add_argument("input_file", help="Input assembly file (with .s extension)")
    parser.add_argument(
        "-d",
        "--delete-intermediate",
        action="store_true",
        help="Delete intermediate files",
    )
    args = parser.parse_args()

    if not args.input_file.endswith(".s"):
        print("Input file must be an assembly file with .s extension")
        return

    base_name = os.path.splitext(args.input_file)[0]

    # Compile the assembly file
    subprocess.run(
        [
            "riscv64-elf-gcc",
            "-march=rv32i",
            "-mabi=ilp32",
            "-static",
            "-mcmodel=medany",
            "-fvisibility=hidden",
            "-nostdlib",
            "-nostartfiles",
            "-T./bf8b.ld",
            args.input_file,
            "-o",
            base_name,
        ]
    )

    # Convert the binary file to hex
    subprocess.run(
        [
            "riscv64-elf-objcopy",
            "-O",
            "binary",
            "--gap-fill",
            "0x00",
            "--pad-to",
            "0x1000",
            base_name,
            f"{base_name}.bin",
        ]
    )
    subprocess.run(
        ["xxd", "-g", "1", "-c", "1", "-plain", f"{base_name}.bin"],
        stdout=open(f"{base_name}.hex", "w"),
    )

    # Split the hex file into four 1k blocks
    with open(f"{base_name}.hex", "r") as f:
        hex_lines = f.readlines()

    block_size = 1024
    num_blocks = 4

    for i in range(num_blocks):
        block_data = "".join(hex_lines[i::num_blocks])
        with open(f"{base_name}_block{i}.hex", "w") as f:
            f.write(block_data)

    # Delete intermediate files if requested
    if args.delete_intermediate:
        os.remove(base_name)
        os.remove(f"{base_name}.bin")
        os.remove(f"{base_name}.hex")


if __name__ == "__main__":
    main()
