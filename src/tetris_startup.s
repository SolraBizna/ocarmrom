        .code 32
        .text

        .global _start
        .func _start
_start:
        /* Exception vectors */
        B _entry                                /* Reset */
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
        /* Initialize stack */
        MSR CPSR_c,#0xDF
        LDR sp,=__stack_top
        /* Latch component list */
        CDP p3, 5, cr0, cr0, cr0, #0
        /* Learn the GPU's address */
        SUB sp, #44
        MOV r0, sp
        LDR r1,=cc_is_gpu
        BL foreach_cc
        LDCEQ p3, cr15, no_gpu_message
        /* Copy it to gpu_addr */
        LDM sp, {r0, r1, r2, r3}
        LDR r4, =gpu_addr
        STM r4, {r0, r1, r2, r3}
        /* and write gpu_addr to the ITR */
        MCR p3, 0, r4, cr1, cr1
        /* Madness, aye, but there is method in it... */
        ADD r0, sp, #12
        LDR r1,=cc_is_screen
        BL foreach_cc
        LDCEQ p3, cr15, no_screen_message
        /* ...because now the address of the screen is in the right place to
           incorporate it into a "bind" command for the GPU */
        MOV r0, sp
        LDR r1, =bind_invoke_header
        MOV r2, #3
        BL copywords
        MOV r3, #-1
        STR r3, [sp, #28]
        /* which we will now invoke */
        LDC p3, cr1, [sp]
        CDP p3, 2, cr0, cr0, cr0, #0
        /* require success */
        MOV r0, sp
        LDR r1, =bind_fail
        BL require_true_result
        /* try to set 32x16 resolution */
        LDC p3, cr1, set_resolution_invoke_buf
        CDP p3, 2, cr0, cr0, cr0, #1
        /* (assume success) */
        /* main screen turn on */
        BL draw_main_screen_elements
        /* one last thing... truncate interchange stores */
        /* this way we get `"key_down", keyboard, char, code` instead of
           `"key_down", keyboard, char, code, player` */
        MOV r0, #4
        MCR p3, 0, r0, cr1, cr3
        /* restore stack */
        ADD sp, #44
        /* proceed! */
        B game_loop
        .endfunc
        
set_resolution_invoke_buf:
        .word 13
        .ascii "setResolution"
        .balign 4,0
        .word -5, 32, -5, 16, -1
        
no_gpu_message:
        .asciz "Need GPU"
        .balign 4,0
no_screen_message:
        .asciz "Need screen"
        .balign 4,0
bind_fail:
        .asciz "gpu:bind failed"
        .balign 4,0
bind_invoke_header:
        .word 4 // ICTAG_STRING(4)
        .ascii "bind"
        .balign 4,0
        .word -8 // ICTAG_UUID
        
        .bss
gpu_addr:
        .skip 16
        
