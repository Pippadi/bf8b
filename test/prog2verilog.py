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
    parser.add_argument("-o", "--output-dir", help="Output directory for hex files", default=".")
    args = parser.parse_args()

    if not args.input_file.endswith(".s"):
        print("Input file must be an assembly file with .s extension")
        return

    base_name = os.path.basename(os.path.splitext(args.input_file)[0])
    script_dir = os.path.dirname(os.path.realpath(__file__))

    executable_path = os.path.join(script_dir, base_name)
    bin_dump_path = os.path.join(script_dir, f"{base_name}.bin")
    hex_dump_path = os.path.join(script_dir, f"{base_name}.hex")

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
                f"-L{script_dir}",
                f"-T{script_dir}/bf8b.ld",
                args.input_file,
                "-o",
                executable_path,
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
                executable_path,
                bin_dump_path,
                ]
            )
    subprocess.run(
            ["xxd", "-g", "1", "-c", "1", "-plain", bin_dump_path],
            stdout=open(hex_dump_path, "w"),
            )

    # Split the hex file into four 1k blocks
    with open(hex_dump_path, "r") as f:
        hex_lines = f.readlines()

    block_size = 1024
    num_blocks = 4

    for i in range(num_blocks):
        block_data = "".join(hex_lines[i::num_blocks])
        with open(f"{args.output_dir}/{base_name}_block{i}.hex", "w") as f:
            f.write(block_data)

    # Delete intermediate files if requested
    if args.delete_intermediate:
        os.remove(executable_path)
        os.remove(bin_dump_path)
        os.remove(hex_dump_path)


if __name__ == "__main__":
    main()
