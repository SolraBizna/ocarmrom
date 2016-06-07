/* http://www.embedded.com/design/mcus-processors-and-socs/4026075/Building-Bare-Metal-ARM-Systems-with-GNU-Part-2 */
/* http://www.embedded.com/design/mcus-processors-and-socs/4026080/Building-Bare-Metal-ARM-Systems-with-GNU-Part-3 */
OUTPUT_FORMAT("elf32-bigarm")
OUTPUT_ARCH(arm)
ENTRY(_start)
MEMORY {
       ROM (rx)  : ORIGIN = 0xFFFF0000, LENGTH = 4031
       SRAM (rw): ORIGIN = 0x80000000, LENGTH = 256
}

/* The number of bytes of memory to reserve for each stack */
C_STACK_SIZE   = 236;
IRQ_STACK_SIZE = 0;
FIQ_STACK_SIZE = 0;
SVC_STACK_SIZE = 0;
ABT_STACK_SIZE = 0;
UND_STACK_SIZE = 0;

SECTIONS {
        /* ARM reset vectors and startup code */
        .reset 0xFFFF0000 : {
               KEEP(*startup.o (.text));
               . = ALIGN(4);
        } >ROM
        /* Code and constants */
        .text : {
              CREATE_OBJECT_SYMBOLS
              *(.text .text.* .gnu.linkonce.t.*)
              *(.rodata .rodata.* .gnu.linkonce.r.*)
               . = ALIGN(4);
        } >ROM
        /* stack */
        /* put the stack at the bottom of the SRAM so any overflow will be
           detected quickly */
        /* Stacks */
        .stack : {
              __stack_start__ = .;
              . += IRQ_STACK_SIZE;
              . = ALIGN(4);
              __irq_stack_top__ = .;
              . += FIQ_STACK_SIZE;
              . = ALIGN(4);
              __fiq_stack_top__ = .;
              . += SVC_STACK_SIZE;
              . = ALIGN(4);
              __supervisor_stack_top__ = .;
              . += ABT_STACK_SIZE;
              . = ALIGN(4);
              __abort_stack_top__ = .;
              . += UND_STACK_SIZE;
              . = ALIGN(4);
              __undefined_stack_top__ = .;
              . += C_STACK_SIZE;
              . = ALIGN(4);
              __c_stack_top__ = .;
              __stack_end__ = .;
        } >SRAM
        /* BSS */
        .bss : {
              __bss_start = .;
              *(.bss .bss.* .gnu.linkonce.b.*)
              __bss_end = .;
        } >SRAM
}
