        .code 32
        .text

        .global tetromino_list, tetromino_list_end, num_tetrominoes
tetromino_list:
        .byte i_tetr_1-tetromino_data_base
        .byte j_tetr_1-tetromino_data_base
        .byte l_tetr_1-tetromino_data_base
        .byte o_tetr_1-tetromino_data_base
        .byte s_tetr_1-tetromino_data_base
        .byte t_tetr_1-tetromino_data_base
        .byte z_tetr_1-tetromino_data_base
tetromino_list_end:
        .set num_tetrominoes, tetromino_list_end - tetromino_list
        .balign 4,0

        // Tetromino data format:
        // Bytes #0-3: tetromino shape encoded as bits
        // (right square is low, center is the second column of the second row)
        // Bytes #4-7: color
        // Byte #8: offset of clockwise-rotated version
        // Byte #9: offset of counter-clockwise-rotated version
        .macro tetr_data this, b1, b2, b3, b4, next, prev
        .global \this\()
\this\():
        .set \this\()_off, \this\()-tetromino_data_base
        .byte \b1, \b2, \b3, \b4
        color
        .byte \next\()-tetromino_data_base
        .byte \prev\()-tetromino_data_base
        .skip 2
        .endm
        .global tetromino_data_base
tetromino_data_base:
        // I tetromino:
        // ####
        // color: BLUE
        .macro color
        .word 0x3366CC
        .endm
        tetr_data i_tetr_1, 0b0000,0b1111,0b0000,0b0000, i_tetr_2,i_tetr_2
        tetr_data i_tetr_2, 0b0100,0b0100,0b0100,0b0100, i_tetr_1,i_tetr_1
        .purgem color
        // J tetromino:
        // ###  # #   ##
        //   #  # ### #
        //     ##     #
        // color: RED
        .macro color
        .word 0xCC4C4C
        .endm
        tetr_data j_tetr_1, 0b0000,0b1110,0b0010,0b0000, j_tetr_2,j_tetr_4
        tetr_data j_tetr_2, 0b0100,0b0100,0b1100,0b0000, j_tetr_3,j_tetr_1
        tetr_data j_tetr_3, 0b1000,0b1110,0b0000,0b0000, j_tetr_4,j_tetr_2
        tetr_data j_tetr_4, 0b0110,0b0100,0b0100,0b0000, j_tetr_1,j_tetr_3
        .purgem color
        // L tetromino:
        // ### ##   # #
        // #    # ### #
        //      #     ##
        // color: ORANGE
        .macro color
        .word 0xF2B233
        .endm
        tetr_data l_tetr_1, 0b0000,0b1110,0b1000,0b0000, l_tetr_2,l_tetr_4
        tetr_data l_tetr_2, 0b1100,0b0100,0b0100,0b0000, l_tetr_3,l_tetr_1
        tetr_data l_tetr_3, 0b0010,0b1110,0b0000,0b0000, l_tetr_4,l_tetr_2
        tetr_data l_tetr_4, 0b0100,0b0100,0b0110,0b0000, l_tetr_1,l_tetr_3
        .purgem color
        // O tetromino:
        // ##
        // ##
        // color: PURPLE
        .macro color
        .word 0xB266E5
        .endm
        tetr_data o_tetr_1, 0b0000,0b0110,0b0110,0b0000, o_tetr_1,o_tetr_1
        .purgem color
        // S tetromino:
        //  ## #
        // ##  ##
        //      #
        // color: PINK
        .macro color
        .word 0xF2B2CC
        .endm
        tetr_data s_tetr_1, 0b0000,0b0110,0b1100,0b0000, s_tetr_2,s_tetr_2
        tetr_data s_tetr_2, 0b0100,0b0110,0b0010,0b0000, s_tetr_1,s_tetr_1
        .purgem color
        // T tetromino:
        // ###  #  #  #
        //  #  ## ### ##
        //      #     #
        // color: GREEN
        .macro color
        .word 0x7FCC19
        .endm
        tetr_data t_tetr_1, 0b0000,0b1110,0b0100,0b0000, t_tetr_2,t_tetr_4
        tetr_data t_tetr_2, 0b0100,0b1100,0b0100,0b0000, t_tetr_3,t_tetr_1
        tetr_data t_tetr_3, 0b0100,0b1110,0b0000,0b0000, t_tetr_4,t_tetr_2
        tetr_data t_tetr_4, 0b0100,0b0110,0b0100,0b0000, t_tetr_1,t_tetr_3
        .purgem color
        // Z tetromino:
        // ##   #
        //  ## ##
        //     #
        // color: WHITE
        .macro color
        .word 0xF0F0F0
        .endm
        tetr_data z_tetr_1, 0b0000,0b1100,0b0110,0b0000, z_tetr_2,z_tetr_2
        tetr_data z_tetr_2, 0b0010,0b0110,0b0100,0b0000, z_tetr_1,z_tetr_1
        .purgem color
tetromino_data_end:

        .if (tetromino_data_end-tetromino_data_base) > 255
        .error "Tetromino database is too big"
        .endif
        .end
