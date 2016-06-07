/* http://www.embedded.com/design/mcus-processors-and-socs/4026075/Building-Bare-Metal-ARM-Systems-with-GNU-Part-2 */
/* http://www.embedded.com/design/mcus-processors-and-socs/4026080/Building-Bare-Metal-ARM-Systems-with-GNU-Part-3 */
OUTPUT_FORMAT("elf32-bigarm")
OUTPUT_ARCH(arm)
ENTRY(_start)
MEMORY {
       ROM (rx)  : ORIGIN = 0xFFFF0000, LENGTH = 4031
       SRAM (rw) : ORIGIN = 0x80000000, LENGTH = 256
}

SECTIONS {
        __nvram_end = 0x80000100;
        /* ARM reset vectors and startup code */
        .reset : {
               *boot1_startup.o (.text);
               . = ALIGN(4);
        } >ROM
        /* SRAM structure */
        .nvram : {
              nvram_flags = .; . += 4;
              nvram_check = .; . += 4;
              nvram_bootfs = .; . += 16;
              nvram_bootscreen = .; . += 16;
              nvram_bootgpu = .; . += 16;
              *(.nvram .nvram.*)
              KEEP(*(.nvram .nvram.*));
        } >SRAM
        /* Initialized read-write data */
        .data : {
              __data_load = LOADADDR(.data);
              __data_start = .;
              *(.data .data.* .gnu.linkonce.d.*)
              . = ALIGN(4);
              __data_end = .;
        } >SRAM AT>ROM
        /* Uninitialized read-write data */
        .bss : {
              __bss_start = .;
              *(.bss .bss.* .gnu.linkonce.b.*)
              . = ALIGN(4);
              __bss_end = .;
        } >SRAM
        /* Code and constants */
        .text : {
              CREATE_OBJECT_SYMBOLS
              *(.text .text.* .gnu.linkonce.t.*)
              *(.rodata .rodata.* .gnu.linkonce.r.*)
        } >ROM
        _end = .;
        __end = _end;
        PROVIDE(end = .);
}
