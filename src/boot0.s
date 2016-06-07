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

        // r11 = number of bytes in memory
        // r10 = file handle for /OC-ARM
        // r9 = address of 36-byte buffer for invokes and small replies
        // r8 = number of program header table entries
        // r7 = current program header table entry
        // r6 = program header table offset
        .func _entry
_entry:
        /**************************************************************/
        /*** Initial setup ********************************************/
        /**************************************************************/
        /* Enter System mode */
        MSR CPSR_c,#0xDF
        /* Initialize stack */
        LDR sp,=0x80000100
        /* Clear A bit, leave E bit set */
        MSR CPSR_x,#0x0200
        /**************************************************************/
        /*** Determine (and sanity-check) installed RAM quantity ******/
        /**************************************************************/
        /* Find how many bytes of RAM we have */
        MOV r0, #1
        MOV r11, #0
1:      MCR p3, 0, r0, cr0, cr0
        MRC p3, 0, r1, cr0, cr0
        ADD r0, #1
        CMP r1, #0
        ADD r11, r1
        BNE 1b
        /* If no RAM installed, bomb */
        CMP r11, #0
        LDCEQ p3, cr15, no_ram_message
        /**************************************************************/
        /*** Find filesystem containing /OC-ARM ***********************/
        /**************************************************************/
        /* Make room for a compact_component... and some invoke buffers */
        SUB sp, #52
        /* Latch the Component List Buffer */
        CDP p3, 5, cr0, cr0, cr0, #0
        /* Find the first bootable-looking filesystem */
        MOV r0, sp
        LDR r1, =cc_is_bootable
        BL foreach_cc
        /* EQ = didn't find one */
        LDCEQ p3, cr15, no_bootable_message
        /* upper half of compact_component is now invoke/reply buffers */
        ADD r9, sp, #16
        /**************************************************************/
        /*** Open /OC-ARM *********************************************/
        /**************************************************************/
        /* set it as the invoke target (redundant) */
        MCR p3, 0, sp, cr1, cr1
        /* fs->open("boot/arm.elf") */
        LDC p3, cr1, boot_elf_open_invoke_buf
        CDP p3, 2, cr0, cr0, cr0, #0
        /* expected result:
        INVOKE_SUCCESS ICTAG_INT <handle> ICTAG_END */
        MRC p3, 0, r0, cr2, cr1
        LDCMI p3, cr15, open_error_message
        CMP r0, #16
        LDCNE p3, cr15, open_error_message
        /* first word is definitely INVOKE_SUCCESS,
           last definitely ICTAG_END */
        STC p3, cr1, [r9]
        /* is the second word ICTAG_VALUE? */
        LDR r0, [r9, #4]
        CMP r0, #-9
        LDCNE p3, cr15, open_error_message
        /* the third word is the file handle */
        LDR r10, [r9, #8]
        /**************************************************************/
        /*** Load /OC-ARM *********************************************/
        /**************************************************************/
        /** Elf32_Ehdr **/
        /* e_ident field, 16 bytes */
        MOV r0, #16
        MOV r1, r9
        BL read
        /* EI_MAG0-3 = <BS>ELF */
        LDR r0, [r9, #0]
        LDR r1, =0x7f454c46
        CMP r0, r1
        LDCNE p3, cr15, invalid_elf
        /* EI_CLASS = ELFCLASS32 (1) /*
        /* EI_DATA = ELFDATA2MSB (2) */
        /* EI_VERSION = 1 */
        /* EI_OSABI = ignored */
        LDR r0, [r9, #4]
        BFC r0, #0, #8
        LDR r1, =0x01020100
        CMP r0, r1
        LDCNE p3, cr15, invalid_elf
        /* EI_ABIVERSION, EI_PAD ... EI_NIDENT ignored */
        /* So far so good... */
        /* Exactly enough room at r9 for the rest of the header */
        MOV r0, #36
        MOV r1, r9
        BL read
        /* e_type = ET_EXEC (2) */
        /* e_machine = EM_ARM (40) */
        LDR r0, [r9, #0]
        LDR r1,=0x00020028
        CMP r0, r1
        LDCNE p3, cr15, invalid_elf
        /* e_version = 1 */
        LDR r0, [r9, #4]
        CMP r0, #1
        LDCNE p3, cr15, invalid_elf
        /* e_entry */
        LDR r3, [r9, #8]
        LDR r1, =entry_point_address
        STR r3, [r1]
        /* e_phoff */
        LDR r6, [r9, #12]
        /* e_shoff ignored */
        /* e_flags must contain:
           EF_ARM_BE8 (0x00800000) */
        LDR r0, [r9, #20]
        LDR r1, =0x00800000
        AND r2, r0, r1
        CMP r2, r1
        LDCNE p3, cr15, invalid_elf
        /* if e_flags DOES NOT contain:
           EF_ARM_HASENTRY (0x00000002)
           then e_entry MUST be non-zero */
        LDR r1, =0x00000002
        AND r2, r0, r1
        CMP r2, r1
        BNE no_ck_entry
        CMP r3, #0 /* r3 still contains e_entry */
        LDCEQ p3, cr15, invalid_elf
no_ck_entry:
        /* e_ehsize must be >= 52 */
        LDRH r0, [r9, #24]
        CMP r0, #52
        LDCLO p3, cr15, invalid_elf
        /* e_phentsize must equal 32 */
        LDRH r0, [r9, #26]
        CMP r0, #32
        LDCNE p3, cr15, invalid_elf
        /* e_phnum must not be 0xFFFF or 0*/
        LDRSH r8, [r9, #28]
        CMP r8, #-1
        CMPNE r8, #0
        LDCEQ p3, cr15, invalid_elf // way too many program header table entries
        UXTH r8, r8
        /* e_shentsize ignored */
        /* e_shnum ignored */
        /* e_shstrndx ignored */
        /** Elf32_Phdr **/
3:      CMP r7, r8
        BGE 3f
        ADD r0, r6, r7, LSL#5
        ADD r7, #1
        BL seek
        MOV r0, #32
        MOV r1, r9
        BL read
        /* if p_type != PT_LOAD (1) then skip */
        LDR r0, [r9, #0]
        CMP r0, #1
        BNE 1b
        PUSH {r6, r7}
        /* p_offset */
        LDR r4, [r9, #4]
        /* p_vaddr, must be 4-byte aligned */
        LDR r5, [r9, #8]
        /* p_filesz, must be 4-byte aligned */
        LDR r6, [r9, #16]
        /* p_memsz, must be 4-byte aligned */
        LDR r7, [r9, #20]
        /* test them all at once */
        TST r5, #3
        TSTEQ r6, #3
        TSTEQ r7, #3
        LDCNE p3, cr15, unaligned_elf
        /* ignore p_paddr, p_flags, p_align */
        /* replace p_memsz with "number of zero bytes at the end"
           and ensure that it was not less than p_filesz */
        SUBS r7, r6
        LDCLO p3, cr15, invalid_elf
        /* p_vaddr + p_memsz may not be > 4GiB or > memory_bytes */
        ADDS r0, r5, r7
        LDCCS p3, cr15, invalid_elf
        CMP r0, r11
        LDCHI p3, cr15, not_enough_ram_message
        /* seek to p_offset */
        MOV r0, r4
        BL seek
        /* read up to 2048 bytes at a time until nothing remains to read */
        CMP r6, #0
        BEQ 2f
1:      CMP r6, #2048
        MOVHS r0, #2048
        MOVLO r0, r6
        MOV r1, r5
        ADD r5, r0
        SUB r6, r0
        BL read
        CMP r6, #0
        BNE 1b
        /* zero what's left */
        /* do it four words at a time if that would save time */
2:      CMP r7, #32
        MOV r0, #0
        BLO 2f
        MOV r1, #0
        MOV r2, #0
        MOV r3, #0
1:      SUB r7, #16
        CMP r7, #16
        STMIA r5!, {r0, r1, r2, r3}
        BHS 1b
        /* do it one word at a time now */
2:      SUBS r7, #4
        STR r0, [r5, #4]!
        BHI 2b
        POP {r6, r7}
        B 3b
3:      /* Dispose of the file handle, and any other Values we (should not
           have) accidentally accumulated */
        CDP p3, 8, cr0, cr0, cr0
        /* Jump to the entry point! */
        LDR r12, =entry_point_address
        LDR r12, [r12]
        BLX r12
        LDC p3, cr15, entry_point_returned
        .endfunc
entry_point_returned:
        .asciz "returned from entry point"
        .balign 4, 0
invalid_elf:
        .asciz "/OC-ARM is not an executable big-endian ARM ELF"
        .balign 4, 0
unaligned_elf:
        .asciz "/OC-ARM contains a segment not 4-byte aligned"
        .balign 4, 0
no_ram_message:
        .asciz "No RAM is installed"
        .balign 4, 0
not_enough_ram_message:
        .asciz "Insufficient RAM to boot"
        .balign 4, 0
no_bootable_message:
        .asciz "No filesystem with /OC-ARM found"
        .balign 4, 0
open_error_message:
        .asciz "Couldn't open /OC-ARM"
        .balign 4, 0
boot_elf_open_invoke_buf:
        .word 4 // ICTAG_STRING(4)
        .ascii "open"
        .balign 4, 0
        .word 6 // ICTAG_STRING(6)
        .ascii "OC-ARM"
        .balign 4, 0
        .word -1 // ICTAG_END

        // r9: invoke buf at least 36 bytes in size
        // r10: file handle
        // r0: seek offset
        // r1-r3: clobber
        .func seek
seek:
        PUSH {r4, lr}
        MOV r4, r0
        /* copy out the invoke buffer skeleton */
        MOV r0, r9
        LDR r1, =seek_invoke_buf_start
        MOV r2, #seek_invoke_buf_end-seek_invoke_buf_start
        BL memcpy_wa
        /* store the file handle */
        STR r10, [r9, #seek_invoke_buf_handle-seek_invoke_buf_start]
        /* store the seek offset */
        STR r4, [r9, #seek_invoke_buf_offset-seek_invoke_buf_start]
        /* invoke */
        LDC p3, cr1, [r9]
        CDP p3, 2, cr0, cr0, cr0, #0
        /* expected result:
        INVOKE_SUCCESS, ICTAG_INT, <our offset value>, ICTAG_END */
        MRC p3, 0, r0, cr2, cr1
        LDCMI p3, cr15, seek_error_message
        CMP r0, #16
        LDCNE p3, cr15, seek_error_message
        /* first word is definitely INVOKE_SUCCESS,
           last definitely ICTAG_END */
        STC p3, cr1, [r9]
        /* is the second word ICTAG_INT? */
        LDR r0, [r9, #4]
        CMP r0, #-5
        LDCNE p3, cr15, seek_error_message
        /* is the third word our offset? */
        LDR r0, [r9, #8]
        CMP r0, r4
        LDCNE p3, cr15, seek_error_message
        /* seek was successful, return */
        POP {r4, pc}
        .endfunc
seek_error_message:
        .asciz "Seek failed on /OC-ARM"
        .balign 4, 0
seek_invoke_buf_start:
        .word 4 // ICTAG_STRING(4)
        .ascii "seek"
        .balign 4, 0
        .word -9 // ICTAG_VALUE
seek_invoke_buf_handle:
        .word 0 // (handle)
        .word 3 // ICTAG_STRING(3)
        .ascii "set"
        .balign 4, 0
        .word -5 // ICTAG_INT
seek_invoke_buf_offset:
        .word 0 // (offset)
        .word -1 // ICTAG_END
seek_invoke_buf_end:

        // r9: invoke buf at least 36 bytes in size
        // r10: file handle
        // r0: read count
        // r1: read target
        // r2-r3: clobber
        .func read
read:   
        PUSH {r4, r5, lr}
        MOV r4, r0
        MOV r5, r1
        /* copy out the invoke buffer skeleton */
        MOV r0, r9
        LDR r1, =read_invoke_buf_start
        MOV r2, #read_invoke_buf_end-read_invoke_buf_start
        BL memcpy_wa
        /* store the file handle */
        STR r10, [r9, #read_invoke_buf_handle-read_invoke_buf_start]
        /* store the read count */
        STR r4, [r9, #read_invoke_buf_count-read_invoke_buf_start]
        /* invoke */
        LDC p3, cr1, [r9]
        CDP p3, 2, cr0, cr0, cr0, #0
        /* expected result:
        INVOKE_SUCCESS, ICTAG_BYTE_ARRAY, <our data>, ICTAG_END */
        MRC p3, 0, r0, cr2, cr5
        LDCCC p3, cr15, read_error_message
        CMP r0, r4
        LDCNE p3, cr15, read_error_message
        /* read was successful, store and return */
        STC p3, cr5, [r5]
        POP {r4, r5, pc}
        .endfunc
read_error_message:
        .asciz "Couldn't read /OC-ARM"
        .balign 4, 0
read_invoke_buf_start:
        .word 4 // ICTAG_STRING(4)
        .ascii "read"
        .balign 4, 0
        .word -9 // ICTAG_HANDLE
read_invoke_buf_handle:
        .word 0 // (handle)
        .word -5 // ICTAG_INT
read_invoke_buf_count:
        .word 0 // (count)
        .word -1 // ICTAG_END
read_invoke_buf_end:

        // copy memory, word-aligned
        // r0: the destination
        // r1: the source
        // r2: the length of the copy, must be at least 4 and a multiple of 4
        // r3: clobbered
        .func memcpy_wa
memcpy_wa:
1:      SUBS r2, #4
        LDR r3, [r1], #4
        STR r3, [r0], #4
        BNE 1b
        BX lr
        .endfunc

        .func cc_is_bootable
cc_is_bootable:
        PUSH {r5, lr}
        MOV r5, r0
        BL cc_is_fs
        /* return early if this compact component is not a filesystem */
        POPNE {r5, pc}
        /* it's a filesystem, let's see if it has the right stuff */
        /* set it as the invoke target */
        MCR p3, 0, r5, cr1, cr1
        /* invoke! */
        PUSH {r4}
        LDC p3, cr1, boot_elf_exists_invoke_buf
        CDP p3, 2, cr0, cr0, cr0, #0
        /* expected result:
        INVOKE_SUCCESS ICTAG_BOOL (whether it exists) ICTAG_END */
        MRC p3, 0, r4, cr2, cr1
        /* if the invocation didn't succeed, skip this one */
        MOVMI r0, #0
        POPMI {r4, r5, pc}
        /* if the invocation did succeed but the result wasn't 16 bytes, skip*/
        CMP r4, #16
        MOVNE r0, #0
        POPNE {r4, r5, pc}
        /* check whether the expected result is what we got */
        STC p3, cr1, [r5, #16]
        ADD r0, r5, #16
        LDR r1, =exists_positive_reply
        BL compare16
        MOVNE r0, #0
        MOVEQ r0, #1
1:      POP {r4, r5, pc}
        .endfunc

boot_elf_exists_invoke_buf:
        .word 6 // ICTAG_STRING(6)
        .ascii "exists"
        .balign 4, 0
        .word 6 // ICTAG_STRING(6)
        .ascii "OC-ARM"
        .balign 4, 0
        .word -1 // ICTAG_END
exists_positive_reply:
        .word 0 // INVOKE_SUCCESS
        .word -3 // ICTAG_BOOLEAN
        .word -1 // true
        .word -1 // ICTAG_END

        .bss
entry_point_address:
        .skip 4

        .end
