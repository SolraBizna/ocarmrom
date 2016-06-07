        .code 32
        .text

        .global transfer_stack_to_RAM
        .func transfer_stack_to_RAM
transfer_stack_to_RAM:
        LDR sp,=memory_bytes
        LDR sp,[sp]
        SUB sp,#84 // make room for out_line_invoke_buf
        B post_ramstack
        .endfunc
