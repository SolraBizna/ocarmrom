        .code 32
        .text

        /*
        r0 = UUID
        r1 = output buffer
        r2 = current segment
        r3 = current shift
        r4 = &hexdigits
        r5 = scratch
        r6 = '-'
        */
        .func cpout_int
cpout_int:
1:      LSR r5, r2, r3
        AND r5, r5, #15
        SUBS r3, r3, #4
        LDRB r5, [r4, r5]
        STRB r5, [r1], #1
        BPL 1b
        BX lr
        .endfunc

        .global uuid_to_ascii
        .func uuid_to_ascii
uuid_to_ascii:
        PUSH {r4, r5, r6, lr}
        LDR r4, =hexdigits
        MOV r6, #'-'
        // first 32 bits
        LDR r2, [r0, #0]
        MOV r3, #28
        BL cpout_int
        STRB r6, [r1], #1
        // next 16
        LDRH r2, [r0, #4]
        MOV r3, #12
        BL cpout_int
        STRB r6, [r1], #1
        // next 16
        LDRH r2, [r0, #6]
        MOV r3, #12
        BL cpout_int
        STRB r6, [r1], #1
        // next 16
        LDRH r2, [r0, #8]
        MOV r3, #12
        BL cpout_int
        STRB r6, [r1], #1
        // next 16+32
        LDRH r2, [r0, #10]
        MOV r3, #12
        BL cpout_int
        LDR r2, [r0, #12]
        MOV r3, #28
        BL cpout_int
        POP {r4, r5, r6, pc}
        .endfunc
hexdigits:
        .ascii "0123456789abcdef"
