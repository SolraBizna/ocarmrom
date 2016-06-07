        .text
        .code 32

        .weak _exception_undefined, _exception_svc, _exception_prefetch_abort
        .weak _exception_data_abort, _exception_hyp_trap, _exception_irq
        .weak _exception_fiq

        .global _start, _exception_reset
_start:
        /* Exception vectors */
        B _exception_reset          /* Reset */
_exception_undefined:
        B _exception_undefined      /* Undefined */
_exception_svc:
        B _exception_svc            /* Supervisor Call */
_exception_prefetch_abort:
        B _exception_prefetch_abort /* Prefetch Abort */
_exception_data_abort:
        B _exception_data_abort     /* Data Abort */
_exception_hyp_trap:
        B _exception_hyp_trap       /* Hyp trap (not used) */
_exception_irq:
        B _exception_irq            /* IRQ */
_exception_fiq:
        B _exception_fiq            /* FIQ */

        .func _exception_reset
_exception_reset:
        /* Store memory amount */
        LDR r12,=ram_bytes
        STR r11, [r12]
        /* Initialize stacks */
        MSR CPSR_c,#0xD2
        LDR sp,=__irq_stack_top__
        MSR CPSR_c,#0xD1
        LDR sp,=__fiq_stack_top__
        MSR CPSR_c,#0xD3
        LDR sp,=__supervisor_stack_top__
        MSR CPSR_c,#0xD7
        LDR sp,=__abort_stack_top__
        MSR CPSR_c,#0xDB
        LDR sp,=__undefined_stack_top__
        MSR CPSR_c,#0xDF
        LDR sp,=__c_stack_top__
        /* Clear A bit, leave E bit set */
        MSR CPSR_x,#0x0200
        /* Basic setup complete, pass control to `main` */
        MOV r0, #1
        LDR r1, =argv
        LDR r12,=main
        MOV lr,pc
        BX r12
        /* If we reach this point, main has returned */
1:      LDC p3, cr15, _main_fail_message
_main_fail_message:
        .asciz "main returned"
        .balign 4,0
argv:
        .word argv0
        .word 0
argv0:  .asciz "ROM"
        .endfunc

        .bss
        .global ram_bytes
ram_bytes:
        .skip 4
        .end
