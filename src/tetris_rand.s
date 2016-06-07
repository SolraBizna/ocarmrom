        .code 32
        .text

        // Linear congruential generator with parameters:
        // a=1103515245
        // c=12345
        // m=2^32
        // (like used in glibc)
        .global rand
        .func rand
rand:   LDR r1, =random_state
        LDR r0, [r1]
        LDR r2, =1103515245
        LDR r3, =12345
        MLA r0, r0, r2, r3
        STR r0, [r1]
        ASR r0, r0, #16
        BFC r0, #15, #17
        BX lr
        .endfunc

        .bss
        .global random_state
random_state:
        .skip 4
