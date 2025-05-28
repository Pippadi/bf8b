OUTPUT_ARCH("riscv")
OUTPUT_FORMAT("elf32-littleriscv")

ENTRY( _start )

SECTIONS {
    . = 0x00000000;
    .text : { *(.text) }
    .gnu_build_id : { *(.note.gnu.build-id) }
    .rodata : { *(.rodata) }

    . = 0x00000800;
    .data : { *(.data) }
    .sdata : { *(.sdata) }
    .debug : { *(.debug) }

    . += 0x100;
    stack_top = .;

    _end = .;
}

