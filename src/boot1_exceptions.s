        .text
        .code 32

        .global _exception_undefined, _exception_svc
        .global _exception_prefetch_abort, _exception_data_abort
        .global _exception_irq, _exception_fiq
        /* don't waste ROM space on _exception_hyp_trap */
        
        .func _exception_undefined
_exception_undefined:
        LDC p3, cr15, _undefined_message
_undefined_message:
        .asciz "Undefined instruction in ROM"
        .balign 4
        .endfunc

        .func _exception_svc
_exception_svc:
        LDC p3, cr15, _svc_message
_svc_message:
        .asciz "Supervisor call in ROM"
        .balign 4
        .endfunc

        .func _exception_prefetch_abort
_exception_prefetch_abort:
        LDC p3, cr15, _prefetch_abort_message
_prefetch_abort_message:
        .asciz "Prefetch abort in ROM"
        .balign 4
        .endfunc

        .func _exception_data_abort
_exception_data_abort:
        LDC p3, cr15, _data_abort_message
_data_abort_message:
        .asciz "Data abort in ROM"
        .balign 4
        .endfunc

        .func _exception_irq
_exception_irq:
        LDC p3, cr15, _irq_message
_irq_message:
        .asciz "IRQ in ROM"
        .balign 4
        .endfunc

        .func _exception_fiq
_exception_fiq:
        LDC p3, cr15, _fiq_message
_fiq_message:
        .asciz "FIQ in ROM"
        .balign 4
        .endfunc
