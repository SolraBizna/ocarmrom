OUTPUT_FORMAT("elf32-bigarm")
OUTPUT_ARCH(arm)
ENTRY(_exception_reset)
MEMORY {
       RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 192k
}

/* The number of bytes of memory to reserve for each stack */
C_STACK_SIZE   = 512;
IRQ_STACK_SIZE = 0;
FIQ_STACK_SIZE = 0;
SVC_STACK_SIZE = 0;
ABT_STACK_SIZE = 0;
UND_STACK_SIZE = 0;

SECTIONS {
        /* Startup code, interrupt vectors */
        .startup : {
             KEEP(*startup.o(.text))
        } >RAM
        /* Code (and read-only data) */
        .text : {
              CREATE_OBJECT_SYMBOLS
              *(.text .text.* .gnu.linkonce.t.*)
              *(.rodata .rodata.* .gnu.linkonce.r.*)
              . = ALIGN(4);
        } >RAM
        /* Initialized read-write data */
        .data : {
              *(.data .data.* .gnu.linkonce.d.*)
              . = ALIGN(4);
        } >RAM
        /* Uninitialized read-write data */
        .bss : {
              *(.bss .bss.* .gnu.linkonce.b.*)
              . = ALIGN(4);
        } >RAM
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
        } >RAM
        __heap_start = .;
}
