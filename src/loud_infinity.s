        .code 32
        .text

        .global _start
        .func _start
_start:
        /* Exception vectors */
        B _entry                                 /* Reset */
        LDC p3, cr15, _und_message               /* Undefined */
        LDC p3, cr15, _svc_message               /* Supervisor Call */
        LDC p3, cr15, _pfa_message               /* Prefetch Abort */
        LDC p3, cr15, _dfa_message               /* Data Abort */
        B .                                     /* Hyp trap (not used) */
        LDC p3, cr15, _irq_message               /* IRQ */
        LDC p3, cr15, _fiq_message               /* FIQ */
_und_message:
        .asciz "UND"
_svc_message:
        .asciz "SVC"
_pfa_message:
        .asciz "PFA"
_dfa_message:
        .asciz "DFA"
_irq_message:
        .asciz "IRQ"
_fiq_message:
        .asciz "FIQ"
        .endfunc

        .func _entry
_entry:
        LDR r0, =startup_string
outloop:
        LDRB r1, [r0]
        CMP r1, #0
        BEQ done
        MCR p7, 0, r1, cr0, cr0
        ADD r0, #1
        B outloop
done:   CDP p7, 0, cr0, cr0, cr0, #0
forever: B forever
        .endfunc
startup_string:
        .asciz "Loud Infinity is running!"
        
        .end
