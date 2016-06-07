        .code 32
        .text

        .altmacro
        .macro bounded_text name, text
        \name\():
        .ascii \text
        \name\()_end:
        .balign 4,0
        .endm

        .macro script_message x, y, message
        LOCAL next
        .byte \x, \y, \message-next, \message\()_end-\message
next:   
        .endm

        /* draw all the elements of the screen that will not be overwritten */
        .global draw_main_screen_elements
        .func draw_main_screen_elements
draw_main_screen_elements:
        PUSH {lr}
        /* set white foreground color */
        LDR r0, =0xFFFFFF
        BL set_foreground_color
        /* clear screen */
        MOV r0, #1
        MOV r1, #1
        MOV r2, #32
        MOV r3, #16
        BL clear_rect
        /* draw left and right edges of playing field / next piece window */
        LDR r4, vbar
        MOV r5, #vbar_end-vbar
        ADR r0, playfield_nextpiece_lr_border_script
        BL draw_fillscript
        /* draw top and bottom edges of next piece window */
        LDR r4, hbar
        MOV r5, #hbar_end-hbar
        ADR r0, nextpiece_tb_border_script
        BL draw_fillscript
        /* draw the corners of the "next piece" window */
        ADR r0, next_piece_corner_script
        BL draw_script
        /* set light blue foreground color */
        LDR r0, =0x6598fe
        BL set_foreground_color
        /* draw "NEXT PIECE" */
        MOV r0, #21
        MOV r1, #7
        ADR r2, NEXT
        MOV r3, #NEXT_end-NEXT
        BL draw_string
        /* draw "SCORE" */
        MOV r0, #21
        MOV r1, #9
        ADR r2, SCORE
        MOV r3, #SCORE_end-SCORE
        BL draw_string
        /* draw "LEVEL" */
        MOV r0, #21
        MOV r1, #11
        ADR r2, LEVEL
        MOV r3, #LEVEL_end-LEVEL
        BL draw_string
        /* draw "ROWS" */
        MOV r0, #21
        MOV r1, #13
        ADR r2, ROWS
        MOV r3, #ROWS_end-ROWS
        POP {lr}
        B draw_string
        .endfunc
playfield_nextpiece_lr_border_script:
        .byte 2, 1, 1, 16
        .byte 19, 1, 1, 16
        .byte 21, 2, 1, 4
        .byte 30, 2, 1, 4
        .word 0
nextpiece_tb_border_script:
        .byte 22, 1, 8, 1
        .byte 22, 6, 8, 1
        .word 0
next_piece_corner_script:        
        script_message 21, 1, rbbar
        script_message 30, 1, lbbar
        script_message 21, 6, rtbar
        script_message 30, 6, ltbar
        .word 0
        bounded_text ltbar, "┘"
        bounded_text rtbar, "└"
        bounded_text lbbar, "┐"
        bounded_text rbbar, "┌"
        bounded_text vbar, "│"
        bounded_text hbar, "─"
        bounded_text NEXT, "NEXT PIECE"
        bounded_text SCORE, "SCORE"
        bounded_text LEVEL, "LEVEL"
        bounded_text ROWS, "ROWS"
        
        .global draw_title_screen
        .func draw_title_screen
draw_title_screen:
        PUSH {r4, lr}
        BL clear_playing_field
        BL clear_next_piece
        /* set light blue foreground color */
        LDR r0, =0x6598fe
        BL set_foreground_color
        /* execute script */
        ADR r0, title_script
        BL draw_script
        POP {r4, pc}
        .endfunc
title_script:
        script_message 5, 2, WELCOME_TO
        script_message 5, 3, TETROMINOES
        script_message 5, 5, ENTER
        script_message 5, 6, NEW_GAME
        script_message 5, 8, ARROWS
        script_message 5, 9, MOVE
        script_message 5, 11, ONE_AND_TWO
        script_message 5, 12, ROTATE
        script_message 5, 14, SPACE
        script_message 5, 15, DROP
        .word 0 // end of script
        bounded_text WELCOME_TO, "WELCOME TO"
        bounded_text TETROMINOES, "TETROMINOES!!"
        bounded_text ENTER, "Enter:"
        bounded_text NEW_GAME, "New game"
        bounded_text ARROWS, "Arrows:"
        bounded_text MOVE, "Move"
        bounded_text ONE_AND_TWO, "1 and 2:"
        bounded_text ROTATE, "Rotate"
        bounded_text SPACE, "Space:"
        bounded_text DROP, "Drop"

        .global draw_game_over
        .func draw_game_over
draw_game_over:
        PUSH {lr}
        BL clear_next_piece
        /* set foreground color to ANGRY RED */
        LDR r0,=0xFF0000
        BL set_foreground_color
        /* and draw "GAME OVER" in the window */
        ADR r0, game_over_script
        POP {lr}
        B draw_script // tail return
        .endfunc
game_over_script:
        script_message 24, 3, GAME
        script_message 24, 4, OVER
        .word 0 // end of script
        bounded_text GAME, "GAME"
        bounded_text OVER, "OVER"

        .global clear_playing_field
        .func clear_playing_field
clear_playing_field:
        LDR r0,=3
        LDR r1,=1
        LDR r2,=16
        LDR r3,=16
        B clear_rect // tail return
        .endfunc
        
        .global clear_next_piece
        .func clear_next_piece
clear_next_piece:
        LDR r0,=22
        LDR r1,=2
        LDR r2,=8
        LDR r3,=4
        B clear_rect // tail return
        .endfunc
