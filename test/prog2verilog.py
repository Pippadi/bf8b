#!/usr/bin/python3

import subprocess
import os
import argparse


def generate_coe_file(hex_dump_path, coe_path):
    """
    Generate a 32-bit little-endian COE file from the hex dump
    """
    with open(hex_dump_path, "r") as f:
        hex_lines = f.readlines()

    # Prepare COE file header
    coe_content = [
            "memory_initialization_radix=16;\n",
            "memory_initialization_vector=\n"
            ]

    # Convert hex bytes to 32-bit little-endian words
    for i in range(0, len(hex_lines), 4):
        # Ensure we have 4 bytes for a complete 32-bit word
        if i + 3 < len(hex_lines):
            # Little-endian: reverse the byte order
            word = (
                    hex_lines[i+3].strip() +
                    hex_lines[i+2].strip() +
                    hex_lines[i+1].strip() +
                    hex_lines[i].strip()
                    )
            coe_content.append(word + ",\n")

    # Remove the last comma and add terminating semicolon
    coe_content[-1] = coe_content[-1].rstrip(",\n") + ";"

    # Write COE file
    with open(coe_path, "w") as f:
        f.writelines(coe_content)


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

    coe_path = os.path.join(args.output_dir, f"{base_name}.coe")
    generate_coe_file(hex_dump_path, coe_path)

    # Delete intermediate files if requested
    if args.delete_intermediate:
        os.remove(executable_path)
        os.remove(bin_dump_path)
        os.remove(hex_dump_path)


if __name__ == "__main__":
    main()
