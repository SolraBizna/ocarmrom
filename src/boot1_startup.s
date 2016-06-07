        .text
        .code 32

        .global _start
        .func _start
_start:
        /* Exception vectors */
        B _exception_reset          /* Reset */
        //B _exception_undefined      /* Undefined */
        //B _exception_svc            /* Supervisor Call */
        //B _exception_prefetch_abort /* Prefetch Abort */
        //B _exception_data_abort     /* Data Abort */
        B .                         /* Hyp trap (not used) */
        //B _exception_irq            /* IRQ */
        //B _exception_fiq            /* FIQ */
        .rep 6
        B .
        .endr

_exception_reset:
        /* Copy `data` into RAM */
        LDR r0,=__data_load
        LDR r1,=__data_start
        LDR r2,=__data_end
1:      CMP r1,r2
        LDRLT r3,[r0],#4
        STRLT r3,[r1],#4
        BLT 1b
        /* Initialize `bss` */
        MOV r0,#0
        LDR r1,=__bss_start
        LDR r2,=__bss_end
1:      CMP r1,r2
        STRLT r0,[r1],#4
        BLT 1b
        /* Initialize stack */
        MSR CPSR_c,#0xDF
        LDR sp,=__nvram_end
        /* Clear A bit, leave E bit set */
        MSR CPSR_x,#0x0200
        /* Basic setup complete, pass control to `rom_main` */
        B rom_main
        .endfunc

        .end
