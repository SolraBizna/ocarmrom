        .code 32
        .text

        /* game state registers:
        r5 = wait target (low)
        r6 = wait target (high)
        r7 = current piece
        r8 = piece X
        r9 = piece Y
        r10 = score
        r11 = playfield address
        */
        r_WAIT_LO .req r5
        r_WAIT_HI .req r6
        r_CUR_PIECE .req r7
        r_PIECE_X .req r8
        r_PIECE_Y .req r9
        r_SCORE .req r10
        r_PLAYFIELD .req r11
        
        .global game_loop
        .func game_loop
game_loop:
        LDR r_PLAYFIELD, =playfield
        /* draw title screen and wait for enter key */
        BL draw_title_screen
        BL flush_signals
1:      BL wait_key
        CMP r0, #1 // wait for enter key
        BNE 1b
        /* initialize the game! */
        BL clear_playing_field
        BL init_game
game_inner_loop:
        /* get inputs from the user */
        BL get_key
        SUBS r0, #2 // all keys we're interested in are >= 2
        LDRHS r1, =key_jump_table
        /* using a PC as a destination of arbitrary operations is deprecated */
        ADDHS r0, r1, r0, LSL #2
        LDRHS pc, [r0]
        /* has a tick passed? */
        MRRC p3, 0, r0, r1, cr0
        CMP r_WAIT_HI, r1
        CMPEQ r_WAIT_LO, r0
        /* if it has, handle a tick */
        BLS time_has_passed
        /* otherwise, draw the piece (if it's dirty) and the score (if it
           changed) and wait */
        LDR r1, =piece_dirty
        LDRB r0, [r1]
        CMP r0, #0
        MOVNE r0, #0
        STRNEB r0, [r1]
        BLNE draw_cur_piece
        LDR r1, =last_score
        LDR r0, [r1]
        CMP r0, r_SCORE
        BLNE draw_score
        MCRR p3, 0, r_WAIT_LO, r_WAIT_HI, cr0
        B game_inner_loop
time_has_passed:
        // time to wait = 16 - level
        // shortest wait is 6, which is a few ticks more than it takes for us
        // to process a step
        LDR r1, =cur_level
        LDR r1, [r1]
        RSB r0, r1, #16
        ADDS r_WAIT_LO, r0
        ADC r_WAIT_HI, #0
        // move the piece down by one tile
        MOV r4, #0 // do not add points for this type of drop
        B drop_one_row
game_over: /* game is over, say so and wait for enter key */
        BL draw_game_over
        BL draw_score
        BL flush_signals
1:      BL wait_key
        CMP r0, #1 // wait for enter key
        BNE 1b
        B game_loop
