        .code 32
        .text

        // in: r0 = first thing, r1 = second thing
        // out: Z = 0 if different, 1 if same
        // locals: r2/r3 = comparison scratch register A/B
        // clobbers: r2, r3
        .global compare16
        .func compare16
compare16:
        LDR r2, [r0]
        LDR r3, [r1]
        CMP r2, r3
        BXNE lr
        LDR r2, [r0, #4]
        LDR r3, [r1, #4]
        CMP r2, r3
        BXNE lr
        LDR r2, [r0, #8]
        LDR r3, [r1, #8]
        CMP r2, r3
        BXNE lr
        LDR r2, [r0, #12]
        LDR r3, [r1, #12]
        CMP r2, r3
        BX lr
        .endfunc

        .global foreach_cc
        .func foreach_cc
foreach_cc:
        // save registers
        PUSH {r4, r5, r6, lr}
        // r4 := cc buffer
        MOV r4, r0
        // r5 := callback
        MOV r5, r1
        // r6 := component index
        // component index := #0
        MOV r6, #0
        // CCIR := component index
1:      MCR p3, 0, r6, cr1, cr2
        // [cc buffer] := CC
        STC p3, cr4, [r4]
        // end of list? return 0
        MOVEQ r0, #0
        BEQ 1f
        // invalid component? skip
        ADDVS r6, #1
        BVS 1b
        // call callback
        MOV r0, r4
        BLX r5
        // if it returned zero, loop again; otherwise, return what it returned
        CMP r0, #0
        ADDEQ r6, #1
        BEQ 1b
        // restore registers and return
1:      POP {r4, r5, r6, pc}
        .endfunc

        .global cc_is_fs
        .func cc_is_fs
cc_is_fs:
        // save link register
        PUSH {lr}
        // compare the types
        ADD r0, #16
        LDR r1, =str_filesystem16
        BL compare16
        // return 0 if not equal, 1 if equal
1:      MOVNE r0, #0
        MOVEQ r0, #1
        // return
        POP {pc}
        .endfunc
str_filesystem16:
        .ascii "filesystem\0\0\0\0\0\0"
