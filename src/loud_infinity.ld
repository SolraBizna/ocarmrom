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
        /* ARM reset vectors and startup code */
        .reset 0xFFFF0000 : {
               KEEP(*boot0.o (.text));
               . = ALIGN(4);
        } >ROM
        /* Code and constants */
        .text : {
              CREATE_OBJECT_SYMBOLS
              *(.text .text.* .gnu.linkonce.t.*)
              *(.rodata .rodata.* .gnu.linkonce.r.*)
               . = ALIGN(4);
        } >ROM
        /* BSS */
        .bss : {
              *(.bss .bss.* .gnu.linkonce.b.*)
        } >SRAM
}
