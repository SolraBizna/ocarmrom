        .code 32
        .text

        .global key_was_pressed
        .func key_was_pressed
key_was_pressed:        
  /* Expected signal buffer if key_down signal occurs:
     ICTAG_STRING(8) "key_down" ICTAG_UUID (keyboard) ICTAG_INT key ICTAG_END*/
        PUSH {fp, lr}
        MOV fp, sp
        SUB sp, sp, #44
        LDR r1, =expected_signal_for_keydown
1:      MRC p3, 0, r2, cr2, cr0
        BVS 1f
        CMP r2, #44
        CDPNE p3, 6, cr0, cr0, cr0, #0
        BNE 1b
        MOV r0, sp
        BL compare16
        BNE 1b
        MOV r0, #1
        B 2f
1:      MOV r0, #0
2:      MOV sp, fp
        POP {fp, pc}
        .endfunc

        .data
expected_signal_for_keydown:
        .word 8
        .ascii "key_down"
        .word -8
