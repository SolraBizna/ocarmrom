        .code 32
        .text

        // void copywords(int* dst, const int* src, size_t wordcount)
        .global copywords
        .func copywords
copywords:
        SUBS r2, #1
        LDRCS r3, [r1], #4
        STRCS r3, [r0], #4
        BCS copywords
        BX lr
        .endfunc

        // void require_true_result(char buf[16], const char* fail_message)
        .global require_true_result
        .func require_true_result
require_true_result:
        // reply must have succeeded, and must be 16 bytes
        MRC p3, 0, r2, cr2, cr1
        LDCMI p3, cr15, [r1]
        CMP r2, #16
        LDCNE p3, cr15, [r1]
        // reply must be INVOKE_SUCCESS, ICTAG_BOOLEAM, nonzero, ICTAG_END
        STC p3, cr1, [r0]
        // INVOKE_SUCCESS is a given because N is clear
        // check ICTAG_BOOLEAN
        LDR r2, [r0, #4]
        CMP r2, #-3
        LDCNE p3, cr15, [r1]
        // ICTAG_END is a given because the buffer was 16 bytes long
        // check nonzero
        LDR r2, [r0, #8]
        CMP r2, #0
        LDCEQ p3, cr15, [r1]
        BX lr
        .endfunc

        // void clear_rect(int x, int y, int w, int h)
        .global clear_rect
        .func clear_rect
clear_rect:
        PUSH {r4, r5, lr}
        MOV r4, #0x20000000
        MOV r5, #1
        BL fill_rect
        POP {r4, r5, pc}
        .endfunc

        // void fill_rect(int x, int y, int w, int h, int str, int strlen)
        // args 5 and 6 are passed in r4 and r5, respectively
        // 0 < strlen <= 4
        .global fill_rect
        .func fill_rect
fill_rect:
        PUSH {r0, r1, r2, r3, r6, lr}
        LDR r0, =invoke_buf
        MOV r6, r0
        LDR r1, =fill_invoke_buf
        MOV r2, #(fill_invoke_buf_end-fill_invoke_buf)/4
        BL copywords
        POP {r0, r1, r2, r3}
        STR r0, [r6, #fill_invoke_buf_x-fill_invoke_buf]
        STR r1, [r6, #fill_invoke_buf_y-fill_invoke_buf]
        STR r2, [r6, #fill_invoke_buf_w-fill_invoke_buf]
        STR r3, [r6, #fill_invoke_buf_h-fill_invoke_buf]
        STR r5, [r6, #fill_invoke_buf_strlen-fill_invoke_buf]
        STR r4, [r6, #fill_invoke_buf_str-fill_invoke_buf]
        // Invoke!
        LDC p3, cr1, [r6]
        CDP p3, 2, cr0, cr0, cr0, #0
        // Let our caller deal with any error
        POP {r6, pc}
        .endfunc
fill_invoke_buf:
        .word 4 // ICTAG_STRING(4)
        .ascii "fill"
        .balign 4,0
        .word -5 // ICTAG_INT
fill_invoke_buf_x:
        .skip 4
        .word -5 // ICTAG_INT
fill_invoke_buf_y:
        .skip 4
        .word -5 // ICTAG_INT
fill_invoke_buf_w:
        .skip 4
        .word -5 // ICTAG_INT
fill_invoke_buf_h:
        .skip 4
fill_invoke_buf_strlen:
        .skip 4
fill_invoke_buf_str:
        .skip 4
        .word -1 // ICTAG_END
fill_invoke_buf_end:

        // void copy_rect(int x, int y, int w, int h, int tx, int ty)
        // args 5 and 6 are passed in r4 and r5, respectively
        .global copy_rect
        .func copy_rect
copy_rect:
        PUSH {r0, r1, r2, r3, r6, lr}
        LDR r0, =invoke_buf
        MOV r6, r0
        LDR r1, =copy_invoke_buf
        MOV r2, #(copy_invoke_buf_end-copy_invoke_buf)/4
        BL copywords
        POP {r0, r1, r2, r3}
        STR r0, [r6, #copy_invoke_buf_x-copy_invoke_buf]
        STR r1, [r6, #copy_invoke_buf_y-copy_invoke_buf]
        STR r2, [r6, #copy_invoke_buf_w-copy_invoke_buf]
        STR r3, [r6, #copy_invoke_buf_h-copy_invoke_buf]
        STR r4, [r6, #copy_invoke_buf_tx-copy_invoke_buf]
        STR r5, [r6, #copy_invoke_buf_ty-copy_invoke_buf]
        // Invoke!
        LDC p3, cr1, [r6]
        CDP p3, 2, cr0, cr0, cr0, #0
        // Let our caller deal with any error
        POP {r6, pc}
        .endfunc
copy_invoke_buf:
        .word 4 // ICTAG_STRING(4)
        .ascii "copy"
        .balign 4,0
        .word -5 // ICTAG_INT
copy_invoke_buf_x:
        .skip 4
        .word -5 // ICTAG_INT
copy_invoke_buf_y:
        .skip 4
        .word -5 // ICTAG_INT
copy_invoke_buf_w:
        .skip 4
        .word -5 // ICTAG_INT
copy_invoke_buf_h:
        .skip 4
        .word -5 // ICTAG_INT
copy_invoke_buf_tx:
        .skip 4
        .word -5 // ICTAG_INT
copy_invoke_buf_ty:
        .skip 4
        .word -1 // ICTAG_END
copy_invoke_buf_end:

        // x,y are the TOP-LEFT SQUARE of the tetromino grid
        // void clear_tetromino(int x, int y, tetromino* tetr)
        .global clear_tetromino
        .func clear_tetromino
clear_tetromino:
        // sub_draw_tetromino with the end of the invoke buf being " "
        PUSH {r4, r5, r6, r7, lr}
        MOV r4, r0
        MOV r5, r1
        MOV r6, r2
        LDR r7, =invoke_buf
        LDR r3, =0x20000000
        STR r3, [r7, #fill_invoke_buf_str-fill_invoke_buf]
        MOV r3, #1
        STR r3, [r7, #fill_invoke_buf_strlen-fill_invoke_buf]
        B sub_draw_tetromino
        .endfunc
        // x,y are the TOP-LEFT SQUARE of the tetromino grid
        // void draw_tetromino(int x, int y, tetromino* tetr)
        .global draw_tetromino
        .func draw_tetromino
draw_tetromino:
        // sub_draw_tetromino with the end of the invoke buf being "▓"
        PUSH {r4, r5, r6, r7, lr}
        MOV r4, r0
        MOV r5, r1
        MOV r6, r2
        // first, set the foreground color to the tetromino color
        LDR r0, [r6, #4]
        BL set_foreground_color
        // now proceed
        LDR r7, =invoke_buf
        LDR r3, =0xe2969300
        STR r3, [r7, #fill_invoke_buf_str-fill_invoke_buf]
        MOV r3, #3
        STR r3, [r7, #fill_invoke_buf_strlen-fill_invoke_buf]
        // B sub_draw_tetromino
        .endfunc
        .func sub_draw_tetromino
sub_draw_tetromino:
        // set up the parts of the invoke buffer that our head didn't set up
        // and that we don't plan to set up later
        MOV r3, #-1
        STR r3, [r7, #fill_invoke_buf_end-fill_invoke_buf-4]
        MOV r3, #1
        STR r3, [r7, #fill_invoke_buf_h-fill_invoke_buf]
        MOV r0, r7
        LDR r1, =fill_invoke_buf
        // do not copy the end
        MOV r2, #(fill_invoke_buf_h-fill_invoke_buf)/4
        BL copywords
        /* registers at this point:
        r4 = x coordinate
        r5 = y coordinate
        r6 = tetromino data
        r7 = invoke_buf
        */
        // r0 := row
        MOV r0, #0
        // loop through each row
        // we could early-out for zero-element rows, but that would introduce
        // some timing inconsistencies
1:      // r1 := the tetromino data for this row
        LDRB r1, [r6, r0]
        // r2 := the number of leading zeroes in the tetromino
        // 28 for one that takes up the whole row, 32 for an empty one
        CLZ r2, r1
        // r3 := x coordinate of left edge of tetromino
        ADD r3, r4, r2, lsl #1
        SUB r3, #56
        STR r3, [r7, #fill_invoke_buf_x-fill_invoke_buf]
        // store y coordinate
        STR r5, [r7, #fill_invoke_buf_y-fill_invoke_buf]
        // r3 := width
        // width starts at the maximum possible (32 - leading zeroes)
        RSB r3, r2, #32
        // subtract one for each zero bit on the right, up to four
        // (destroying the tetromino data as we go)
        // do this the long way so it takes a consistent time to render each
        // tetromino
        MOVS r1, r1, lsr #1
        SUBCC r3, #1
        MOVCCS r1, r1, lsr #1
        SUBCC r3, #1
        MOVCCS r1, r1, lsr #1
        SUBCC r3, #1
        MOVCCS r1, r1, lsr #1
        SUBCC r3, #1
        // width actually needs to be doubled
        MOV r3, r3, lsl #1
        STR r3, [r7, #fill_invoke_buf_w-fill_invoke_buf]
        // invoke buffer is ready, fire away!
        LDC p3, cr1, [r7]
        CDP p3, 2, cr0, cr0, cr0, #1
        // do the above four times, on consecutive tetromino bytes
2:      ADD r0, #1
        CMP r0, #4
        ADD r5, #1
        BLO 1b
        POP {r4, r5, r6, r7, pc}
        .endfunc

        // void draw_cstring(int x, int y, char* str)
        // str must be word-aligned, and must not be too big
        .global draw_cstring
        .func draw_cstring
draw_cstring:
        // determine length of string
        PUSH {r4}
        MOV r3, #0
1:      LDRB r4, [r2, r3]
        CMP r4, #0
        ADDNE r3, #1
        BNE 1b
        POP {r4}
        CMP r3, #0
        BXEQ lr // don't draw an empty string
        // B draw_string // fall through into a tail return
        .endfunc
        
        // void draw_string(int x, int y, char* str, int strlen)
        // str must be word-aligned
        // strlen must not be too big (>12 or so)
        .global draw_string
        .func draw_string
draw_string:    
        PUSH {r0, r1, r2, r3, r4, r5, lr}
        LDR r0, =invoke_buf
        MOV r4, r0
        LDR r1, =draw_string_invoke_buf
        MOV r2, #(draw_string_invoke_buf_end-draw_string_invoke_buf)/4
        BL copywords
        POP {r0, r1, r2, r3}
        STR r0, [r4, #draw_string_invoke_buf_x-draw_string_invoke_buf]
        STR r1, [r4, #draw_string_invoke_buf_y-draw_string_invoke_buf]
        STR r3, [r4, #draw_string_invoke_buf_strlen-draw_string_invoke_buf]
        // MAD! MAAAD!
        ADD r0, r4, #draw_string_invoke_buf_str-draw_string_invoke_buf
        TST r3, #3
        MOV r1, r2
        MOV r2, r3, lsr #2
        ADDNE r2, #1
        ADD r5, r0, r2, lsl #2
        MOV r3, #-1
        STR r3, [r5]
        BL copywords
        // Invoke!
        LDC p3, cr1, [r4]
        CDP p3, 2, cr0, cr0, cr0, #0
        // Let our caller deal with any error
        POP {r4, r5, pc}
        .endfunc
draw_string_invoke_buf:
        .word 3 // ICTAG_STRING(3)
        .ascii "set"
        .balign 4,0
        .word -5 // ICTAG_INT
draw_string_invoke_buf_x:
        .skip 4
        .word -5 // ICTAG_INT
draw_string_invoke_buf_end:
draw_string_invoke_buf_y:
        .set draw_string_invoke_buf_strlen, draw_string_invoke_buf_y+4
        .set draw_string_invoke_buf_str, draw_string_invoke_buf_strlen+4

        .global set_foreground_color
        .func set_foreground_color
set_foreground_color:
        PUSH {r4, lr}
        LDR r4, =invoke_buf
        LDR r1, =set_foreground_color_invoke_buf
        STR r0, [r4, #set_foreground_color_invoke_buf_color-set_foreground_color_invoke_buf]
        MOV r2, #-1
        STR r2, [r4, #set_foreground_color_invoke_buf_color-set_foreground_color_invoke_buf+4]
        MOV r2, #(set_foreground_color_invoke_buf_color-set_foreground_color_invoke_buf)/4
        MOV r0, r4
        BL copywords
        // invoke buffer assembled, invoke it!
        LDC p3, cr1, [r4]
        CDP p3, 2, cr0, cr0, cr0, #1
        // (assume success)
        POP {r4, pc}
        .endfunc
set_foreground_color_invoke_buf:
        .word 13 // ICTAG_STRING(13)
        .ascii "setForeground"
        .balign 4,0
        .word -5 // ICTAG_INT
set_foreground_color_invoke_buf_color:
        // color goes here
        // and end goes after

        .global draw_script
        .func draw_script
draw_script:
        PUSH {r4, lr}
        MOV r4, r0
        /* LDR+UXTB* makes fewer memory accesses occur than four LDRBs */
1:      LDR r0, [r4], #4
        CMP r0, #0
        POPEQ {r4, pc}
        UXTB r1, r0, ROR #16
        UXTB r2, r0, ROR #8
        UXTB r3, r0
        UXTB r0, r0, ROR #24
        ADD r2, r4
        BL draw_string
        B 1b
        .endfunc

        // r4/r5 should already be set such that fill_rect will like them
        .global draw_fillscript
        .func draw_fillscript
draw_fillscript:
        PUSH {r6, lr}
        MOV r6, r0
        /* LDR+UXTB* makes fewer memory accesses occur than four LDRBs */
1:      LDR r0, [r6], #4
        CMP r0, #0
        POPEQ {r6, pc}
        UXTB r1, r0, ROR #16
        UXTB r2, r0, ROR #8
        UXTB r3, r0
        UXTB r0, r0, ROR #24
        BL fill_rect
        B 1b
        .endfunc

        // void draw_decimal(int x, int y, int number)
        // number is capped at 99999999 (8 digits), which is displayed as "?"s
        // draws enough spaces to the right to erase any previous numbers
        .global draw_decimal
        .func draw_decimal
draw_decimal:
        PUSH {r4, r5, r6, r7, lr}
        LDR r4, =99999999
        CMP r2, r4
        BHI 9f
        /* r2 = bcd out
           r3 = binary in
           r4 = constant (bit 2 of every hex digit)
           r5 = loop iterations remaining
           r6 = scratch register 1
           r7 = scratch register 2 */
        LDR r4, =0x22222222
        MOV r5, #27
        LSL r3, r2, #5 // skip the first 5 bits as they will definitely be 0
        MOV r2, #0
1:      /* fixup BCD value */
        AND r6, r4, r2
        AND r7, r4, r2, LSL #1
        ORR r6, r7
        AND r7, r4, r2, LSR #1
        AND r7, r6
        AND r6, r4, r2, LSR #2
        ORR r6, r7
        ORR r6, r6, r6, LSR #1
        ADD r2, r6
        /* uhhh... you'll just have to trust me about the above
           it adds 3 to any BCD digit >= 5 */
        /* now shift the next binary digit out */
        LSLS r3, #1
        LSL r2, #1
        ORRCS r2, #1
        /* repeat 27 times so the whole thing gets shifted out */
        SUBS r5, #1
        BNE 1b
        POP {r4, r5, r6, r7, lr}
        B draw_bcd // tail return
9:      // number was >99999999, display as ????????
        LDR r2, =0xffffffff
        POP {r4, r5, r6, r7, lr}
        // B draw_bcd // tail return
        .endfunc

        // void draw_bcd(int x, int y, int number)
        .global draw_bcd
        .func draw_bcd
draw_bcd:
        PUSH {r4, r5, lr}
        SUB sp, #8
        MOV r3, #8
        /* shift away the zeroes on the left (but only up to 7) */
1:      TST r2, #0xF0000000
        BNE 1f
        SUB r3, #1
        LSL r2, #4
        CMP r3, #1
        BHI 1b
1:      MOV r4, #0
        /* write digits until none are left */
1:      LSR r5, r2, #28
        LSL r2, #4
        ADD r5, #48 // turn it into an ASCII digit
        STRB r5, [sp, r4]
        ADD r4, #1
        CMP r4, r3
        BLO 1b
        /* write spaces until we have eight */
        MOV r5, #32
1:      CMP r3, #8
        STRLOB r5, [sp, r3]
        ADDLO r3, #1
        BLO 1b
        MOV r2, sp
        /* chain into draw_string */
        BL draw_string
        ADD sp, #8
        POP {r4, r5, pc}
        .endfunc
        
        .global flush_signals
        .func flush_signals
flush_signals:  
1:      CDP p3, 6, cr0, cr0, cr0, #0
        BVC 1b
        BX lr
        .endfunc

        /*
        can return one of:
        0 - no key
        1 - new game (enter key)
        2 - rotate_left (1 key)
        3 - rotate_right (2 key)
        4 - hard_drop (up key)
        5 - soft_drop (down key)
        6 - move_left (left key)
        7 - move_right (right key)
        8 - toggle_sound (m key)
        */
        .global get_key
        .func get_key
2:      // pop and skip
        CDP p3, 6, cr0, cr0, cr0, #0
        B 1f
get_key:
        PUSH {r4, lr}
1:
        MRC p3, 0, r0, cr2, cr0
        BVS 1f // no signal -> no key, return 0 (which was just written to r0)
        /* expected signal:
           ICTAG_STRING(8) key_down ICTAG_UUID ICTAG_INT char ICTAG_INT code
           ICTAG_END
           52 bytes */
        CMP r0, #52
        BNE 2b // signal of wrong size, get next one
        LDR r4, =invoke_buf
        STC p3, cr0, [r4]
        MOV r0, r4
        ADR r1, key_down_header
        BL compare16
        BNE 2b // signal does not start with "key_down", (addr)
        /* signal is a key down signal! */
        /* assume the ICTAG_INTs are in place */
        /* r1 := char */
        LDR r1, [r4, #36]
        /* r2 := code */
        LDR r2, [r4, #44]
        /* sorted roughly in order of frequency */
        /* code 203 = left arrow */
        CMP r2, #203
        MOVEQ r0, #6
        BEQ 1f
        /* code 205 = right arrow */
        CMP r2, #205
        MOVEQ r0, #7
        BEQ 1f
        /* char 0x31 = 1 key */
        CMP r1, #0x31
        MOVEQ r0, #2
        BEQ 1f
        /* char 0x32 = 2 key */
        CMP r1, #0x32
        MOVEQ r0, #3
        BEQ 1f
        /* code 200 = up arrow */
        CMP r2, #200
        MOVEQ r0, #3
        BEQ 1f
        /* code 208 = down arrow */
        CMP r2, #208
        MOVEQ r0, #5
        BEQ 1f
        /* char 32 = space */
        CMP r1, #32
        MOVEQ r0, #4
        BEQ 1f
        /* char 10 or 13 = enter key */
        CMP r1, #13
        CMPNE r1, #10
        MOVEQ r0, #1
        BEQ 1f
        /* char 0x4d / 0x6d = m key */
        CMP r1, #0x4d
        CMPNE r1, #0x6d
        MOVEQ r0, #8
        BEQ 1f
        MOV r0, #0
1:      POP {r4, pc}
        .endfunc
key_down_header:
        .word 8 // ICTAG_STRING(8)
        .ascii "key_down"
        .balign 4,0
        .word -8 // ICTAG_UUID

        /* returns anything get_key can except 0 */
        .global wait_key
        .func wait_key
wait_key:
        PUSH {r4, lr}
        LDR r4, =0x7FFFFFFF
1:      MCR p3, 0, r4, cr4, cr0
        BL get_key
        CMP r0, #0
        BEQ 1b
        POP {r4, pc}
        .endfunc
        
        .bss
invoke_buf:
        .skip 60
        