handle_rotate_left:
        MOV r0, r_PIECE_X
        MOV r1, r_PIECE_Y
        LDRB r2, [r_CUR_PIECE, #9]
        LDR r3, =tetromino_data_base
        ADD r2, r3, r2
        MOV r4, r2
        BL piece_will_intersect
        /* NE = intersection, forget it */
        BNE game_inner_loop
        BL dirty_piece
        MOV r_CUR_PIECE, r4
        B game_inner_loop
handle_rotate_right:
        MOV r0, r_PIECE_X
        MOV r1, r_PIECE_Y
        LDRB r2, [r_CUR_PIECE, #8]
        LDR r3, =tetromino_data_base
        ADD r2, r3, r2
        MOV r4, r2
        BL piece_will_intersect
        /* NE = intersection, forget it */
        BNE game_inner_loop
        BL dirty_piece
        MOV r_CUR_PIECE, r4
        B game_inner_loop
handle_hard_drop:
        MOV r4, #1
1:      MOV r0, r_PIECE_X
        ADD r1, r_PIECE_Y, r4
        MOV r2, r_CUR_PIECE
        BL piece_will_intersect
        /* EQ = no intersection */
        ADDEQ r4, #1
        BEQ 1b
        SUB r4, #1
        ADD r_SCORE, r4
        BL dirty_piece
        ADD r_PIECE_Y, r4
        B 1f // jump into drop_one_row to place the piece
handle_soft_drop:
        MOV r4, #1
drop_one_row:
        // r4 = amount to add to score if we do drop
        MOV r0, r_PIECE_X
        ADD r1, r_PIECE_Y, #1
        MOV r2, r_CUR_PIECE
        BL piece_will_intersect
        /* NE = intersection, place the piece and move on */
        BNE 1f
        /* EQ = no intersection, we may move the piece */
        ADD r_SCORE, r4
        BL dirty_piece
        ADD r_PIECE_Y, #1
        B game_inner_loop
1:      /* draw the piece if it's dirty */
        LDR r4, =piece_dirty
        LDRB r0, [r4]
        CMP r0, #0
        BLNE draw_cur_piece
        BL place_piece
        /* did we just place some piece above the world? */
        LDR r0, [r_PLAYFIELD, #-4]
        CMP r0, #0
        BNE game_over // if so, game over!
        /* otherwise... */
        BL clear_rows // did any rows clear?
        BL choose_piece // choose another piece
        B game_inner_loop
handle_move_left:
        SUB r0, r_PIECE_X, #1
        MOV r1, r_PIECE_Y
        MOV r2, r_CUR_PIECE
        BL piece_will_intersect
        /* NE = intersection, forget it */
        BNE game_inner_loop
        BL dirty_piece
        SUB r_PIECE_X, #1
        B game_inner_loop
handle_move_right:
        ADD r0, r_PIECE_X, #1
        MOV r1, r_PIECE_Y
        MOV r2, r_CUR_PIECE
        BL piece_will_intersect
        /* NE = intersection, forget it */
        BNE game_inner_loop
        BL dirty_piece
        ADD r_PIECE_X, #1
        B game_inner_loop
handle_toggle_sound:
        B game_inner_loop
        .endfunc
key_jump_table:
        .word handle_rotate_left
        .word handle_rotate_right
        .word handle_hard_drop
        .word handle_soft_drop
        .word handle_move_left
        .word handle_move_right
        .word handle_toggle_sound

        .func place_piece
place_piece:
        /*
        r0 = amount by which to shift tetromino
        r1 = playfield pointer
        r2 = tetromino data pointer
        r3 = iterations remaining
        r4 = scratch 1
        r5 = scratch 2
        */
        PUSH {r4, r5, lr}
        RSB r0, r_PIECE_X, #6 // will need to shift again by 2
        MOV r1, r_PLAYFIELD
        ADD r1, r_PIECE_Y
        MOV r2, r_CUR_PIECE
        MOV r3, #4
1:      LDRB r4, [r2], #1 // r4 := unshifted tetromino data
        LSL r4, r0 // r4 := shifted tetromino data
        LDRB r5, [r1] // r5 := existing playfield data
        ORR r5, r4, LSR #2 // r5 := playfield data | tetromino data
        STRB r5, [r1], #1 // store playfield data
        SUBS r3, #1
        BNE 1b // still more loop iterations to go
        /* finished */
        POP {r4, r5, pc}
        .endfunc

        // piece_will_intersect(int x, int y, tetromino*)
        // EQ if no bits in common between playfield and tetromino
        .func piece_will_intersect
piece_will_intersect:
        /*
        r0 = amount by which to shift tetromino
        r1 = playfield pointer
        r2 = tetromino data pointer
        r3 = iterations remaining
        r4 = scratch 1
        r5 = scratch 2
        r6 = all 1 bits except where the playfield data goes
        */
        PUSH {r4, r5, r6, lr}
        RSB r0, r0, #7
        ADD r1, r_PLAYFIELD
        MOV r3, #4
        LDR r6, =0xFFFFF807
1:      LDRB r4, [r2], #1 // r4 := unshifted tetromino data
        LSL r4, r0 // r4 := shifted tetromino data
        LDRB r5, [r1], #1 // r5 := unprocessed playfield data
        ORR r5, r6, r5, LSL #3 // r5 := processed playfield data
        TST r4, r5 // any common bits?
        POPNE {r4, r5, r6, pc} // return immediately if so
        SUBS r3, #1
        BNE 1b // still more loop iterations to go
        /* and EQ will be set correctly here! */
        POP {r4, r5, r6, pc}
        .endfunc

        /* if the piece is not dirty, mark it so and undraw it
           if it is already dirty, nothing needs to be done */
        .func dirty_piece
dirty_piece:    
        PUSH {r4, lr}
        LDR r4, =piece_dirty
        LDRB r0, [r4]
        CMP r0, #0
        POPNE {r4, pc}
        MOV r0, #1
        STRB r0, [r4]
        LSL r0, r_PIECE_X, #1
        ADD r0, #3
        ADD r1, r_PIECE_Y, #1
        MOV r2, r_CUR_PIECE
        POP {r4, lr}
        B clear_tetromino // tail return
        .endfunc

        /* should only be called if necessary; doesn't check dirty flag! */
        .func draw_cur_piece
draw_cur_piece:
        LSL r0, r_PIECE_X, #1
        ADD r0, #3
        ADD r1, r_PIECE_Y, #1
        MOV r2, r_CUR_PIECE
        B draw_tetromino // tail return
        .endfunc

        .func choose_piece
choose_piece:
        PUSH {r4, lr}
        LDR r4, =piece_dirty
        MOV r0, #0
        STRB r0, [r4]
        LDR r4, =next_piece
        LDR r_CUR_PIECE, [r4]
        MOV r_PIECE_X, #2
        MOV r_PIECE_Y, #-4
        BL clear_next_piece
        // random number
        // bits 0-2: tetromino number
        // bits 3-4: rotation count
1:      BL rand
        UBFX r1, r0, #0, #3
        CMP r1, #7
        BHS 1b // chose eighth tetromino but we only have seven; go again
        LDR r2, =tetromino_list
        ADD r2, r2, r1
        LDRB r2, [r2]
        LDR r3, =tetromino_data_base
        ADD r2, r2, r3
        // rotate it right by the random rotation count
        UBFX r1, r0, #3, #2
1:      CMP r1, #0
        SUBHI r1, #1
        LDRHIB r2, [r2, #8]
        ADDHI r2, r2, r3
        BHI 1b
        STR r2, [r4]
        MOV r0, #22
        MOV r1, #2
        BL draw_tetromino
        POP {r4, pc}
        .endfunc
        
        .func init_game
init_game:
        PUSH {lr}
        /* "below" the playfield is filled */
        MOV r0, #-1
        STR r0, [r_PLAYFIELD, #16]
        /* rest of playfield is clear */
        SUB r0, r_PLAYFIELD, #4
        MOV r1, #5
        MOV r2, #0
1:      STR r2, [r0], #4
        SUBS r1, #1
        BNE 1b
        /* score is 0 points */
        MOV r_SCORE, #0
        BL draw_score
        /* start at level 1 */
        MOV r0, #1
        LDR r1, =cur_level
        STR r0, [r1]
        BL draw_level
        /* zero rows cleared */
        MOV r0, #0
        LDR r1, =rows_cleared
        STRH r0, [r1]
        /* ten rows till next level */
        /* rows_till_next == rows_cleared + 2 */
        MOV r0, #10
        STRH r0, [r1, #2]
        BL draw_rows
        /* we want to tick immediately */
        MRRC p3, 0, r_WAIT_LO, r_WAIT_HI, cr0
        /* and let's seed the RNG with the low bits of the time */
        LDR r1, =random_state
        STR r_WAIT_LO, [r1]
        /* force a piece to be selected */
        BL choose_piece
        BL choose_piece
        POP {pc}
        .endfunc

        .func draw_score
draw_score:
        PUSH {lr}
        LDR r0, =0xffffff
        BL set_foreground_color
        MOV r0, #21
        MOV r1, #10
        MOV r2, r_SCORE
        LDR r3, =last_score
        STR r2, [r3]
        POP {lr}
        B draw_decimal // tail return
        .endfunc
        
        .func draw_level
draw_level:
        PUSH {lr}
        LDR r0, =0xffffff
        BL set_foreground_color
        MOV r0, #21
        MOV r1, #12
        LDR r3, =cur_level
        LDR r2, [r3]
        POP {lr}
        B draw_decimal // tail return
        .endfunc

        .func draw_rows
draw_rows:
        PUSH {lr}
        LDR r0, =0xffffff
        BL set_foreground_color
        MOV r0, #21
        MOV r1, #14
        LDR r3, =rows_cleared
        LDRH r2, [r3]
        POP {lr}
        B draw_decimal // tail return
        .endfunc

        .func clear_rows
clear_rows:
        /* registers:
        r0 = number of cleared rows
        r1 = loop index
        */
        PUSH {lr}
        MOV r0, #0
        MOV r1, #0
1:      LDRB r2, [r_PLAYFIELD, r1]
        CMP r2, #0xFF
        ADDEQ r0, #1
        BLEQ clear_rows_display_cleared_row
        ADD r1, #1
        CMP r1, #16
        BLO 1b
        /* were any rows cleared? */
        CMP r0, #0
        BEQ 9f
        LDR r1, =row_clear_points
        SUB r2, r0, #1
        LSL r2, #1
        LDRH r2, [r1, r2]
        ADD r_SCORE, r_SCORE, r2
        LDR r1, =rows_cleared
        LDRH r2, [r1]
        ADD r2, r0
        STRH r2, [r1]
        LDRH r3, [r1, #2]
        CMP r2, r3 /* pass into the next level? */
        BLO 2f
        PUSH {r4, r5}
        LDR r4, =cur_level
        LDR r5, [r4]
1:      ADD r3, #10
        ADD r5, #1
        CMP r2, r3
        BHS 1b
        STR r5, [r4]
        POP {r4, r5}
        STRH r3, [r1, #2]
        BL draw_level
2:      BL draw_rows
        /* go through again, copying the field down */
        /* this code assumes there are at least four blank rows "above" the
           playfield, and that only four rows can be cleared at a time */
        /* registers:
        r0 = loop index out
        r1 = loop index in
        */
        MOV r0, #15
        MOV r1, #15
1:      LDRB r2, [r_PLAYFIELD, r1]
        CMP r2, #0xff
        SUBEQ r1, #1
        BEQ clear_rows_copy_over_cleared_row
        CMP r0, #0
        STRB r2, [r_PLAYFIELD, r0]
        SUBHI r0, #1
        SUBHI r1, #1
        BHI 1b
        /* r0 - r1 = number of rows now clear at the top >= 1 */
        SUB r3, r0, r1
        MOV r0, #3
        MOV r1, #1
        MOV r2, #16
        BL clear_rect
9:      POP {pc}
clear_rows_copy_over_cleared_row:
        PUSH {r0, r1, r4, r5}
        MOV r4, #0
        MOV r5, #1
        MOV r3, r0
        MOV r0, #3
        MOV r2, #16
        MOV r1, #1
        BL copy_rect
        POP {r0, r1, r4, r5}
        B 1b
clear_rows_display_cleared_row:
        PUSH {r0, r1, r4, r5, lr}
        LDR r0, =0xFFFF00 // yellow!
        BL set_foreground_color
        LDR r1, [sp, #4]
        MOV r0, #3
        ADD r1, #1
        MOV r2, #16
        MOV r3, #1
        LDR r4, =0xe2968800 // '█'
        MOV r5, #3
        BL fill_rect
        POP {r0, r1, r4, r5, pc}
        .endfunc
row_clear_points:
        .short 100, 300, 700, 1500
        
        .bss
        .skip 4 // pre-playfield
playfield:
        .skip 20
last_score:
        .skip 4
next_piece:
        .skip 4
cur_level:
        .skip 4
rows_cleared:
        .skip 2
rows_till_next:
        .skip 2
piece_dirty:
        .skip 1
        .balign 4,0
