	.INCLUDE "asm/macro.inc"
	.INCLUDE "asm/gba_constants.inc"

	.SECTION .text
	.ARM

	.macro ldrbeq args:vararg
	ldreqb \args
	.endm

	.macro andseq args:vararg
	andeqs \args
	.endm

	.macro strheq args:vararg
	streqh \args
	.endm

	.macro strhne args:vararg
	strneh \args
	.endm

	ARM_FUNC_START _reset
_reset: @ 0x00000000
	b reset_vector

	ARM_FUNC_START _reserved
_reserved: @ 0x00000004
	b reserved_vector

	ARM_FUNC_START _swi
_swi: @ 0x00000008
	b swi_vector

	ARM_FUNC_START _abort_pftch
_abort_pftch: @ 0x0000000C
	b reserved_vector

	ARM_FUNC_START _abort_data
_abort_data: @ 0x00000010
	b reserved_vector

	ARM_FUNC_START _reserved_2
_reserved_2: @ 0x00000014
	b reserved_vector

	ARM_FUNC_START _irq
_irq: @ 0x00000018
	b irq_vector

reserved_vector:
	ldr sp, _000001C4 @=IWRAM_END - 0x10
	push {ip, lr}
	mrs ip, spsr
	mrs lr, apsr
	push {ip, lr}
	mov ip, #0x8000000
	ldrb lr, [ip, #0x9c]
	cmp lr, #0xa5
	bne _00000054
	ldrbeq lr, [ip, #0xb4]
	andseq lr, lr, #0x80
	add lr, pc, #4
	ldrne pc, _00000274 @=0x09FE2000
	ldreq pc, _00000278 @=0x09FFC000
_00000054:
	ldr sp, _000001C0 @=IWRAM_END - 0x20
	pop {ip, lr}
	msr spsr_fc, ip
	pop {ip, lr}
	subs pc, lr, #4

	ARM_FUNC_START reset_vector
reset_vector:
	cmp lr, #0
	moveq lr, #4
	mov ip, #REG_BASE
	ldrb ip, [ip, #0x300]
	teq ip, #1
	mrseq ip, apsr
	orreq ip, ip, #0xc0
	msreq cpsr_fc, ip
	beq reserved_vector

	ARM_FUNC_START swi_HardReset
swi_HardReset: @ 0x0000008C
	mov r0, #0xdf
	msr cpsr_fc, r0
	mov r4, #REG_BASE
	strb r4, [r4, #REG_OFFSET_IME]
	bl sub_000000E0
	add r0, pc, #0x258  @ sub_00000300?
	str r0, [sp, #0xfc]
	ldr r0, _0000027C @=sub_00001928
	add lr, pc, #0
	bx r0

	ARM_FUNC_START swi_SoftReset
swi_SoftReset: @ 0x000000B4
	mov r4, #REG_BASE
	ldrb r2, [r4, #-6]
	bl sub_000000E0

	ARM_FUNC_START swi_SoftRest_continue
swi_SoftRest_continue: @ 0x000000C0
	cmp r2, #0
	ldmdb r4, {r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}
	movne lr, #0x2000000
	moveq lr, #0x8000000
	mov r0, #0x1f
	msr cpsr_fc, r0
	mov r0, #0
	bx lr

	ARM_FUNC_START sub_000000E0
sub_000000E0:
	mov r0, #0xd3
	msr cpsr_fc, r0
	ldr sp, _000001C0 @=IWRAM_END - 0x20
	mov lr, #0
	msr spsr_fc, lr
	mov r0, #0xd2
	msr cpsr_fc, r0
	ldr sp, _000001BC @=IWRAM_END - 0x60
	mov lr, #0
	msr spsr_fc, lr
	mov r0, #0x5f
	msr cpsr_fc, r0
	ldr sp, _000001B8 @=IWRAM_END - 0x100
	add r0, pc, #1
	bx r0

	THUMB_FUNC_START _0000011C
_0000011C: @ 0x0000011C
	movs r0, #0
	ldr r1, _00000280 @=0xFFFFFE00
_00000120:
	str r0, [r4, r1]
	@ FIXME: Why is it assembling the wrong opcode?
	@ This occurs throughout
	.2byte 0x1D09 @ adds r1, r1, #4
	blt _00000120
	bx lr

	ARM_FUNC_START irq_vector
irq_vector:
	push {r0, r1, r2, r3, ip, lr}
	mov r0, #REG_BASE
	add lr, pc, #0
	ldr pc, [r0, #-4]
	pop {r0, r1, r2, r3, ip, lr}
	subs pc, lr, #4

	ARM_FUNC_START swi_vector
swi_vector:
	push {fp, ip, lr}
	ldrb ip, [lr, #-2]
	add fp, pc, #0x78
	ldr ip, [fp, ip, lsl #2]
	mrs fp, spsr
	stmdb sp!, {fp}
	and fp, fp, #0x80
	orr fp, fp, #0x1f
	msr cpsr_fc, fp
	push {r2, lr}
	add lr, pc, #0
	bx ip

	ARM_FUNC_START swi_complete
swi_complete: @ 0x00000170
	pop {r2, lr}
	mov ip, #0xd3
	msr cpsr_fc, ip
	ldm sp!, {fp}
	msr spsr_fc, fp
	pop {fp, ip, lr}
	movs pc, lr

	ARM_FUNC_START Dispcnt_Something_And_Custom_Halt
Dispcnt_Something_And_Custom_Halt:
	mov ip, #REG_DISPCNT
	mov r2, #4
	strb r2, [ip, #1]
	mov r2, #8
	strb r2, [ip]
swi_Halt:
	mov r2, #0
	b swi_CustomHalt

	ARM_FUNC_START swi_Stop
swi_Stop: @ 0x000001A8
	mov r2, #0x80
swi_CustomHalt:
	mov ip, #REG_BASE
	strb r2, [ip, #0x301]
	bx lr
	.align 2, 0
_000001B8: .4byte IWRAM_END - 0x100
_000001BC: .4byte IWRAM_END - 0x60
_000001C0: .4byte IWRAM_END - 0x20
_000001C4: .4byte IWRAM_END - 0x10

swi_branch_table:
	.4byte swi_SoftReset
	.4byte swi_RegisterRamReset
	.4byte swi_Halt
	.4byte swi_Stop
	.4byte swi_IntrWait
	.4byte swi_VBlankIntrWait
	.4byte swi_Div
	.4byte swi_DivArm
	.4byte swi_Sqrt
	.4byte swi_ArcTan
	.4byte swi_ArcTan2
	.4byte swi_CPUSet
	.4byte swi_CPUFastSet
	.4byte swi_BiosChecksum
	.4byte swi_BgAffineSet
	.4byte swi_ObjAffineSet
	.4byte swi_BitUnPack
	.4byte swi_LZ77UnCompWRAM
	.4byte swi_LZ77UnCompVRAM
	.4byte swi_HuffUnComp
	.4byte swi_RLUnCompWRAM
	.4byte swi_RLUnCompVRAM
	.4byte swi_Diff8bitUnFilterWRAM
	.4byte swi_Diff8bitUnFilterVRAM
	.4byte swi_Diff16bitUnFilter
	.4byte swi_SoundBiasChange
	.4byte swi_SoundDriverInit
	.4byte swi_SoundDriverMode
	.4byte swi_SoundDriverMain
	.4byte swi_SoundDriverVSync
	.4byte swi_SoundChannelClear
	.4byte swi_MIDIKey2Freq
	.4byte swi_MusicPlayerOpen
	.4byte swi_MusicPlayerStart
	.4byte swi_MusicPlayerStop
	.4byte swi_MusicPlayerContinue
	.4byte swi_MusicPlayerFadeOut
	.4byte swi_MultiBoot
	.4byte swi_HardReset
	.4byte swi_CustomHalt
	.4byte swi_SoundDriverVSyncOff
	.4byte swi_SoundDriverVSyncOn
	.4byte swi_GetJumpList

_00000274: .4byte 0x09FE2000
_00000278: .4byte 0x09FFC000
_0000027C: .4byte sub_00001928
_00000280: .4byte 0xFFFFFE00

	THUMB_FUNC_START sub_00000284
sub_00000284: @ 0x00000284
	movs r4, #REG_BASE >> 24
	lsls r4, r4, #0x18
	movs r5, #PLTT >> 24
	lsls r5, r5, #0x18
	movs r6, #VRAM >> 24
	lsls r6, r6, #0x18
	movs r1, #0
	movs r0, #0xc2
	adds r2, r4, #0
	adds r2, #REG_OFFSET_SOUNDCNT
	strb r0, [r2, #2]
	strb r0, [r2, #9]
	movs r0, #0xff
	.2byte 0x1C80 @ adds r0, r0, #2
	movs r2, #0xa0
	movs r3, #0x90
	str r6, [sp]
	movs r7, #0xf0
	str r7, [sp, #4]
	bl sub_0000079E
	movs r0, #0x83
	lsls r0, r0, #7
	strh r0, [r4, #REG_OFFSET_BG2CNT]
	ldr r0, _000002F4 @=0xFFFFD800
	str r0, [r4, #REG_OFFSET_BG2X_L]
	asrs r0, r0, #0x10
	lsls r0, r0, #0xb
	str r0, [r4, #REG_OFFSET_BG2Y_L]
	ldr r3, _000002F8 @=0x7FFF7BDE
	str r3, [r5]
	ldrh r3, [r5]
	ldr r7, _000002FC @=0x00000C63
_000002C6:
	lsrs r2, r4, #0x11
	adds r2, r2, r4
	strh r7, [r2, #2]
	bl swi_Halt_t
	movs r0, #4
	strb r0, [r4, #1]
	strb r0, [r4]
	subs r3, r3, r7
	strh r3, [r5]
	bgt _000002C6
	mvns r0, r1
	str r0, [sp, #8]
	adds r4, #0xd4
	add r1, sp, #8
	str r1, [r4]
	str r6, [r4, #4]
	ldr r1, _000002F0 @=0x85006000
	str r1, [r4, #8]
	bl Dispcnt_Something_And_Custom_Halt_t
	.align 2, 0
_000002F0: .4byte 0x85006000
_000002F4: .4byte 0xFFFFD800
_000002F8: .4byte 0x7FFF7BDE
_000002FC: .4byte 0x00000C63

	ARM_FUNC_START sub_00000300
sub_00000300: @ 0x00000300
	mov r3, #REG_BASE
	ldr r2, [r3, #0x200]
	and r2, r2, r2, lsr #16
	ands r1, r2, #0x80
	ldrne r0, _00000AB8
	andeq r1, r2, #1
	ldreq r0, _00000ABC
	strheq r2, [r3, #-8]
	strb r1, [r3, #0x202]
	bx r0

	ARM_FUNC_START swi_VBlankIntrWait
swi_VBlankIntrWait:
	mov r0, #1
	mov r1, #1

	ARM_FUNC_START swi_IntrWait
swi_IntrWait: @ 0x00000330
	push {r4, lr}
	mov r3, #0
	mov r4, #1
	cmp r0, #0
	blne sub_00000358
_00000344:
	strb r3, [ip, #0x301]
	bl sub_00000358
	beq _00000344
	pop {r4, lr}
	bx lr

	ARM_FUNC_START sub_00000358
sub_00000358: @ 0x00000358
	mov ip, #REG_BASE
	strb r3, [ip, #0x208]
	ldrh r2, [ip, #-8]
	ands r0, r1, r2
	eorne r2, r2, r0
	strhne r2, [ip, #-8]
	strb r4, [ip, #0x208]
	bx lr

	ARM_FUNC_START swi_BiosChecksum
swi_BiosChecksum: @ 0x00000378
	mov r0, #0
	mov r3, #0
_00000380:
	mov ip, #0xdf
	ldm r3!, {r2}
	msr cpsr_fc, ip
	add r0, r0, r2
	lsrs r1, r3, #0xe
	beq _00000380
	bx lr

	THUMB_FUNC_START sub_0000039C
sub_0000039C: @ 0x0000039C
	cmp r0, #0
	bgt _000003A2
	negs r0, r0
_000003A2:
	bx lr

	THUMB_FUNC_START sub_000003A4
sub_000003A4: @ 0x000003A4
	add r3, pc, #0xC
	bx r3

	ARM_FUNC_START swi_DivArm
swi_DivArm:
	mov r3, r0
	mov r0, r1
	mov r1, r3

	ARM_FUNC_START swi_Div
swi_Div: @ 0x000003B4
	ands r3, r1, #0x80000000
	rsbmi r1, r1, #0
	eors ip, r3, r0, asr #32
	rsbhs r0, r0, #0
	movs r2, r1
_000003C8:
	cmp r2, r0, lsr #1
	lslls r2, r2, #1
	bcc _000003C8
_000003D4:
	cmp r0, r2
	adc r3, r3, r3
	subhs r0, r0, r2
	teq r2, r1
	lsrne r2, r2, #1
	bne _000003D4
	mov r1, r0
	mov r0, r3
	lsls ip, ip, #1
	rsbhs r0, r0, #0
	rsbmi r1, r1, #0
	bx lr

	ARM_FUNC_START swi_Sqrt
swi_Sqrt: @ 0x00000404
	stmdb sp!, {r4}
	mov ip, r0
	mov r1, #1
_00000410:
	cmp r0, r1
	lsrhi r0, r0, #1
	lslhi r1, r1, #1
	bhi _00000410
_00000420:
	mov r0, ip
	mov r4, r1
	mov r3, #0
	mov r2, r1
_00000430:
	cmp r2, r0, lsr #1
	lslls r2, r2, #1
	bcc _00000430
_0000043C:
	cmp r0, r2
	adc r3, r3, r3
	subhs r0, r0, r2
	teq r2, r1
	lsrne r2, r2, #1
	bne _0000043C
	add r1, r1, r3
	lsrs r1, r1, #1
	cmp r1, r4
	bcc _00000420
	mov r0, r4
	ldm sp!, {r4}
	bx lr

	THUMB_FUNC_START sub_00000470
sub_00000470: @ 0x00000470
	add r3, pc, #0x0
	bx r3

	ARM_FUNC_START swi_ArcTan
swi_ArcTan: @ 0x00000474
	mul r1, r0, r0
	asr r1, r1, #0xe
	rsb r1, r1, #0
	mov r3, #0xa9
	mul r3, r1, r3
	asr r3, r3, #0xe
	add r3, r3, #0x390
	mul r3, r1, r3
	asr r3, r3, #0xe
	add r3, r3, #0x900
	add r3, r3, #0x1c
	mul r3, r1, r3
	asr r3, r3, #0xe
	add r3, r3, #0xf00
	add r3, r3, #0xb6
	mul r3, r1, r3
	asr r3, r3, #0xe
	add r3, r3, #0x1600
	add r3, r3, #0xaa
	mul r3, r1, r3
	asr r3, r3, #0xe
	add r3, r3, #0x2000
	add r3, r3, #0x81
	mul r3, r1, r3
	asr r3, r3, #0xe
	add r3, r3, #0x3600
	add r3, r3, #0x51
	mul r3, r1, r3
	asr r3, r3, #0xe
	add r3, r3, #0xa200
	add r3, r3, #0xf9
	mul r0, r3, r0
	asr r0, r0, #0x10
	bx lr

	UNALIGNED_THUMB_FUNC_START swi_ArcTan2
swi_ArcTan2: @ 0x000004FC
	push {r4, r5, r6, r7, lr}
	cmp r1, #0
	bne _00000510
	cmp r0, #0
	blt _0000050A
	movs r0, #0
	b _0000059E
_0000050A:
	movs r0, #0x80
	lsls r0, r0, #8
	b _0000059E
_00000510:
	cmp r0, #0
	bne _00000524
	cmp r1, #0
	blt _0000051E
	movs r0, #0x40
	lsls r0, r0, #8
	b _0000059E
_0000051E:
	movs r0, #0xc0
	lsls r0, r0, #8
	b _0000059E
_00000524:
	adds r2, r0, #0
	lsls r2, r2, #0xe
	adds r3, r1, #0
	lsls r3, r3, #0xe
	negs r4, r0
	negs r5, r1
	movs r6, #0x40
	lsls r6, r6, #8
	lsls r7, r6, #1
	cmp r1, #0
	blt _00000572
	cmp r0, #0
	blt _0000055E
	cmp r0, r1
	blt _00000550
	adds r1, r0, #0
	adds r0, r3, #0
	bl sub_000003A4
	bl sub_00000470
	b _0000059E
_00000550:
	adds r0, r2, #0
	bl sub_000003A4
	bl sub_00000470
	subs r0, r6, r0
	b _0000059E
_0000055E:
	cmp r4, r1
	blt _00000550
_00000562:
	adds r1, r0, #0
	adds r0, r3, #0
	bl sub_000003A4
	bl sub_00000470
	adds r0, r7, r0
	b _0000059E
_00000572:
	cmp r0, #0
	bgt _0000058A
	cmp r4, r5
	bgt _00000562
_0000057A:
	adds r0, r2, #0
	bl sub_000003A4
	bl sub_00000470
	adds r6, r6, r7
	subs r0, r6, r0
	b _0000059E
_0000058A:
	cmp r0, r5
	blt _0000057A
	adds r1, r0, #0
	adds r0, r3, #0
	bl sub_000003A4
	bl sub_00000470
	adds r7, r7, r7
	adds r0, r7, r0
_0000059E:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	THUMB_FUNC_START sub_000005A4
sub_000005A4: @ 0x000005A4
	push {r3, r4, r5, r6, lr}
	movs r6, #8
	lsls r6, r6, #0x18
	movs r5, #0x9e
	adds r5, r5, r6
	subs r0, r5, #1
	movs r1, #0x1b
	bl sub_000006AC
	movs r4, #0xc
	muls r4, r0, r4
	ldrb r3, [r5]
	lsls r3, r3, #0x1e
	lsrs r3, r3, #0x1e
	movs r2, #0x30
	muls r2, r3, r2
	adds r4, r4, r2
	add r5, pc, #0x24
	adds r5, r5, r4
	movs r4, #0
_000005CC:
	adds r0, r4, #0
	bl sub_000006CE
	cmp r4, #3
	blt _000005E4
	cmp r4, #9
	bge _000005E4
	ldrh r1, [r5]
	lsls r1, r1, #1
	orrs r1, r6
	ldrh r0, [r1]
	.2byte 0x1CAD @ adds r5, r5, #2
_000005E4:
	.2byte 0x1C64 @ adds r4, r4, #1
	cmp r4, #0xb
	bne _000005CC
	pop {r3, r4, r5, r6, pc}

	.global gUnknown_05EC
gUnknown_05EC:
	.byte 0x9B, 0x47, 0x26, 0x74, 0xBC, 0x11, 0x4F, 0x6D, 0xBD, 0x11, 0xF1, 0x32, 0xD9, 0x7F, 0xE7, 0x2C
	.byte 0xA5, 0x5D, 0xBD, 0x11, 0x10, 0x46, 0xA4, 0x5D, 0x90, 0x4E, 0x73, 0x61, 0x84, 0x2A, 0x91, 0x4E
	.byte 0x6A, 0x10, 0xFE, 0x75, 0xC8, 0x29, 0x39, 0x78, 0x0E, 0x42, 0x1B, 0x5D, 0x38, 0x78, 0xA8, 0x12
	.byte 0x7D, 0x3F, 0xB9, 0x67, 0xF3, 0x26, 0xEF, 0x54, 0x23, 0x7C, 0xF2, 0x26, 0xC6, 0x6B, 0x37, 0x41
	.byte 0xAB, 0x15, 0x0D, 0x73, 0xC7, 0x6B, 0x4F, 0x3B, 0x24, 0x5F, 0xDA, 0x3D, 0x3F, 0x25, 0x49, 0x17
	.byte 0xDB, 0x3D, 0xE6, 0x70, 0x6C, 0x74, 0xF7, 0x30, 0x1F, 0x53, 0x38, 0x67, 0x1E, 0x53, 0x51, 0x1A
	.byte 0x71, 0x19, 0x7D, 0x5B, 0xD6, 0x4E, 0x70, 0x19, 0x27, 0x3F, 0xCB, 0x75, 0x62, 0x3D, 0x8C, 0x12
	.byte 0xB8, 0x74, 0xAD, 0x2F, 0xB9, 0x74, 0xFD, 0x64, 0x9A, 0x6C, 0x3A, 0x4F, 0x6D, 0x27, 0xEF, 0x73
	.byte 0xB1, 0x38, 0x3B, 0x4F, 0x1E, 0x57, 0xA3, 0x7E, 0x49, 0x62, 0x87, 0x35, 0x7C, 0x1B, 0x86, 0x35
	.byte 0xFB, 0x7A, 0xE4, 0x67, 0x92, 0x5C, 0xE5, 0x67, 0xCA, 0x2B, 0x8C, 0x43, 0x6F, 0x2E, 0x7F, 0x58
	.byte 0xB7, 0x14, 0x6E, 0x2E, 0xB9, 0x4C, 0xA2, 0x6F, 0xF0, 0x38, 0x9E, 0x71, 0x5A, 0x47, 0x3C, 0x1F
	.byte 0xD8, 0x6A, 0x5B, 0x47, 0x99, 0x51, 0x64, 0x32, 0x41, 0x7B, 0xEF, 0x49, 0x98, 0x51, 0xD7, 0x1C

	THUMB_FUNC_START sub_000006AC
sub_000006AC: @ 0x000006AC
	push {r4, r5, lr}
	movs r4, #3
	movs r3, #0
_000006B2:
	ldrb r2, [r0]
	rors r3, r4
	movs r5, #4
_000006B8:
	eors r3, r2
	lsls r2, r2, #8
	.2byte 0x1E6D @ subs r5, r5, #1
	bgt _000006B8
	.2byte 0x1C40 @ adds r0, r0, #1
	.2byte 0x1E49 @ subs r1, r1, #1
	bgt _000006B2
	adds r0, r3, #0
	lsls r0, r0, #0x1b
	lsrs r0, r0, #0x1e
	pop {r4, r5, pc}

	UNALIGNED_THUMB_FUNC_START sub_000006CE
sub_000006CE: @ 0x000006CE
	push {r4, lr}
	movs r4, #0x14
	muls r4, r0, r4
	movs r3, #8
	lsls r3, r3, #0x18
	adds r0, r3, #4
	adds r0, r0, r4
	ldr r1, _00000AC0 @=gUnknown_03000088
	adds r1, r1, r4
	movs r2, #0xa
	bl swi_CPUSet
	pop {r4, pc}

	THUMB_FUNC_START sub_000006E8
sub_000006E8: @ 0x000006E8
	push {r4, r5, r6, lr}
	ldr r1, _00000AC4 @=gUnknown_3290
	movs r6, #0
_000006EE:
	movs r4, #0xff
	cmp r6, #0x98
	bne _000006F6
	movs r4, #0x7b
_000006F6:
	cmp r6, #0x9a
	bne _000006FC
	movs r4, #0xfc
_000006FC:
	cmp r6, #0x9c
	bge _0000070E
	ldrb r2, [r0, r6]
	ldrb r3, [r1, r6]
	ands r2, r4
	.2byte 0x1C76 @ adds r6, r6, #1
	cmp r2, r3
	beq _000006EE
	b _00000722
_0000070E:
	movs r4, #0x19
_00000710:
	ldrb r2, [r0, r6]
	adds r4, r4, r2
	.2byte 0x1C76 @ adds r6, r6, #1
	cmp r6, #0xba
	blt _00000710
	lsls r0, r4, #0x18
	bne _00000722
	movs r0, #0
	b _00000724
_00000722:
	movs r0, #1
_00000724:
	pop {r4, r5, r6, pc}

	UNALIGNED_THUMB_FUNC_START sub_00000726
sub_00000726: @ 0x00000726
	ldr r3, _00000AC8 @=gUnknown_03003580
	movs r2, #8
	movs r0, #0x7e
	negs r0, r0
_0000072E:
	str r0, [r3, r2]
	adds r2, #0x10
	cmp r2, #0x78
	blt _0000072E
	bx lr

	THUMB_FUNC_START sub_00000738
sub_00000738: @ 0x00000738
	push {r6, lr}
	subs r3, r0, #3
	lsls r6, r3, #2
	muls r6, r2, r6
	movs r3, #0x40
	subs r3, r3, r2
	muls r6, r3, r6
	.2byte 0x1EC0 @ subs r0, r0, #3
	movs r3, #0x18
	muls r3, r0, r3
	lsls r3, r3, #8
	subs r6, r6, r3
	str r6, [r1]
	cmp r2, #0x2f
	bgt _00000766
	movs r6, #0x1a
	muls r6, r2, r6
	subs r2, #0x48
	muls r6, r2, r6
	movs r3, #0x68
	lsls r3, r3, #8
	adds r6, r6, r3
	str r6, [r1, #4]
_00000766:
	pop {r6, pc}

	THUMB_FUNC_START sub_00000768
sub_00000768: @ 0x00000768
	push {r4, r5, r6, r7, lr}
	adds r7, r1, #0
	ldm r0!, {r4, r5, r6}
	adds r6, #0x80
	adds r1, r6, #0
	movs r0, #0x80
	lsls r0, r0, #0x10
	bl sub_000003A4
	lsls r3, r6, #1
	strh r3, [r7, #0xc]
	strh r3, [r7, #0xe]
	movs r1, #0x7f
	lsls r1, r1, #7
	str r1, [r7]
	str r1, [r7, #4]
	asrs r1, r4, #8
	muls r1, r0, r1
	asrs r1, r1, #0x10
	adds r1, #0x78
	strh r1, [r7, #8]
	asrs r1, r5, #8
	muls r1, r0, r1
	asrs r1, r1, #0x10
	adds r1, #0x50
	strh r1, [r7, #0xa]
	pop {r4, r5, r6, r7, pc}

	UNALIGNED_THUMB_FUNC_START sub_0000079E
sub_0000079E: @ 0x0000079E
	push {r4, r5, r6, r7, lr}
	ldr r4, [sp, #0x14]
	ldr r5, [sp, #0x18]
	movs r7, #0
_000007A6:
	movs r6, #0
_000007A8:
	strh r0, [r4, r6]
	adds r0, r0, r1
	.2byte 0x1CB6 @ adds r6, r6, #2
	cmp r6, r2
	blt _000007A8
	adds r4, r4, r5
	.2byte 0x1C7F @ adds r7, r7, #1
	cmp r7, r3
	blt _000007A6
	pop {r4, r5, r6, r7, pc}

	THUMB_FUNC_START sub_000007BC
sub_000007BC: @ 0x000007BC
	push {r4, r5, r6, r7, lr}
	movs r7, #2
_000007C0:
	ldr r4, _00000ACC @=gUnknown_3200
	lsls r3, r0, #1
	adds r3, r3, r0
	adds r3, r3, r7
	lsls r3, r3, #2
	adds r3, r3, r4
	ldr r5, [r3, #4]
	ldr r6, [r3, #0x10]
	movs r3, #0x20
	subs r3, r3, r1
	muls r3, r5, r3
	muls r6, r1, r6
	adds r3, r3, r6
	lsrs r4, r3, #5
	movs r6, #0x1f
	lsls r3, r6, #0x14
	ands r3, r4
	lsrs r5, r3, #0xa
	lsls r3, r6, #0xa
	ands r3, r4
	lsrs r3, r3, #5
	orrs r3, r5
	ands r4, r6
	orrs r4, r3
	adds r3, r2, r7
	lsls r6, r3, #1
	ldr r3, _00000AD0 @=PLTT + 0x0200
	adds r3, r6, r3
	strh r4, [r3]
	.2byte 0x1E7F @ subs r7, r7, #1
	bge _000007C0
	pop {r4, r5, r6, r7, pc}

	THUMB_FUNC_START swi_SoundBiasChange
swi_SoundBiasChange:
	movs r1, #2
	lsls r1, r1, #8
	mov ip, r1
	ldr r3, _00000AD4 @=REG_SOUNDBIAS
	ldrh r2, [r3]
	ldr r3, _00000AD4 @=REG_SOUNDBIAS
	lsls r1, r2, #0x16
	lsrs r1, r1, #0x16
	cmp r0, #0
	beq _0000081C
	cmp r1, ip
	bge _0000082C
	.2byte 0x1C92 @ adds r2, r2, #2
	b _00000822
_0000081C:
	cmp r1, #0
	ble _0000082C
	.2byte 0x1E92 @ subs r2, r2, #2
_00000822:
	strh r2, [r3]
	movs r2, #8
_00000826:
	.2byte 0x1E52 @ subs r2, r2, #1
	bpl _00000826
	b swi_SoundBiasChange
_0000082C:
	bx lr

	UNALIGNED_THUMB_FUNC_START sub_0000082E
sub_0000082E: @ 0x0000082E
	ldr r1, _00000AD8 @=gUnknown_03000564
	movs r2, #0x37
	lsls r2, r2, #4
	ldr r0, _00000ADC @=gUnknown_332C
	b _00000858

	THUMB_FUNC_START sub_00000838
sub_00000838: @ 0x00000838
	ldr r1, _00000AD8 @=gUnknown_03000564
	movs r2, #0x24
	ldr r0, _00000AE0 @=gUnknown_326C
	b _00000858

	THUMB_FUNC_START sub_00000840
sub_00000840: @ 0x00000840
	movs r1, #7
	lsls r1, r1, #0x18
	movs r2, #0x50
	ldr r0, _00000AE4 @=gUnknown_369C
	b _00000858

	UNALIGNED_THUMB_FUNC_START sub_0000084A
sub_0000084A: @ 0x0000084A
	ldr r1, _00000AE8 @=PLTT + 0x0038
	cmp r0, #0
	beq _00000854
	lsls r0, r0, #9
	adds r1, r1, r0
_00000854:
	movs r2, #8
	ldr r0, _00000AEC @=gUnknown_3264
_00000858:
	push {r4, r5, lr}
	adds r2, r2, r1
_0000085C:
	ldr r3, _00000ACC @=gUnknown_3200
	cmp r0, r3
	blt _00000872
	movs r3, #4
	lsls r3, r3, #0xc
	cmp r0, r3
	bge _00000872
	ldm r0!, {r3}
	stm r1!, {r3}
	cmp r1, r2
	blt _0000085C
_00000872:
	pop {r4, r5, pc}

	THUMB_FUNC_START sub_00000874
sub_00000874: @ 0x00000874
	push {r4, r5, r6, r7, lr}
	sub sp, #0x14
	ldr r1, _00000AF0 @=gUnknown_30C0
	ldm r1!, {r5, r7}
	add r0, sp, #8
	stm r0!, {r5, r7}
	ldr r0, _00000AF4 @=0x0BFE1FE0
	ldr r3, _00000AF8 @=ROM_HEADER_DEVICE
	ldrb r3, [r3]
	lsrs r3, r3, #7
	bne _0000088C
	ldr r0, _00000AFC @=0x0BFFFFE0
_0000088C:
	ldr r1, _00000AD8 @=gUnknown_03000564
	movs r2, #0xa
	bl swi_CPUSet
	bl sub_000005A4
	ldr r1, _00000AC0 @=gUnknown_03000088
	adds r3, r1, #0
	adds r3, #0xae
	ldrb r0, [r3]
	cmp r0, #0x96
	beq _000008B0
	ldr r2, _00000B00 @=0x85000027
	asrs r3, r2, #0x1f
	str r3, [sp, #0x10]
	add r0, sp, #0x10
	bl swi_CPUSet
_000008B0:
	bl sub_0000082E
	ldr r0, _00000AD8 @=gUnknown_03000564
	ldr r1, _00000B04 @=gUnknown_03001564
	bl swi_HuffUnComp_t
	ldr r0, _00000B04 @=gUnknown_03001564
	ldr r1, _00000AD8 @=gUnknown_03000564
	bl swi_LZ77UnCompWRAM_t
	movs r7, #0
_000008C6:
	lsls r0, r7, #2
	str r0, [sp, #0xc]
	ldr r2, _00000AD8 @=gUnknown_03000564
	lsls r0, r7, #8
	adds r0, r0, r2
	ldr r3, _00000B08 @=VRAM + 0x00040
	lsls r1, r7, #0xa
	adds r1, r1, r3
	add r2, sp, #8
	bl swi_BitUnPack_t
	.2byte 0x1C7F @ adds r7, r7, #1
	cmp r7, #8
	blt _000008C6
	movs r7, #0xe
_000008E4:
	movs r4, #3
_000008E6:
	ldr r3, _00000B08 @=VRAM + 0x00040
	lsls r0, r7, #1
	adds r0, r0, r4
	lsls r0, r0, #8
	adds r0, r0, r3
	ldr r3, _00000B0C @=gUnknown_30B0
	ldrh r2, [r3, r7]
	ldr r3, _00000B10 @=VRAM + 0x10000
	lsls r1, r4, #4
	adds r1, r1, r2
	lsls r1, r1, #6
	adds r1, r1, r3
	movs r2, #0x80
	bl swi_CPUSet
	.2byte 0x1E64 @ subs r4, r4, #1
	bge _000008E6
	.2byte 0x1EBF @ subs r7, r7, #2
	bge _000008E4
	ldr r0, _00000AC0 @=gUnknown_03000088
	bl sub_0000094A
	bl sub_00000974
	bl sub_00000982
	movs r2, #0x20
	str r2, [sp, #4]
	ldr r1, _00000B14 @=VRAM + 0x0B880
	str r1, [sp]
	movs r3, #4
	movs r2, #4
	ldr r1, _00000B18 @=0x00000202
	ldr r0, _00000B1C @=0x00007271
	bl sub_0000079E
	movs r1, #5
	lsls r1, r1, #0x18
	mvns r0, r1
	strh r0, [r1]
	movs r0, #0
	bl sub_0000084A
	movs r0, #1
	bl sub_0000084A
	bl sub_00000840
	add sp, #0x14
	pop {r4, r5, r6, r7, pc}

	UNALIGNED_THUMB_FUNC_START sub_0000094A
sub_0000094A: @ 0x0000094A
	push {r0, r4, r5, r6, r7, lr}
	ldr r4, _00000B20 @=gUnknown_03007FF0 + 7
	strb r0, [r4]
	bl sub_00000838
	ldr r0, [sp]
	ldr r1, _00000B24 @=gUnknown_03000588
	movs r2, #0x4e
	bl swi_CPUSet
	ldr r0, _00000AD8 @=gUnknown_03000564
	ldr r1, _00000B04 @=gUnknown_03001564
	bl swi_HuffUnComp_t
	ldr r0, _00000B04 @=gUnknown_03001564
	ldr r2, _00000B28 @=0x0000D082
	str r2, [r0]
	ldr r1, _00000AD8 @=gUnknown_03000564
	bl swi_Diff16bitUnFilter
	pop {r0, r4, r5, r6, r7, pc}

	THUMB_FUNC_START sub_00000974
sub_00000974: @ 0x00000974
	push {r0, r4, r5, r6, r7, lr}
	ldr r0, _00000AD8 @=gUnknown_03000564
	ldr r1, _00000B04 @=gUnknown_03001564
	ldr r2, _00000B2C @=gUnknown_30C8
	bl swi_BitUnPack_t
	pop {r0, r4, r5, r6, r7, pc}

	UNALIGNED_THUMB_FUNC_START sub_00000982
sub_00000982: @ 0x00000982
	push {r0, r4, r5, r6, r7, lr}
	ldr r6, _00000B04 @=gUnknown_03001564
	ldr r4, _00000B30 @=VRAM + 0x024C0
	movs r7, #2
_0000098A:
	movs r5, #0x34
_0000098C:
	ldm r6!, {r0, r1, r2, r3}
	stm r4!, {r0, r1, r2, r3}
	.2byte 0x1E6D @ subs r5, r5, #1
	bgt _0000098C
	adds r4, #0xc0
	.2byte 0x1E7F @ subs r7, r7, #1
	bgt _0000098A
	movs r7, #3
_0000099C:
	lsls r3, r7, #0xa
	ldr r0, _00000B34 @=VRAM + 0x02040
	adds r0, r0, r3
	ldr r1, _00000B38 @=VRAM + 0x16800
	adds r1, r1, r3
	movs r2, #1
	lsls r2, r2, #8
	bl swi_CPUFastSet_t
	.2byte 0x1E7F @ subs r7, r7, #1
	bgt _0000099C
	mov r0, sp
	str r7, [r0]
	ldr r1, _00000AD8 @=gUnknown_03000564
	movs r2, #8
	lsls r2, r2, #8
	bl _00000AB2
	pop {r0, r4, r5, r6, r7, pc}

	UNALIGNED_THUMB_FUNC_START swi_RegisterRamReset
swi_RegisterRamReset: @ 0x000009C2
	push {r4, r5, r6, r7, lr}
	sub sp, #4
	adds r7, r0, #0
	ldr r5, _00000B3C @=0x85000000
	movs r4, #4
	lsls r4, r4, #0x18
	movs r3, #0
	str r3, [sp]
	movs r1, #0x80
	strh r1, [r4]
	movs r6, #0x80
	tst r6, r7
	beq _00000A18
	lsrs r1, r4, #0x11
	adds r1, r1, r4
	movs r2, #8
	bl sub_00000AAC
	subs r1, #0x20
	mvns r0, r2
	strh r0, [r1, #2]
	lsrs r1, r4, #0x10
	adds r1, r1, r4
	strb r0, [r1, #0x10]
	adds r1, r4, #4
	movs r2, #8
	bl sub_00000AAC
	.2byte 0x1F09 @ subs r1, r1, #4
	movs r2, #0x10
	bl sub_00000AAC
	movs r1, #0xb0
	adds r1, r1, r4
	movs r2, #0x18
	bl sub_00000AAC
	str r2, [r1, #0x20]
	lsrs r0, r4, #0x12
	strh r0, [r4, #0x20]
	strh r0, [r4, #0x30]
	strh r0, [r4, #0x26]
	strh r0, [r4, #0x36]
_00000A18:
	movs r6, #0x20
	ldr r1, _00000B40 @=0x04000110
	movs r2, #8
	bl sub_00000AAC
	lsrs r2, r4, #0xb
	strh r2, [r1, #4]
	adds r1, #0x10
	movs r2, #7
	strb r2, [r1]
	bl sub_00000AAC
	movs r6, #0x40
	tst r6, r7
	beq _00000A6A
	movs r1, #0x80
	adds r1, r1, r4
	ldr r0, _00000B44 @=0x880E0000
	strb r0, [r1, #4]
	strb r1, [r1, #4]
	str r0, [r1]
	ldrh r0, [r1, #8]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x16
	strh r0, [r1, #8]
	subs r1, #0x10
	strb r1, [r1]
	adds r1, #0x20
	movs r2, #8
	bl sub_00000AAC
	subs r1, #0x40
	strb r2, [r1]
	adds r1, #0x20
	movs r2, #8
	bl sub_00000AAC
	movs r2, #0
	movs r1, #0x80
	adds r1, r1, r4
	strb r2, [r1, #4]
_00000A6A:
	movs r6, #1
	lsrs r1, r4, #1
	lsrs r2, r4, #0xa
	bl sub_00000AAC
	movs r6, #8
	movs r1, #6
	lsls r1, r1, #0x18
	lsrs r2, r1, #0xc
	bl sub_00000AAC
	movs r6, #0x10
	movs r1, #7
	lsls r1, r1, #0x18
	lsrs r2, r4, #0x12
	bl sub_00000AAC
	movs r6, #4
	movs r1, #5
	lsls r1, r1, #0x18
	lsrs r2, r4, #0x12
	bl sub_00000AAC
	movs r6, #2
	movs r1, #3
	lsls r1, r1, #0x18
	ldr r2, _00000B48 @=0x00001F80
	bl sub_00000AAC
	add sp, #4
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	THUMB_FUNC_START sub_00000AAC
sub_00000AAC: @ 0x00000AAC
	tst r6, r7
	bne _00000AB2
	bx lr
_00000AB2:
	mov r0, sp
	orrs r2, r5
	b swi_CPUFastSet_t
	.align 2, 0
_00000AB8: .4byte sub_00002D70
_00000ABC: .4byte swi_SoundDriverVSync
_00000AC0: .4byte gUnknown_03000088
_00000AC4: .4byte gUnknown_3290
_00000AC8: .4byte gUnknown_03003580
_00000ACC: .4byte gUnknown_3200
_00000AD0: .4byte PLTT + 0x0200
_00000AD4: .4byte REG_SOUNDBIAS
_00000AD8: .4byte gUnknown_03000564
_00000ADC: .4byte gUnknown_332C
_00000AE0: .4byte gUnknown_326C
_00000AE4: .4byte gUnknown_369C
_00000AE8: .4byte PLTT + 0x0038
_00000AEC: .4byte gUnknown_3264
_00000AF0: .4byte gUnknown_30C0
_00000AF4: .4byte 0x0BFE1FE0
_00000AF8: .4byte ROM_HEADER_DEVICE
_00000AFC: .4byte 0x0BFFFFE0
_00000B00: .4byte 0x85000027
_00000B04: .4byte gUnknown_03001564
_00000B08: .4byte VRAM + 0x00040
_00000B0C: .4byte gUnknown_30B0
_00000B10: .4byte VRAM + 0x10000
_00000B14: .4byte VRAM + 0x0B880
_00000B18: .4byte 0x00000202
_00000B1C: .4byte 0x00007271
_00000B20: .4byte gUnknown_03007FF0 + 7
_00000B24: .4byte gUnknown_03000588
_00000B28: .4byte 0x0000D082
_00000B2C: .4byte gUnknown_30C8
_00000B30: .4byte VRAM + 0x024C0
_00000B34: .4byte VRAM + 0x02040
_00000B38: .4byte VRAM + 0x16800
_00000B3C: .4byte 0x85000000
_00000B40: .4byte 0x04000110
_00000B44: .4byte 0x880E0000
_00000B48: .4byte 0x00001F80

	THUMB_FUNC_START swi_CPUSet
swi_CPUSet: @ 0x00000B4C
	push {r4, r5, lr}
	lsls r4, r2, #0xb
	lsrs r4, r4, #9
	bl CheckDestInWritableRange_t
	beq _00000B96
	movs r5, #0
	lsrs r3, r2, #0x1b
	bcc _00000B78
	adds r5, r1, r4
	lsrs r3, r2, #0x19
	bcc _00000B6E
	ldm r0!, {r3}
_00000B66:
	cmp r1, r5
	bge _00000B96
	stm r1!, {r3}
	b _00000B66
_00000B6E:
	cmp r1, r5
	bge _00000B96
	ldm r0!, {r3}
	stm r1!, {r3}
	b _00000B6E
_00000B78:
	lsrs r4, r4, #1
	lsrs r3, r2, #0x19
	bcc _00000B8A
	ldrh r3, [r0]
_00000B80:
	cmp r5, r4
	bge _00000B96
	strh r3, [r1, r5]
	.2byte 0x1CAD @ adds r5, r5, #2
	b _00000B80
_00000B8A:
	cmp r5, r4
	bge _00000B96
	ldrh r3, [r0, r5]
	strh r3, [r1, r5]
	.2byte 0x1CAD @ adds r5, r5, #2
	b _00000B8A
_00000B96:
	pop {r4, r5}
	pop {r3}
	bx r3

	THUMB_INTERWORK_FALLTHROUGH_2 CheckDestInWritableRange
CheckDestInWritableRange: @ 0x00000BA4
@ start addr: r0
@ size: r12
@ Sets eq if size is 0 or if any write is outside the acceptable range.
	cmp ip, #0
	beq _00000BBC
	bic ip, ip, #0xfe000000
	add ip, r0, ip
	tst r0, #0xe000000
	tstne ip, #0xe000000
_00000BBC:
	bx lr

	THUMB_INTERWORK_FALLTHROUGH swi_CPUFastSet
swi_CPUFastSet: @ 0x00000BC4
	push {r4, r5, r6, r7, r8, sb, sl, lr}
	lsl sl, r2, #0xb
	lsrs ip, sl, #9
	bl CheckDestInWritableRange
	beq _00000C24
	add sl, r1, sl, lsr #9
	lsrs r2, r2, #0x19
	bcc _00000C14
	ldr r2, [r0]
	mov r3, r2
	mov r4, r2
	mov r5, r2
	mov r6, r2
	mov r7, r2
	mov r8, r2
	mov sb, r2
_00000C04:
	cmp r1, sl
	stmlt r1!, {r2, r3, r4, r5, r6, r7, r8, sb}
	blt _00000C04
	b _00000C24
_00000C14:
	cmp r1, sl
	ldmlt r0!, {r2, r3, r4, r5, r6, r7, r8, sb}
	stmlt r1!, {r2, r3, r4, r5, r6, r7, r8, sb}
	blt _00000C14
_00000C24:
	pop {r4, r5, r6, r7, r8, sb, sl, lr}
	bx lr

	ARM_FUNC_START swi_BgAffineSet
swi_BgAffineSet: @ 0x00000C2C
	push {r4, r5, r6, r7, r8, sb, sl, fp}
_00000C30:
	subs r2, r2, #1
	blt _00000CD8
	ldrh r3, [r0, #0x10]
	lsr r3, r3, #8
	add ip, pc, #0x114
	add r8, r3, #0x40
	and r8, r8, #0xff
	lsl r8, r8, #1
	ldrsh fp, [r8, ip]
	lsl r8, r3, #1
	ldrsh ip, [r8, ip]
	ldrsh sb, [r0, #0xc]
	ldrsh sl, [r0, #0xe]
	mul r8, fp, sb
	asr r3, r8, #0xe
	mul r8, ip, sb
	asr r4, r8, #0xe
	mul r8, ip, sl
	asr r5, r8, #0xe
	mul r8, fp, sl
	asr r6, r8, #0xe
	ldm r0, {sb, sl, ip}
	lsl fp, ip, #0x10
	asr fp, fp, #0x10
	asr ip, ip, #0x10
	rsb r8, fp, #0
	mla sb, r3, r8, sb
	mla r8, r4, ip, sb
	str r8, [r1, #8]
	rsb r8, fp, #0
	mla sl, r5, r8, sl
	rsb r8, ip, #0
	mla r8, r6, r8, sl
	str r8, [r1, #0xc]
	strh r3, [r1]
	rsb r4, r4, #0
	strh r4, [r1, #2]
	strh r5, [r1, #4]
	strh r6, [r1, #6]
	add r0, r0, #0x14
	add r1, r1, #0x10
	b _00000C30
_00000CD8:
	pop {r4, r5, r6, r7, r8, sb, sl, fp}
	bx lr

	ARM_FUNC_START swi_ObjAffineSet
swi_ObjAffineSet:
	push {r8, sb, sl, fp}
_00000CE4:
	subs r2, r2, #1
	blt _00000D54
	ldrh sb, [r0, #4]
	lsr sb, sb, #8
	add ip, pc, #0x60
	add r8, sb, #0x40
	and r8, r8, #0xff
	lsl r8, r8, #1
	ldrsh fp, [r8, ip]
	lsl r8, sb, #1
	ldrsh ip, [r8, ip]
	ldrsh sb, [r0]
	ldrsh sl, [r0, #2]
	mul r8, fp, sb
	asr r8, r8, #0xe
	strh r8, [r1], r3
	mul r8, ip, sb
	asr r8, r8, #0xe
	rsb r8, r8, #0
	strh r8, [r1], r3
	mul r8, ip, sl
	asr r8, r8, #0xe
	strh r8, [r1], r3
	mul r8, fp, sl
	asr r8, r8, #0xe
	strh r8, [r1], r3
	add r0, r0, #8
	b _00000CE4
_00000D54:
	pop {r8, sb, sl, fp}
	bx lr

	.global gUnknown_0D5C
gUnknown_0D5C:
@ sine table?
	.2byte 0x0000
	.2byte 0x0192
	.2byte 0x0323
	.2byte 0x04B5
	.2byte 0x0645
	.2byte 0x07D5
	.2byte 0x0964
	.2byte 0x0AF1
	.2byte 0x0C7C
	.2byte 0x0E05
	.2byte 0x0F8C
	.2byte 0x1111
	.2byte 0x1294
	.2byte 0x1413
	.2byte 0x158F
	.2byte 0x1708
	.2byte 0x187D
	.2byte 0x19EF
	.2byte 0x1B5D
	.2byte 0x1CC6
	.2byte 0x1E2B
	.2byte 0x1F8B
	.2byte 0x20E7
	.2byte 0x223D
	.2byte 0x238E
	.2byte 0x24DA
	.2byte 0x261F
	.2byte 0x275F
	.2byte 0x2899
	.2byte 0x29CD
	.2byte 0x2AFA
	.2byte 0x2C21
	.2byte 0x2D41
	.2byte 0x2E5A
	.2byte 0x2F6B
	.2byte 0x3076
	.2byte 0x3179
	.2byte 0x3274
	.2byte 0x3367
	.2byte 0x3453
	.2byte 0x3536
	.2byte 0x3612
	.2byte 0x36E5
	.2byte 0x37AF
	.2byte 0x3871
	.2byte 0x392A
	.2byte 0x39DA
	.2byte 0x3A82
	.2byte 0x3B20
	.2byte 0x3BB6
	.2byte 0x3C42
	.2byte 0x3CC5
	.2byte 0x3D3E
	.2byte 0x3DAE
	.2byte 0x3E14
	.2byte 0x3E71
	.2byte 0x3EC5
	.2byte 0x3F0E
	.2byte 0x3F4E
	.2byte 0x3F84
	.2byte 0x3FB1
	.2byte 0x3FD3
	.2byte 0x3FEC
	.2byte 0x3FFB
	.2byte 0x4000
	.2byte 0x3FFB
	.2byte 0x3FEC
	.2byte 0x3FD3
	.2byte 0x3FB1
	.2byte 0x3F84
	.2byte 0x3F4E
	.2byte 0x3F0E
	.2byte 0x3EC5
	.2byte 0x3E71
	.2byte 0x3E14
	.2byte 0x3DAE
	.2byte 0x3D3E
	.2byte 0x3CC5
	.2byte 0x3C42
	.2byte 0x3BB6
	.2byte 0x3B20
	.2byte 0x3A82
	.2byte 0x39DA
	.2byte 0x392A
	.2byte 0x3871
	.2byte 0x37AF
	.2byte 0x36E5
	.2byte 0x3612
	.2byte 0x3536
	.2byte 0x3453
	.2byte 0x3367
	.2byte 0x3274
	.2byte 0x3179
	.2byte 0x3076
	.2byte 0x2F6B
	.2byte 0x2E5A
	.2byte 0x2D41
	.2byte 0x2C21
	.2byte 0x2AFA
	.2byte 0x29CD
	.2byte 0x2899
	.2byte 0x275F
	.2byte 0x261F
	.2byte 0x24DA
	.2byte 0x238E
	.2byte 0x223D
	.2byte 0x20E7
	.2byte 0x1F8B
	.2byte 0x1E2B
	.2byte 0x1CC6
	.2byte 0x1B5D
	.2byte 0x19EF
	.2byte 0x187D
	.2byte 0x1708
	.2byte 0x158F
	.2byte 0x1413
	.2byte 0x1294
	.2byte 0x1111
	.2byte 0x0F8C
	.2byte 0x0E05
	.2byte 0x0C7C
	.2byte 0x0AF1
	.2byte 0x0964
	.2byte 0x07D5
	.2byte 0x0645
	.2byte 0x04B5
	.2byte 0x0323
	.2byte 0x0192
	.2byte 0x0000
	.2byte 0xFE6E
	.2byte 0xFCDD
	.2byte 0xFB4B
	.2byte 0xF9BB
	.2byte 0xF82B
	.2byte 0xF69C
	.2byte 0xF50F
	.2byte 0xF384
	.2byte 0xF1FB
	.2byte 0xF074
	.2byte 0xEEEF
	.2byte 0xED6C
	.2byte 0xEBED
	.2byte 0xEA71
	.2byte 0xE8F8
	.2byte 0xE783
	.2byte 0xE611
	.2byte 0xE4A3
	.2byte 0xE33A
	.2byte 0xE1D5
	.2byte 0xE075
	.2byte 0xDF19
	.2byte 0xDDC3
	.2byte 0xDC72
	.2byte 0xDB26
	.2byte 0xD9E1
	.2byte 0xD8A1
	.2byte 0xD767
	.2byte 0xD633
	.2byte 0xD506
	.2byte 0xD3DF
	.2byte 0xD2BF
	.2byte 0xD1A6
	.2byte 0xD095
	.2byte 0xCF8A
	.2byte 0xCE87
	.2byte 0xCD8C
	.2byte 0xCC99
	.2byte 0xCBAD
	.2byte 0xCACA
	.2byte 0xC9EE
	.2byte 0xC91B
	.2byte 0xC851
	.2byte 0xC78F
	.2byte 0xC6D6
	.2byte 0xC626
	.2byte 0xC57E
	.2byte 0xC4E0
	.2byte 0xC44A
	.2byte 0xC3BE
	.2byte 0xC33B
	.2byte 0xC2C2
	.2byte 0xC252
	.2byte 0xC1EC
	.2byte 0xC18F
	.2byte 0xC13B
	.2byte 0xC0F2
	.2byte 0xC0B2
	.2byte 0xC07C
	.2byte 0xC04F
	.2byte 0xC02D
	.2byte 0xC014
	.2byte 0xC005
	.2byte 0xC000
	.2byte 0xC005
	.2byte 0xC014
	.2byte 0xC02D
	.2byte 0xC04F
	.2byte 0xC07C
	.2byte 0xC0B2
	.2byte 0xC0F2
	.2byte 0xC13B
	.2byte 0xC18F
	.2byte 0xC1EC
	.2byte 0xC252
	.2byte 0xC2C2
	.2byte 0xC33B
	.2byte 0xC3BE
	.2byte 0xC44A
	.2byte 0xC4E0
	.2byte 0xC57E
	.2byte 0xC626
	.2byte 0xC6D6
	.2byte 0xC78F
	.2byte 0xC851
	.2byte 0xC91B
	.2byte 0xC9EE
	.2byte 0xCACA
	.2byte 0xCBAD
	.2byte 0xCC99
	.2byte 0xCD8C
	.2byte 0xCE87
	.2byte 0xCF8A
	.2byte 0xD095
	.2byte 0xD1A6
	.2byte 0xD2BF
	.2byte 0xD3DF
	.2byte 0xD506
	.2byte 0xD633
	.2byte 0xD767
	.2byte 0xD8A1
	.2byte 0xD9E1
	.2byte 0xDB26
	.2byte 0xDC72
	.2byte 0xDDC3
	.2byte 0xDF19
	.2byte 0xE075
	.2byte 0xE1D5
	.2byte 0xE33A
	.2byte 0xE4A3
	.2byte 0xE611
	.2byte 0xE783
	.2byte 0xE8F8
	.2byte 0xEA71
	.2byte 0xEBED
	.2byte 0xED6C
	.2byte 0xEEEF
	.2byte 0xF074
	.2byte 0xF1FB
	.2byte 0xF384
	.2byte 0xF50F
	.2byte 0xF69C
	.2byte 0xF82B
	.2byte 0xF9BB
	.2byte 0xFB4B
	.2byte 0xFCDD
	.2byte 0xFE6E

	THUMB_INTERWORK_FALLTHROUGH swi_BitUnPack
swi_BitUnPack: @ 0x00000F60
	push {r4, r5, r6, r7, r8, sb, sl, fp, lr}
	sub sp, sp, #8
	ldrh r7, [r2]
	movs ip, r7
	bl CheckDestInWritableRange
	beq _00001004
	ldrb r6, [r2, #2]
	rsb sl, r6, #8
	mov lr, #0
	ldr fp, [r2, #4]
	lsr r8, fp, #0x1f
	ldr fp, [r2, #4]
	lsl fp, fp, #1
	lsr fp, fp, #1
	str fp, [sp, #4]
	ldrb r2, [r2, #3]
	mov r3, #0
_00000FA4:
	subs r7, r7, #1
	blt _00001004
	mov fp, #0xff
	asr r5, fp, sl
	ldrb sb, [r0], #1
	mov r4, #0
_00000FBC:
	cmp r4, #8
	bge _00000FA4
	and fp, sb, r5
	lsrs ip, fp, r4
	cmpeq r8, #0
	beq _00000FDC
	ldr fp, [sp, #4]
	add ip, ip, fp
_00000FDC:
	orr lr, lr, ip, lsl r3
	add r3, r3, r2
	cmp r3, #0x20
	blt _00000FF8
	str lr, [r1], #4
	mov lr, #0
	mov r3, #0
_00000FF8:
	lsl r5, r5, r6
	add r4, r4, r6
	b _00000FBC
_00001004:
	add sp, sp, #8
	pop {r4, r5, r6, r7, r8, sb, sl, fp, lr}
	bx lr

	THUMB_INTERWORK_FALLTHROUGH swi_HuffUnComp
swi_HuffUnComp: @ 0x00001014
	push {r4, r5, r6, r7, r8, sb, sl, fp, lr}
	sub sp, sp, #8
	movs ip, #0x2000000
	bl CheckDestInWritableRange
	beq _000010EC
	add r2, r0, #4
	add r7, r2, #1
	ldrb sl, [r0]
	and r4, sl, #0xf
	mov r3, #0
	mov lr, #0
	and sl, r4, #7
	add fp, sl, #4
	str fp, [sp, #4]
	ldr sl, [r0]
	lsr ip, sl, #8
	ldrb sl, [r2]
	add sl, sl, #1
	add r0, r2, sl, lsl #1
	mov r2, r7
_00001064:
	cmp ip, #0
	ble _000010EC
	mov r8, #0x20
	ldr r5, [r0], #4
_00001074:
	subs r8, r8, #1
	blt _00001064
	mov sl, #1
	and sb, sl, r5, lsr #31
	ldrb r6, [r2]
	lsl r6, r6, sb
	lsr sl, r2, #1
	lsl sl, sl, #1
	ldrb fp, [r2]
	and fp, fp, #0x3f
	add fp, fp, #1
	add sl, sl, fp, lsl #1
	add r2, sl, sb
	tst r6, #0x80
	beq _000010DC
	lsr r3, r3, r4
	ldrb sl, [r2]
	rsb fp, r4, #0x20
	orr r3, r3, sl, lsl fp
	mov r2, r7
	add lr, lr, #1
	ldr fp, [sp, #4]
	cmp lr, fp
	streq r3, [r1], #4
	subeq ip, ip, #4
	moveq lr, #0
_000010DC:
	cmp ip, #0
	lslgt r5, r5, #1
	bgt _00001074
	b _00001064
_000010EC:
	add sp, sp, #8
	pop {r4, r5, r6, r7, r8, sb, sl, fp, lr}
	bx lr

	THUMB_INTERWORK_FALLTHROUGH swi_LZ77UnCompWRAM
swi_LZ77UnCompWRAM: @ 0x000010FC
	push {r4, r5, r6, lr}
	ldr r5, [r0], #4
	lsr r2, r5, #8
	movs ip, r2
	bl CheckDestInWritableRange
	beq _0000118C
_00001114:
	cmp r2, #0
	ble _0000118C
	ldrb lr, [r0], #1
	mov r4, #8
_00001124:
	subs r4, r4, #1
	blt _00001114
	tst lr, #0x80
	bne _00001144
	ldrb r6, [r0], #1
	strb r6, [r1], #1
	sub r2, r2, #1
	b _0000117C
_00001144:
	ldrb r5, [r0]
	mov r6, #3
	add r3, r6, r5, asr #4
	ldrb r6, [r0], #1
	and r5, r6, #0xf
	lsl ip, r5, #8
	ldrb r6, [r0], #1
	orr r5, r6, ip
	add ip, r5, #1
	sub r2, r2, r3
_0000116C:
	ldrb r5, [r1, -ip]
	strb r5, [r1], #1
	subs r3, r3, #1
	bgt _0000116C
_0000117C:
	cmp r2, #0
	lslgt lr, lr, #1
	bgt _00001124
	b _00001114
_0000118C:
	pop {r4, r5, r6, lr}
	bx lr

	ARM_FUNC_START swi_LZ77UnCompVRAM
swi_LZ77UnCompVRAM: @ 0x00001194
	push {r4, r5, r6, r7, r8, sb, sl, lr}
	mov r3, #0
	ldr r8, [r0], #4
	lsr sl, r8, #8
	mov r2, #0
	movs ip, sl
	bl CheckDestInWritableRange
	beq _00001270
_000011B4:
	cmp sl, #0
	ble _00001270
	ldrb r6, [r0], #1
	mov r7, #8
_000011C4:
	subs r7, r7, #1
	blt _000011B4
	tst r6, #0x80
	bne _000011F0
	ldrb sb, [r0], #1
	orr r3, r3, sb, lsl r2
	sub sl, sl, #1
	eors r2, r2, #8
	strheq r3, [r1], #2
	moveq r3, #0
	b _00001260
_000011F0:
	ldrb sb, [r0]
	mov r8, #3
	add r5, r8, sb, asr #4
	ldrb sb, [r0], #1
	and r8, sb, #0xf
	lsl r4, r8, #8
	ldrb sb, [r0], #1
	orr r8, sb, r4
	add r4, r8, #1
	rsb r8, r2, #8
	and sb, r4, #1
	eor lr, r8, sb, lsl #3
	sub sl, sl, r5
_00001224:
	eor lr, lr, #8
	rsb r8, r2, #8
	add r8, r4, r8, lsr #3
	lsr r8, r8, #1
	lsl r8, r8, #1
	ldrh sb, [r1, -r8]
	mov r8, #0xff
	and r8, sb, r8, lsl lr
	asr r8, r8, lr
	orr r3, r3, r8, lsl r2
	eors r2, r2, #8
	strheq r3, [r1], #2
	moveq r3, #0
	subs r5, r5, #1
	bgt _00001224
_00001260:
	cmp sl, #0
	lslgt r6, r6, #1
	bgt _000011C4
	b _000011B4
_00001270:
	pop {r4, r5, r6, r7, r8, sb, sl, lr}
	bx lr

	UNALIGNED_THUMB_FUNC_START swi_RLUnCompWRAM
swi_RLUnCompWRAM: @ 0x00001278
	push {r4, r5, r6, r7, lr}
	ldm r0!, {r3}
	lsrs r7, r3, #8
	adds r4, r7, #0
	bl CheckDestInWritableRange_t
	beq _000012BA
_00001286:
	cmp r7, #0
	ble _000012BA
	ldrb r4, [r0]
	.2byte 0x1C40 @ adds r0, r0, #1
	lsls r2, r4, #0x19
	lsrs r2, r2, #0x19
	lsrs r3, r4, #8
	bhs _000012A8
	.2byte 0x1C52 @ adds r2, r2, #1
	subs r7, r7, r2
_0000129A:
	ldrb r3, [r0]
	strb r3, [r1]
	.2byte 0x1C40 @ adds r0, r0, #1
	.2byte 0x1C49 @ adds r1, r1, #1
	.2byte 0x1E52 @ subs r2, r2, #1
	bgt _0000129A
	b _00001286
_000012A8:
	.2byte 0x1CD2 @ adds r2, r2, #3
	subs r7, r7, r2
	ldrb r5, [r0]
	.2byte 0x1C40 @ adds r0, r0, #1
_000012B0:
	strb r5, [r1]
	.2byte 0x1C49 @ adds r1, r1, #1
	.2byte 0x1E52 @ subs r2, r2, #1
	bgt _000012B0
	b _00001286
_000012BA:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	UNALIGNED_THUMB_FUNC_START swi_RLUnCompVRAM
swi_RLUnCompVRAM: @ 0x000012C0
	push {r4, r5, r6, r7, lr}
	sub sp, #0xc
	movs r7, #0
	ldm r0!, {r3}
	lsrs r5, r3, #8
	adds r4, r5, #0
	bl CheckDestInWritableRange_t
	beq _0000132A
	movs r4, #0
_000012D4:
	cmp r5, #0
	ble _0000132A
	ldrb r3, [r0]
	str r3, [sp, #4]
	.2byte 0x1C40 @ adds r0, r0, #1
	ldr r3, [sp, #4]
	lsls r2, r3, #0x19
	lsrs r2, r2, #0x19
	ldr r6, [sp, #4]
	lsrs r3, r6, #8
	bhs _00001308
	.2byte 0x1C52 @ adds r2, r2, #1
	subs r5, r5, r2
_000012EE:
	ldrb r6, [r0]
	lsls r6, r4
	orrs r7, r6
	.2byte 0x1C40 @ adds r0, r0, #1
	movs r3, #8
	eors r4, r3
	bne _00001302
	strh r7, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
	movs r7, #0
_00001302:
	.2byte 0x1E52 @ subs r2, r2, #1
	bgt _000012EE
	b _000012D4
_00001308:
	.2byte 0x1CD2 @ adds r2, r2, #3
	subs r5, r5, r2
	ldrb r6, [r0]
	str r6, [sp, #8]
	.2byte 0x1C40 @ adds r0, r0, #1
_00001312:
	ldr r6, [sp, #8]
	lsls r6, r4
	orrs r7, r6
	movs r3, #8
	eors r4, r3
	bne _00001324
	strh r7, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
	movs r7, #0
_00001324:
	.2byte 0x1E52 @ subs r2, r2, #1
	bgt _00001312
	b _000012D4
_0000132A:
	add sp, #0xc
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	UNALIGNED_THUMB_FUNC_START swi_Diff8bitUnFilterWRAM
swi_Diff8bitUnFilterWRAM: @ 0x00001332
	push {r4, lr}
	ldm r0!, {r4}
	lsrs r4, r4, #8
	bl CheckDestInWritableRange_t
	beq _00001356
	ldrb r2, [r0]
	.2byte 0x1C40 @ adds r0, r0, #1
	strb r2, [r1]
	.2byte 0x1C49 @ adds r1, r1, #1
_00001346:
	.2byte 0x1E64 @ subs r4, r4, #1
	ble _00001356
	ldrb r3, [r0]
	adds r2, r3, r2
	.2byte 0x1C40 @ adds r0, r0, #1
	strb r2, [r1]
	.2byte 0x1C49 @ adds r1, r1, #1
	b _00001346
_00001356:
	pop {r4}
	pop {r3}
	bx r3

	UNALIGNED_THUMB_FUNC_START swi_Diff8bitUnFilterVRAM
swi_Diff8bitUnFilterVRAM: @ 0x0000135C
	push {r4, r5, r6, r7, lr}
	ldm r0!, {r3}
	lsrs r5, r3, #8
	adds r4, r5, #0
	bl CheckDestInWritableRange_t
	beq _00001392
	movs r4, #8
	ldrb r7, [r0]
	.2byte 0x1C40 @ adds r0, r0, #1
	adds r2, r7, #0
_00001372:
	.2byte 0x1E6D @ subs r5, r5, #1
	ble _00001392
	ldrb r3, [r0]
	adds r7, r3, r7
	.2byte 0x1C40 @ adds r0, r0, #1
	lsls r6, r7, #0x18
	lsrs r6, r6, #0x18
	lsls r6, r4
	orrs r2, r6
	movs r3, #8
	eors r4, r3
	bne _00001372
	strh r2, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
	movs r2, #0
	b _00001372
_00001392:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	UNALIGNED_THUMB_FUNC_START swi_Diff16bitUnFilter
swi_Diff16bitUnFilter: @ 0x00001398
	push {r4, lr}
	ldm r0!, {r4}
	lsrs r4, r4, #8
	bl CheckDestInWritableRange_t
	beq _000013BC
	ldrh r2, [r0]
	.2byte 0x1C80 @ adds r0, r0, #2
	strh r2, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
_000013AC:
	.2byte 0x1EA4 @ subs r4, r4, #2
	ble _000013BC
	ldrh r3, [r0]
	adds r2, r3, r2
	.2byte 0x1C80 @ adds r0, r0, #2
	strh r2, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
	b _000013AC
_000013BC:
	pop {r4}
	pop {r2}

	THUMB_FUNC_START sub_000013C0
sub_000013C0: @ 0x000013C0
	bx r2

	UNALIGNED_THUMB_FUNC_START sub_000013C2
sub_000013C2: @ 0x000013C2
	bx r1

	THUMB_FUNC_START swi_MusicPlayerOpen
swi_MusicPlayerOpen: @ 0x000013C4
	push {r4, r5, r7, lr}
	adds r4, r2, #0
	adds r5, r1, #0
	adds r7, r0, #0
	cmp r2, #1
	blt _0000141E
	cmp r4, #0x10
	ble _000013D6
	movs r4, #0x10
_000013D6:
	adds r0, r7, #0
	bl sub_000023B0
	str r5, [r7, #0x2c]
	ldr r0, _00001424 @=0x80000000
	strb r4, [r7, #8]
	str r0, [r7, #4]
	movs r0, #0
	b _000013F2
_000013E8:
	subs r1, r4, #1
	lsls r4, r1, #0x18
	lsrs r4, r4, #0x18
	strb r0, [r5]
	adds r5, #0x50
_000013F2:
	cmp r4, #0
	bgt _000013E8
	ldr r1, _00001428 @=gUnknown_03007FC0
	ldr r4, _0000142C @=0x68736D53
	ldr r1, [r1, #0x30]
	ldr r2, [r1]
	cmp r2, r4
	bne _0000141E
	adds r2, #1
	str r2, [r1]
	ldr r2, [r1, #0x20]
	cmp r2, #0
	beq _00001414
	str r2, [r7, #0x38]
	ldr r2, [r1, #0x24]
	str r2, [r7, #0x3c]
	str r0, [r1, #0x20]
_00001414:
	ldr r0, _00001430 @=sub_00002148
	str r7, [r1, #0x24]
	str r0, [r1, #0x20]
	str r4, [r1]
	str r4, [r7, #0x34]
_0000141E:
	pop {r4, r5, r7}
	pop {r3}
	bx r3
	.align 2, 0
_00001424: .4byte 0x80000000
_00001428: .4byte gUnknown_03007FC0
_0000142C: .4byte 0x68736D53
_00001430: .4byte sub_00002148

	THUMB_FUNC_START swi_MusicPlayerStart
swi_MusicPlayerStart: @ 0x00001434
	push {r4, r5, r6, r7, lr}
	adds r7, r0, #0
	ldr r0, [r0, #0x34]
	ldr r3, _000014BC @=0x68736D53
	adds r4, r1, #0
	cmp r0, r3
	bne _000014B4
	adds r0, #1
	str r0, [r7, #0x34]
	movs r1, #0
	str r1, [r7, #4]
	str r4, [r7]
	ldr r0, [r4, #4]
	str r0, [r7, #0x30]
	ldrb r0, [r4, #2]
	strb r0, [r7, #9]
	movs r0, #0x96
	strh r0, [r7, #0x1c]
	strh r0, [r7, #0x20]
	movs r0, #0xff
	adds r0, #1
	strh r0, [r7, #0x1e]
	strh r1, [r7, #0x22]
	strh r1, [r7, #0x24]
	ldr r5, [r7, #0x2c]
	movs r6, #0
	b _00001482
_0000146A:
	adds r0, r7, #0
	adds r1, r5, #0
	bl sub_000023E6
	movs r0, #0xc0
	strb r0, [r5]
	lsls r0, r6, #2
	adds r0, r0, r4
	ldr r0, [r0, #8]
	str r0, [r5, #0x40]
	adds r5, #0x50
	adds r6, #1
_00001482:
	ldrb r0, [r4]
	cmp r6, r0
	bge _000014A0
	ldrb r0, [r7, #8]
	cmp r0, r6
	bgt _0000146A
	b _000014A0
_00001490:
	adds r0, r7, #0
	adds r1, r5, #0
	bl sub_000023E6
	movs r0, #0
	strb r0, [r5]
	adds r5, #0x50
	adds r6, #1
_000014A0:
	ldrb r0, [r7, #8]
	cmp r0, r6
	bgt _00001490
	ldrb r0, [r4, #3]
	lsrs r1, r0, #8
	bcc _000014B0
	bl swi_SoundDriverMode
_000014B0:
	ldr r0, _000014BC @=0x68736D53
	str r0, [r7, #0x34]
_000014B4:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3
	.align 2, 0
_000014BC: .4byte 0x68736D53

	THUMB_FUNC_START swi_MusicPlayerStop
swi_MusicPlayerStop: @ 0x000014C0
	push {r4, r5, r6, r7, lr}
	adds r7, r0, #0
	ldr r0, [r0, #0x34]
	ldr r6, _000014F8 @=0x68736D53
	cmp r0, r6
	bne _000014F0
	adds r0, #1
	str r0, [r7, #0x34]
	ldr r0, [r7, #4]
	lsls r3, r6, #0x1f
	orrs r0, r3
	str r0, [r7, #4]
	ldrb r5, [r7, #8]
	ldr r4, [r7, #0x2c]
	b _000014EA
_000014DE:
	adds r0, r7, #0
	adds r1, r4, #0
	bl sub_000023E6
	adds r4, #0x50
	subs r5, #1
_000014EA:
	cmp r5, #0
	bgt _000014DE
	str r6, [r7, #0x34]
_000014F0:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3
	.align 2, 0
_000014F8: .4byte 0x68736D53

	THUMB_FUNC_START swi_MusicPlayerContinue
swi_MusicPlayerContinue: @ 0x000014FC
	ldr r2, [r0, #0x34]
	ldr r1, _00001510 @=0x68736D53
	cmp r2, r1
	bne _0000150E
	ldr r2, [r0, #4]
	str r1, [r0, #0x34]
	lsls r2, r2, #1
	lsrs r2, r2, #1
	str r2, [r0, #4]
_0000150E:
	bx lr
	.align 2, 0
_00001510: .4byte 0x68736D53

	THUMB_FUNC_START swi_MusicPlayerFadeOut
swi_MusicPlayerFadeOut: @ 0x00001514
	push {r7}
	ldr r7, [r0, #0x34]
	ldr r2, _00001530 @=0x68736D53
	cmp r7, r2
	bne _0000152A
	strh r1, [r0, #0x26]
	strh r1, [r0, #0x24]
	movs r1, #0xff
	adds r1, #1
	strh r1, [r0, #0x28]
	str r2, [r0, #0x34]
_0000152A:
	pop {r7}
	bx lr
	.align 2, 0
_00001530: .4byte 0x68736D53

	THUMB_FUNC_START sub_00001534
sub_00001534: @ 0x00001534
	push {r4, r5, r6, r7, lr}
	adds r7, r0, #0
	ldrh r0, [r0, #0x24]
	cmp r0, #0
	beq _00001572
	ldrh r1, [r7, #0x26]
	subs r1, #1
	lsls r1, r1, #0x10
	lsrs r1, r1, #0x10
	strh r1, [r7, #0x26]
	bne _00001572
	ldrh r1, [r7, #0x28]
	subs r1, #0x10
	strh r1, [r7, #0x28]
	lsls r1, r1, #0x10
	asrs r1, r1, #0x10
	cmp r1, #0
	bgt _00001578
	ldrb r5, [r7, #8]
	ldr r4, [r7, #0x2c]
	movs r6, #0
	b _0000156E
_00001560:
	adds r0, r7, #0
	adds r1, r4, #0
	bl sub_000023E6
	strb r6, [r4]
	adds r4, #0x50
	subs r5, #1
_0000156E:
	cmp r5, #0
	bgt _00001560
_00001572:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	THUMB_FUNC_START _00001578
_00001578:
	strh r0, [r7, #0x26]
	ldrb r1, [r7, #8]
	ldr r0, [r7, #0x2c]
	b _00001596
_00001580:
	ldrb r2, [r0]
	lsrs r3, r2, #8
	bcc _00001592
	ldrh r3, [r7, #0x28]
	lsrs r3, r3, #2
	strb r3, [r0, #0x13]
	movs r3, #3
	orrs r2, r3
	strb r2, [r0]
_00001592:
	adds r0, #0x50
	subs r1, #1
_00001596:
	cmp r1, #0
	bgt _00001580
	b _00001572

	THUMB_FUNC_START sub_0000159C
sub_0000159C: @ 0x0000159C
	push {r4, r5, r7, lr}
	ldrb r5, [r1]
	adds r7, r1, #0
	lsrs r1, r5, #1
	bcc _00001608
	ldrb r1, [r7, #0x12]
	ldrb r2, [r7, #0x13]
	ldrb r4, [r7, #0x18]
	muls r1, r2, r1
	lsrs r2, r1, #5
	cmp r4, #1
	bne _000015BA
	movs r3, #0x16
	ldrsb r1, [r7, r3]
	adds r2, r1, r2
_000015BA:
	movs r3, #0x14
	ldrsb r1, [r7, r3]
	lsls r1, r1, #1
	movs r3, #0x15
	ldrsb r3, [r7, r3]
	adds r1, r1, r3
	cmp r4, #2
	bne _000015D0
	movs r3, #0x16
	ldrsb r3, [r7, r3]
	adds r1, r3, r1
_000015D0:
	movs r3, #0x80
	cmn r1, r3
	bge _000015DA
	negs r1, r3
	b _000015E0
_000015DA:
	cmp r1, #0x7f
	ble _000015E0
	movs r1, #0x7f
_000015E0:
	adds r3, r1, #7
	adds r3, #0x79
	muls r3, r2, r3
	lsrs r3, r3, #8
	lsls r3, r3, #0x18
	lsrs r3, r3, #0x18
	cmp r3, #0xff
	bls _000015F2
	movs r3, #0xff
_000015F2:
	strb r3, [r7, #0x10]
	movs r3, #0x7f
	subs r1, r3, r1
	muls r1, r2, r1
	lsrs r1, r1, #8
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	cmp r1, #0xff
	bls _00001606
	movs r1, #0xff
_00001606:
	strb r1, [r7, #0x11]
_00001608:
	lsrs r1, r5, #3
	bcc _00001646
	movs r3, #0xe
	ldrsb r1, [r7, r3]
	ldrb r2, [r7, #0xf]
	muls r1, r2, r1
	lsls r1, r1, #2
	movs r3, #0xc
	ldrsb r2, [r7, r3]
	lsls r2, r2, #2
	adds r1, r1, r2
	movs r3, #0xa
	ldrsb r2, [r7, r3]
	lsls r2, r2, #8
	adds r1, r1, r2
	movs r3, #0xb
	ldrsb r2, [r7, r3]
	lsls r2, r2, #8
	adds r1, r1, r2
	ldrb r2, [r7, #0xd]
	adds r1, r1, r2
	ldrb r2, [r7, #0x18]
	cmp r2, #0
	bne _00001640
	movs r3, #0x16
	ldrsb r2, [r7, r3]
	lsls r2, r2, #4
	adds r1, r2, r1
_00001640:
	asrs r2, r1, #8
	strb r2, [r7, #8]
	strb r1, [r7, #9]
_00001646:
	ldr r2, _00001660 @=gUnknown_03007FC0
	adds r1, r7, #0
	ldr r2, [r2, #0x30]
	ldr r2, [r2, #0x3c]
	bl sub_000013C0
	ldrb r0, [r7]
	movs r3, #5
	bics r0, r3
	strb r0, [r7]
	pop {r4, r5, r7}
	pop {r3}
	bx r3
	.align 2, 0
_00001660: .4byte gUnknown_03007FC0

	THUMB_FUNC_START swi_SoundDriverInit
swi_SoundDriverInit: @ 0x00001664
	push {r3, r7, lr}
	adds r7, r0, #0
	ldr r1, _000016DC @=REG_DMA1DAD
	movs r0, #0
	strh r0, [r1, #6]
	strh r0, [r1, #0x12]
	ldr r0, _000016E0 @=REG_SOUNDCNT
	movs r2, #0x8f
	strh r2, [r0, #4]
	ldr r2, _000016E4 @=0x0000A90E
	strh r2, [r0, #2]
	ldrb r2, [r0, #9]
	lsls r2, r2, #0x1a
	lsrs r2, r2, #0x1a
	movs r3, #0x40
	orrs r2, r3
	movs r3, #0x35
	lsls r3, r3, #4
	strb r2, [r0, #9]
	adds r2, r7, r3
	str r2, [r0, #0x3c]
	ldr r0, _000016E8 @=REG_FIFO_A
	movs r3, #0x13
	lsls r3, r3, #7
	str r0, [r1]
	adds r0, r7, r3
	str r0, [r1, #8]
	ldr r0, _000016EC @=REG_FIFO_B
	ldr r2, _000016F4 @=PLTT + 0x03EC
	str r0, [r1, #0xc]
	ldr r0, _000016F0 @=gUnknown_03007FC0
	str r7, [r0, #0x30]
	movs r0, #0
	str r0, [sp]
	mov r0, sp
	adds r1, r7, #0
	bl swi_CPUSet
	movs r0, #8
	strb r0, [r7, #6]
	movs r0, #0xf
	strb r0, [r7, #7]
	ldr r0, _000016F8 @=sub_00002424
	str r0, [r7, #0x38]
	ldr r0, _000016FC @=sub_00001708
	str r0, [r7, #0x28]
	str r0, [r7, #0x2c]
	str r0, [r7, #0x30]
	str r0, [r7, #0x3c]
	ldr r0, _00001700 @=gUnknown_3738
	str r0, [r7, #0x34]
	movs r0, #1
	lsls r0, r0, #0x12
	bl sub_0000170A
	ldr r0, _00001704 @=0x68736D53
	str r0, [r7]
	pop {r3, r7}
	pop {r3}
	bx r3
	.align 2, 0
_000016DC: .4byte REG_DMA1DAD
_000016E0: .4byte REG_SOUNDCNT
_000016E4: .4byte 0x0000A90E
_000016E8: .4byte REG_FIFO_A
_000016EC: .4byte REG_FIFO_B
_000016F0: .4byte gUnknown_03007FC0
_000016F4: .4byte PLTT + 0x03EC
_000016F8: .4byte sub_00002424
_000016FC: .4byte sub_00001708
_00001700: .4byte gUnknown_3738
_00001704: .4byte 0x68736D53

	THUMB_FUNC_START sub_00001708
sub_00001708: @ 0x00001708
	bx lr

	UNALIGNED_THUMB_FUNC_START sub_0000170A
sub_0000170A: @ 0x0000170A
	push {r4, r7, lr}
	ldr r1, _00001784 @=gUnknown_03007FC0
	movs r3, #0xf
	lsls r3, r3, #0x10
	ands r0, r3
	ldr r7, [r1, #0x30]
	lsrs r0, r0, #0x10
	strb r0, [r7, #8]
	ldr r1, _00001788 @=gUnknown_31E8
	lsls r0, r0, #1
	adds r0, r0, r1
	subs r0, #0x20
	ldrh r0, [r0, #0x1e]
	movs r1, #0x63
	lsls r1, r1, #4
	adds r4, r0, #0
	str r0, [r7, #0x10]
	bl swi_DivArm_t
	strb r0, [r7, #0xb]
	ldr r0, _0000178C @=0x00091D1B
	ldr r3, _00001790 @=0x00001388
	muls r0, r4, r0
	adds r1, r0, r3
	lsls r0, r3, #1
	bl swi_DivArm_t
	movs r1, #1
	lsls r1, r1, #0x18
	str r0, [r7, #0x14]
	bl swi_DivArm_t
	adds r0, #1
	asrs r0, r0, #1
	str r0, [r7, #0x18]
	ldr r4, _00001794 @=REG_TM0CNT
	movs r0, #0
	strh r0, [r4, #2]
	ldr r0, [r7, #0x10]
	ldr r1, _00001798 @=0x00044940
	bl swi_DivArm_t
	movs r1, #1
	lsls r1, r1, #0x10
	subs r0, r1, r0
	strh r0, [r4]
	bl swi_SoundDriverVSyncOn
	movs r0, #1
	lsls r0, r0, #0x1a
_0000176E:
	ldrb r1, [r0, #6]
	cmp r1, #0x9f
	beq _0000176E
_00001774:
	ldrb r1, [r0, #6]
	cmp r1, #0x9f
	bne _00001774
	movs r0, #0x80
	strh r0, [r4, #2]
	pop {r4, r7}
	pop {r3}
	bx r3
	.align 2, 0
_00001784: .4byte gUnknown_03007FC0
_00001788: .4byte gUnknown_31E8
_0000178C: .4byte 0x00091D1B
_00001790: .4byte 0x00001388
_00001794: .4byte REG_TM0CNT
_00001798: .4byte 0x00044940

	THUMB_FUNC_START swi_SoundDriverMode
swi_SoundDriverMode: @ 0x0000179C
	push {r4, r5, r7, lr}
	ldr r1, _00001818 @=gUnknown_03007FC0
	ldr r5, _0000181C @=0x68736D53
	ldr r7, [r1, #0x30]
	ldr r1, [r7]
	cmp r1, r5
	bne _00001812
	adds r1, #1
	str r1, [r7]
	lsls r1, r0, #0x18
	lsrs r1, r1, #0x18
	beq _000017BA
	lsls r1, r1, #0x19
	lsrs r1, r1, #0x19
	strb r1, [r7, #5]
_000017BA:
	movs r1, #0xf
	lsls r1, r1, #8
	ands r1, r0
	beq _000017D6
	lsrs r1, r1, #8
	strb r1, [r7, #6]
	movs r1, #0xc
	movs r3, #0
	adds r2, r7, #7
	adds r2, #0x49
_000017CE:
	strb r3, [r2]
	adds r2, #0x40
	subs r1, #1
	bne _000017CE
_000017D6:
	movs r1, #0xf
	lsls r1, r1, #0xc
	ands r1, r0
	beq _000017E2
	lsrs r1, r1, #0xc
	strb r1, [r7, #7]
_000017E2:
	movs r1, #0xb
	lsls r1, r1, #0x14
	ands r1, r0
	beq _000017FE
	movs r3, #3
	lsls r3, r3, #0x14
	ldr r2, _00001820 @=REG_SOUNDCNT
	ands r1, r3
	ldrb r3, [r2, #9]
	lsrs r1, r1, #0xe
	lsls r3, r3, #0x1a
	lsrs r3, r3, #0x1a
	orrs r1, r3
	strb r1, [r2, #9]
_000017FE:
	movs r4, #0xf
	lsls r4, r4, #0x10
	ands r4, r0
	beq _00001810
	bl swi_SoundDriverVSyncOff
	adds r0, r4, #0
	bl sub_0000170A
_00001810:
	str r5, [r7]
_00001812:
	pop {r4, r5, r7}
	pop {r3}
	bx r3
	.align 2, 0
_00001818: .4byte gUnknown_03007FC0
_0000181C: .4byte 0x68736D53
_00001820: .4byte REG_SOUNDCNT

	THUMB_FUNC_START swi_SoundChannelClear
swi_SoundChannelClear: @ 0x00001824
	push {r4, r5, r6, r7, lr}
	ldr r0, _00001870 @=gUnknown_03007FC0
	ldr r6, _00001874 @=0x68736D53
	ldr r7, [r0, #0x30]
	ldr r0, [r7]
	cmp r0, r6
	bne _00001868
	adds r0, #1
	str r0, [r7]
	adds r0, r7, #7
	movs r1, #0xc
	adds r0, #0x49
_0000183C:
	movs r2, #0
	strb r2, [r0]
	adds r0, #0x40
	subs r1, #1
	cmp r1, #0
	bgt _0000183C
	ldr r5, [r7, #0x1c]
	cmp r5, #0
	beq _00001866
	movs r4, #1
_00001850:
	lsls r0, r4, #0x18
	lsrs r0, r0, #0x18
	ldr r1, [r7, #0x2c]
	bl sub_000013C2
	adds r4, #1
	adds r5, #0x40
	cmp r4, #4
	ble _00001850
	movs r2, #0
	strb r2, [r5]
_00001866:
	str r6, [r7]
_00001868:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3
	.align 2, 0
_00001870: .4byte gUnknown_03007FC0
_00001874: .4byte 0x68736D53

	THUMB_FUNC_START swi_SoundDriverVSyncOff
swi_SoundDriverVSyncOff: @ 0x00001878
	push {r3, r7, lr}
	ldr r0, _000018B8 @=gUnknown_03007FC0
	ldr r3, _000018BC @=0x68736D53
	ldr r7, [r0, #0x30]
	ldr r0, [r7]
	cmp r0, r3
	bcc _000018B0
	adds r3, #1
	cmp r0, r3
	bhi _000018B0
	adds r0, #1
	str r0, [r7]
	movs r0, #0
	ldr r1, _000018C0 @=REG_DMA1DAD
	movs r3, #0x35
	strh r0, [r1, #6]
	strh r0, [r1, #0x12]
	strb r0, [r7, #4]
	lsls r3, r3, #4
	adds r1, r7, r3
	str r0, [sp]
	mov r0, sp
	ldr r2, _000018C4 @=PLTT + 0x0318
	bl swi_CPUSet
	ldr r0, [r7]
	subs r0, #1
	str r0, [r7]
_000018B0:
	pop {r3, r7}
	pop {r3}
	bx r3
	.align 2, 0
_000018B8: .4byte gUnknown_03007FC0
_000018BC: .4byte 0x68736D53
_000018C0: .4byte REG_DMA1DAD
_000018C4: .4byte PLTT + 0x0318

	THUMB_FUNC_START swi_SoundDriverVSyncOn
swi_SoundDriverVSyncOn: @ 0x000018C8
	movs r1, #0x5b
	ldr r0, _000018D4 @=REG_DMA1DAD
	lsls r1, r1, #9
	strh r1, [r0, #6]
	strh r1, [r0, #0x12]
	bx lr
	.align 2, 0
_000018D4: .4byte REG_DMA1DAD

	UNALIGNED_THUMB_FUNC_START swi_MIDIKey2Freq
swi_MIDIKey2Freq: @ 0x000018D8
	push {r4, r5, r6, r7, lr}
	lsls r2, r2, #0x18
	adds r7, r0, #0
	cmp r1, #0xb2
	ble _000018E6
	ldr r2, _00001920 @=0xFF000000
	movs r1, #0xb2
_000018E6:
	ldr r0, _00001924 @=gUnknown_3104
	ldrb r3, [r0, r1]
	lsls r4, r3, #0x1c
	lsrs r4, r4, #0x1c
	lsls r4, r4, #2
	adds r5, r0, #7
	adds r5, #0xad
	ldr r4, [r5, r4]
	lsrs r6, r3, #4
	lsrs r4, r6
	adds r0, r0, r1
	ldrb r0, [r0, #1]
	lsls r1, r0, #0x1c
	lsrs r1, r1, #0x1c
	lsls r1, r1, #2
	ldr r1, [r5, r1]
	lsrs r0, r0, #4
	lsrs r1, r0
	subs r0, r1, r4
	adds r1, r2, #0
	bl umull_t
	adds r1, r0, r4
	ldr r0, [r7, #4]
	bl umull_t
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3
	.align 2, 0
_00001920: .4byte 0xFF000000
_00001924: .4byte gUnknown_3104

	THUMB_FUNC_START sub_00001928
sub_00001928: @ 0x00001928
	push {r4, r5, r6, r7, lr}
	sub sp, #0x34
	movs r1, #0
	movs r0, #0
	str r0, [sp, #0x14]
	movs r0, #0x10
	str r0, [sp, #0xc]
	mvns r7, r1
	movs r0, #0xff
	str r1, [sp, #0x10]
	str r1, [sp]
	bl swi_RegisterRamReset
	ldr r0, _00001D2C @=0x04000300
	movs r5, #1
	strb r5, [r0]
	movs r0, #1
	bl swi_SoundBiasChange
	ldr r6, _00001D30 @=REG_IE
	movs r0, #8
	lsls r1, r0, #0x17
	strh r5, [r6]
	strh r0, [r1, #4]
	ldrh r0, [r6, #4]
	lsrs r0, r0, #0xf
	beq _00001962
	bl sub_00000284
_00001962:
	bl sub_00000874
	movs r0, #0xef
	lsls r0, r0, #7
	movs r1, #1
	lsls r1, r1, #0x1a
	strh r0, [r1, #0xe]
	movs r0, #0x54
	str r0, [sp, #8]
	movs r0, #0x76
	str r0, [sp, #4]
	movs r0, #0x15
	lsls r0, r0, #0xa
	str r0, [r1, #0x38]
	movs r0, #0x3b
	lsls r0, r0, #9
	str r0, [r1, #0x3c]
	ldr r1, _00001D38 @=REG_WIN0H
	ldr r0, _00001D34 @=0x10003F5F
	str r0, [r1, #0x10]
	bl sub_00000726
	bl sub_00002D68
	ldr r0, _00001D3C @=gUnknown_03003B2C
	bl swi_SoundDriverInit
	ldr r0, _00001D40 @=0x00940A00
	bl swi_SoundDriverMode
	ldr r1, _00001D44 @=gUnknown_0300372C
	ldr r0, _00001D48 @=gUnknown_030036EC
	movs r2, #6
	bl swi_MusicPlayerOpen
	ldr r1, _00001D4C @=gUnknown_0300394C
	ldr r0, _00001D50 @=gUnknown_0300390C
	movs r2, #6
	bl swi_MusicPlayerOpen
	b _00001C62
_000019B4:
	movs r5, #7
	b _00001B0A
_000019B8:
	movs r0, #6
	subs r2, r0, r5
	lsls r0, r2, #2
	adds r0, r0, r2
	adds r0, #8
	cmp r0, r7
	str r2, [sp, #0x30]
	bgt _000019D2
	ldr r3, _00001D54 @=gUnknown_03003564
	lsls r1, r5, #2
	ldr r2, [r3, r1]
	adds r2, #1
	str r2, [r3, r1]
_000019D2:
	ldr r3, _00001D54 @=gUnknown_03003564
	lsls r1, r5, #2
	ldr r2, [r3, r1]
	ldr r3, _00001D58 @=gUnknown_03003580
	lsls r1, r5, #4
	adds r1, r1, r3
	lsls r4, r5, #3
	str r1, [sp, #0x18]
	str r2, [sp, #0x1c]
	ldr r6, [r1, #8]
	movs r3, #7
	lsls r3, r3, #0x18
	str r4, [sp, #0x2c]
	adds r4, r4, r3
	cmp r6, #0
	bge _00001AC2
	cmp r0, r7
	bgt _000019FA
	adds r6, #2
	str r6, [r1, #8]
_000019FA:
	lsls r0, r5, #0x10
	asrs r0, r0, #0x10
	ldr r1, [sp, #0x18]
	bl sub_00000738
	movs r0, #0x14
	muls r0, r5, r0
	ldr r1, _00001D5C @=gUnknown_030035F0
	adds r1, r0, r1
	str r1, [sp, #0x28]
	str r1, [sp, #0x24]
	ldr r0, [sp, #0x18]
	bl sub_00000768
	lsls r0, r5, #5
	ldr r3, _00001D60 @=OAM + 0x26
	movs r2, #1
	adds r1, r0, r3
	ldr r0, [sp, #0x24]
	movs r3, #8
	adds r0, #0xc
	bl swi_ObjAffineSet_t
	movs r3, #0x60
	cmn r6, r3
	ble _00001AAC
	ldr r0, [r4]
	lsls r2, r3, #3
	orrs r2, r0
	movs r0, #0x3f
	mvns r0, r0
	adds r1, r0, #0
	cmp r6, r0
	str r2, [r4]
	bge _00001A44
	cmp r5, #4
	bge _00001A84
_00001A44:
	movs r3, #0x4b
	cmn r6, r3
	blt _00001A84
	cmp r6, #0
	bge _00001A76
	ldrh r0, [r4]
	movs r3, #1
	lsls r3, r3, #0xf
	orrs r0, r3
	strh r0, [r4]
	ldr r0, [sp, #0x2c]
	ldr r2, _00001D64 @=gUnknown_369C
	adds r0, r0, r2
	ldrh r2, [r4, #4]
	ldrh r0, [r0, #4]
	lsrs r2, r2, #0xa
	lsls r2, r2, #0xa
	adds r0, #4
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x16
	orrs r0, r2
	strh r0, [r4, #4]
	movs r0, #0x1f
	mvns r0, r0
	b _00001A84
_00001A76:
	movs r3, #3
	lsls r3, r3, #8
	bics r2, r3
	movs r0, #0xf
	mvns r0, r0
	lsls r1, r0, #1
	str r2, [r4]
_00001A84:
	ldr r2, [sp, #0x28]
	ldr r3, _00001D68 @=0xFE00FFFF
	ldrh r2, [r2, #8]
	adds r0, r2, r0
	ldr r2, [r4]
	ands r2, r3
	lsls r0, r0, #0x17
	lsrs r0, r0, #0x17
	lsls r0, r0, #0x10
	orrs r0, r2
	str r0, [r4]
	ldr r2, [sp, #0x28]
	ldrh r2, [r2, #0xa]
	adds r1, r2, r1
	lsrs r0, r0, #8
	lsls r0, r0, #8
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	orrs r0, r1
	str r0, [r4]
_00001AAC:
	negs r0, r6
	lsls r1, r0, #0x1c
	lsrs r1, r1, #0x1c
	lsls r1, r1, #1
	ldr r2, [sp, #0x30]
	asrs r0, r0, #4
	lsls r2, r2, #2
	adds r0, #1
	adds r2, #1
	bl sub_000007BC
_00001AC2:
	ldr r2, [sp, #0x1c]
	subs r0, r2, #7
	subs r0, #0x38
	cmp r0, #0x22
	bhi _00001AE6
	ldr r0, _00001D6C @=gUnknown_36EC
	ldr r2, [sp, #0x1c]
	adds r0, r0, r2
	subs r0, #0x40
	ldrb r1, [r0, #1]
	ldr r0, [r4]
	lsrs r2, r0, #8
	lsls r2, r2, #8
	adds r0, r0, r1
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	orrs r0, r2
	str r0, [r4]
_00001AE6:
	ldr r2, [sp, #0x1c]
	subs r1, r2, #7
	subs r1, #0x59
	cmp r1, #0x50
	bhi _00001B0A
	movs r0, #5
	bl swi_DivArm_t
	subs r0, #8
	bl sub_0000039C
	ldr r2, [sp, #0x30]
	lsls r1, r0, #2
	lsls r0, r2, #2
	adds r2, r0, #1
	movs r0, #0
	bl sub_000007BC
_00001B0A:
	subs r5, #1
	bmi _00001B10
	b _000019B8
_00001B10:
	movs r4, #7
	lsls r4, r4, #0x18
	cmp r7, #0x6c
	beq _00001B1C
	cmp r7, #0xb4
	bne _00001B38
_00001B1C:
	ldr r0, [sp, #8]
	movs r1, #6
	subs r0, #0x38
	str r0, [sp, #8]
	ldr r0, [sp, #4]
	str r1, [sp, #0x10]
	subs r0, #0x80
	str r0, [sp, #4]
	movs r0, #0xa
	str r0, [sp, #0xc]
	ldr r0, _00001D70 @=0x10001F5F
	ldr r1, _00001D38 @=REG_WIN0H
	str r0, [r1, #0x10]
	b _00001BC4
_00001B38:
	cmp r7, #0x6c
	ble _00001BBC
	ldr r0, [sp, #8]
	subs r0, #3
	str r0, [sp, #8]
	ldr r0, [sp, #0x20]
	cmp r0, #0
	bne _00001B4C
	movs r0, #1
	b _00001B4E
_00001B4C:
	movs r0, #2
_00001B4E:
	movs r3, #3
	ldr r1, [r4, #0x48]
	lsls r3, r3, #8
	bics r1, r3
	lsls r0, r0, #0x1e
	lsrs r0, r0, #0x1e
	lsls r0, r0, #8
	orrs r0, r1
	ldr r1, _00001D68 @=0xFE00FFFF
	ands r1, r0
	movs r3, #1
	lsls r3, r3, #0x12
	adds r0, r0, r3
	ldr r3, _00001D68 @=0xFE00FFFF
	bics r0, r3
	orrs r0, r1
	str r0, [r4, #0x48]
	movs r5, #0
_00001B72:
	lsls r0, r5, #3
	adds r0, r0, r4
	adds r1, r0, #7
	adds r1, #0x79
	movs r2, #3
	adds r6, r1, #0
	bl swi_CPUSet
	ldrh r0, [r6]
	movs r3, #3
	lsls r3, r3, #0xa
	eors r0, r3
	adds r5, #1
	cmp r5, #9
	strh r0, [r6]
	blt _00001B72
	movs r0, #6
	adds r1, r7, #0
	bl swi_DivArm_t
	cmp r1, #0
	bne _00001BB2
	ldr r1, [sp, #0x10]
	ldr r0, [sp, #0xc]
	adds r1, #1
	subs r0, #1
	str r0, [sp, #0xc]
	lsls r0, r0, #8
	orrs r0, r1
	str r1, [sp, #0x10]
	ldr r1, _00001D38 @=REG_WIN0H
	strh r0, [r1, #0x12]
_00001BB2:
	ldr r0, _00001D74 @=0x00003F27
	ldr r1, _00001D38 @=REG_WIN0H
	strh r0, [r1, #0xa]
	ldr r0, _00001D78 @=0x00009802
	b _00001BBE
_00001BBC:
	ldr r0, _00001D7C @=0x00001002
_00001BBE:
	movs r1, #1
	lsls r1, r1, #0x1a
	strh r0, [r1]
_00001BC4:
	ldr r0, [sp, #8]
	lsls r0, r0, #8
	movs r1, #1
	lsls r1, r1, #0x1a
	str r0, [r1, #0x38]
	ldr r0, [sp, #4]
	lsls r0, r0, #8
	str r0, [r1, #0x3c]
	cmp r7, #0x10
	blt _00001BE4
	bl swi_SoundDriverMain
	cmp r7, #0x10
	bne _00001BE4
	ldr r1, _00001D80 @=gUnknown_3908
	b _00001BEA
_00001BE4:
	cmp r7, #0xa2
	bne _00001BF0
	ldr r1, _00001D84 @=gUnknown_39C0
_00001BEA:
	ldr r0, _00001D48 @=gUnknown_030036EC
	bl swi_MusicPlayerStart
_00001BF0:
	subs r0, r7, #7
	subs r0, #0x3a
	cmp r0, #0x4f
	bhs _00001C1C
	ldr r0, [sp, #0x20]
	cmp r0, #0
	bne _00001C1C
	ldr r0, _00001D88 @=gUnknown_03000064
	movs r3, #1
	ldr r0, [r0, #0x24]
	cmn r0, r3
	beq _00001C1C
	ldr r0, _00001D8C @=REG_KEYINPUT
	ldrb r0, [r0]
	cmp r0, #0xf3
	bne _00001C1C
	ldr r1, _00001D90 @=gUnknown_389C
	ldr r0, _00001D50 @=gUnknown_0300390C
	bl swi_MusicPlayerStart
	movs r0, #1
	str r0, [sp, #0x20]
_00001C1C:
	cmp r7, #0x38
	ble _00001C3C
	ldr r0, [sp, #0x20]
	cmp r0, #0
	beq _00001C3C
	ldr r1, [sp]
	cmp r1, #0x20
	bge _00001C32
	ldr r1, [sp]
	adds r1, #2
	str r1, [sp]
_00001C32:
	movs r2, #0x1f
	movs r0, #6
	ldr r1, [sp]
	bl sub_000007BC
_00001C3C:
	bl sub_00002B34
	ldr r1, _00001D30 @=REG_IE
	movs r0, #1
	strh r0, [r1, #8]
	bl swi_VBlankIntrWait_t
	cmp r7, #0x10
	bge _00001C62
	ldr r1, [sp, #0x10]
	ldr r0, [sp, #0xc]
	adds r1, #1
	subs r0, #1
	str r0, [sp, #0xc]
	lsls r0, r0, #8
	orrs r0, r1
	str r1, [sp, #0x10]
	ldr r1, _00001D38 @=REG_WIN0H
	strh r0, [r1, #0x12]
_00001C62:
	adds r7, #1
	cmp r7, #0xd2
	bgt _00001C6A
	b _000019B4
_00001C6A:
	ldr r0, _00001D94 @=gUnknown_03000088
	bl sub_000006E8
	movs r6, #0
	adds r7, r0, #0
	cmp r0, #0
	ldr r5, _00001D98 @=0x03FFFFF0
	bne _00001C80
	ldr r0, [sp, #0x20]
	cmp r0, #0
	beq _00001CD8
_00001C80:
	movs r0, #1
	strb r0, [r5, #0xb]
	strb r6, [r5, #7]
_00001C86:
	bl sub_00002B34
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	strb r0, [r5, #0xa]
	bne _00001CD8
	bl swi_SoundDriverMain
	bl swi_VBlankIntrWait_t
	cmp r7, #0
	bne _00001C86
	ldrb r0, [r5, #7]
	cmp r0, #0
	bne _00001C86
	ldrb r0, [r5, #0xb]
	cmp r0, #0
	beq _00001CC2
	ldr r0, _00001D8C @=REG_KEYINPUT
	ldrb r0, [r0]
	mvns r0, r0
	movs r3, #0xf3
	ands r0, r3
	beq _00001C86
	ldr r1, _00001D9C @=gUnknown_3818
	ldr r0, _00001D50 @=gUnknown_0300390C
	bl swi_MusicPlayerStart
	strb r6, [r5, #0xb]
	b _00001C86
_00001CC2:
	ldr r1, [sp]
	cmp r1, #0
	ble _00001CD8
	ldr r1, [sp]
	movs r2, #0x1f
	subs r1, #1
	str r1, [sp]
	movs r0, #6
	bl sub_000007BC
	b _00001C86
_00001CD8:
	ldr r1, _00001DA0 @=0x00103FBF
	ldr r0, _00001D38 @=REG_WIN0H
	str r1, [r0, #0x10]
	str r6, [r0, #0x14]
	movs r1, #0
_00001CE2:
	lsls r2, r1, #3
	ldr r7, [r4, r2]
	movs r3, #3
	lsls r3, r3, #0xa
	bics r7, r3
	adds r1, #1
	cmp r1, #9
	str r7, [r4, r2]
	blt _00001CE2
	movs r7, #0
	mvns r7, r7
	adds r4, r0, #0
	b _00001D16
_00001CFC:
	bl swi_SoundDriverMain
	bl swi_VBlankIntrWait_t
	lsrs r0, r7, #1
	bhs _00001D16
	ldr r0, [sp, #0x14]
	cmp r0, #0x10
	beq _00001D16
	ldr r0, [sp, #0x14]
	adds r0, #1
	str r0, [sp, #0x14]
	str r0, [r4, #0x14]
_00001D16:
	adds r7, #1
	cmp r7, #0x32
	ble _00001CFC
	bl swi_SoundDriverVSyncOff
	ldrb r0, [r5, #0xa]
	cmp r0, #0
	beq _00001DA4
	movs r0, #0xde
	b _00001DA6

	UNALIGNED_THUMB_FUNC_START _00001D2A
_00001D2A: @ 0x00001D2A
	b _00001DA4
	.align 2, 0
_00001D2C: .4byte 0x04000300
_00001D30: .4byte REG_IE
_00001D34: .4byte 0x10003F5F
_00001D38: .4byte REG_WIN0H
_00001D3C: .4byte gUnknown_03003B2C
_00001D40: .4byte 0x00940A00
_00001D44: .4byte gUnknown_0300372C
_00001D48: .4byte gUnknown_030036EC
_00001D4C: .4byte gUnknown_0300394C
_00001D50: .4byte gUnknown_0300390C
_00001D54: .4byte gUnknown_03003564
_00001D58: .4byte gUnknown_03003580
_00001D5C: .4byte gUnknown_030035F0
_00001D60: .4byte OAM + 0x26
_00001D64: .4byte gUnknown_369C
_00001D68: .4byte 0xFE00FFFF
_00001D6C: .4byte gUnknown_36EC
_00001D70: .4byte 0x10001F5F
_00001D74: .4byte 0x00003F27
_00001D78: .4byte 0x00009802
_00001D7C: .4byte 0x00001002
_00001D80: .4byte gUnknown_3908
_00001D84: .4byte gUnknown_39C0
_00001D88: .4byte gUnknown_03000064
_00001D8C: .4byte REG_KEYINPUT
_00001D90: .4byte gUnknown_389C
_00001D94: .4byte gUnknown_03000088
_00001D98: .4byte 0x03FFFFF0
_00001D9C: .4byte gUnknown_3818
_00001DA0: .4byte 0x00103FBF
_00001DA4:
	movs r0, #0xff
_00001DA6:
	bl swi_RegisterRamReset
	add sp, #0x34
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3
	.align 2, 0

	THUMB_FUNC_START umull_t
umull_t: @ 0x00001DB4
	add r2, pc, #0x0
	bx r2
	.ARM
	umull r2, r3, r0, r1
	add r0, r3, #0
	bx lr

	THUMB_FUNC_START swi_SoundDriverMain
swi_SoundDriverMain: @ 0x00001DC4
	ldr r0, _00002140 @=gUnknown_03007FF0
	ldr r0, [r0]
	ldr r2, _00002144 @=0x68736D53
	ldr r3, [r0]
	cmp r2, r3
	beq _00001DD2
	bx lr
_00001DD2:
	.2byte 0x1C5B @ adds r3, r3, #1
	str r3, [r0]
	push {r4, r5, r6, r7, lr}
	mov r1, r8
	mov r2, sb
	mov r3, sl
	mov r4, fp
	push {r0, r1, r2, r3, r4}
	sub sp, #0x14
	ldr r3, [r0, #0x20]
	cmp r3, #0
	beq _00001DF2
	ldr r0, [r0, #0x24]
	bl sub_00002102
	ldr r0, [sp, #0x14]
_00001DF2:
	ldr r3, [r0, #0x28]
	bl sub_00002102
	ldr r0, [sp, #0x14]
	ldr r3, [r0, #0x10]
	mov r8, r3
	ldr r5, _00002104 @=0x00000350
	adds r5, r5, r0
	ldrb r4, [r0, #4]
	subs r7, r4, #1
	bls _00001E12
	ldrb r1, [r0, #0xb]
	subs r1, r1, r7
	mov r2, r8
	muls r2, r1, r2
	adds r5, r5, r2
_00001E12:
	str r5, [sp, #8]
	ldr r6, _00002108 @=0x00000630
	ldrb r3, [r0, #5]
	cmp r3, #0
	beq _00001E74
	add r1, pc, #0x0
	bx r1
	.ARM
	cmp r4, #2
	addeq r7, r0, #0x350
	addne r7, r5, r8
	mov r4, r8
_00001E30:
	ldrsb r0, [r5, r6]
	ldrsb r1, [r5]
	add r0, r0, r1
	ldrsb r1, [r7, r6]
	add r0, r0, r1
	ldrsb r1, [r7], #1
	add r0, r0, r1
	mul r1, r0, r3
	asr r0, r1, #9
	tst r0, #0x80
	addne r0, r0, #1
	strb r0, [r5, r6]
	strb r0, [r5], #1
	subs r4, r4, #1
	bgt _00001E30
	add r0, pc, #_00001E9C - . + 1 - 8
	bx r0
	.THUMB
_00001E74:
	movs r0, #0
	mov r1, r8
	adds r6, r6, r5
	lsrs r1, r1, #3
	bcc _00001E82
	stm r5!, {r0}
	stm r6!, {r0}
_00001E82:
	lsrs r1, r1, #1
	bcc _00001E8E
	stm r5!, {r0}
	stm r6!, {r0}
	stm r5!, {r0}
	stm r6!, {r0}
_00001E8E:
	stm r5!, {r0}
	stm r6!, {r0}
	stm r5!, {r0}
	stm r6!, {r0}
	stm r5!, {r0}
	stm r6!, {r0}
	stm r5!, {r0}
	stm r6!, {r0}
	.2byte 0x1E49 @ subs r1, r1, #1
	bgt _00001E8E
_00001E9C:
	ldr r4, [sp, #0x14]
	ldr r0, [r4, #0x14]
	mov sb, r0
	ldr r0, [r4, #0x18]
	mov ip, r0
	ldrb r0, [r4, #6]
	adds r4, #0x50
_00001EB0:
	str r0, [sp, #4]
	ldr r3, [r4, #0x24]
	ldrb r6, [r4]
	movs r0, #0xc7
	tst r0, r6
	bne _00001EBE
	b _000020E4
_00001EBE:
	movs r0, #0x80
	tst r0, r6
	beq _00001EEE
_00001EC4:
	movs r0, #0x40
	tst r0, r6
	bne _00001EFE
	movs r6, #3
	strb r6, [r4]
	adds r0, r3, #0
	adds r0, #0x10
	str r0, [r4, #0x28]
	ldr r0, [r3, #0xc]
	str r0, [r4, #0x18]
	movs r5, #0
	strb r5, [r4, #9]
	str r5, [r4, #0x1c]
	ldrb r2, [r3, #3]
	movs r0, #0xc0
	tst r0, r2
	beq _00001F46
	movs r0, #0x10
	orrs r6, r0
	strb r6, [r4]
	b _00001F46
_00001EEE:
	ldrb r5, [r4, #9]
	movs r0, #4
	tst r0, r6
	beq _00001F04
	ldrb r0, [r4, #0xd]
	.2byte 0x1E40 @ subs r0, r0, #1
	strb r0, [r4, #0xd]
	bhi _00001F54
_00001EFE:
	movs r0, #0
	strb r0, [r4]
	b _000020E4
_00001F04:
	movs r0, #0x40
	tst r0, r6
	beq _00001F24
	ldrb r0, [r4, #7]
	muls r5, r0, r5
	lsrs r5, r5, #8
	ldrb r0, [r4, #0xc]
	cmp r5, r0
	bhi _00001F54
_00001F16:
	ldrb r5, [r4, #0xc]
	cmp r5, #0
	beq _00001EFE
	movs r0, #4
	orrs r6, r0
	strb r6, [r4]
	b _00001F54
_00001F24:
	movs r2, #3
	ands r2, r6
	cmp r2, #2
	bne _00001F42
	ldrb r0, [r4, #5]
	muls r5, r0, r5
	lsrs r5, r5, #8
	ldrb r0, [r4, #6]
	cmp r5, r0
	bhi _00001F54
	adds r5, r0, #0
	beq _00001F16
	.2byte 0x1E76 @ subs r6, r6, #1
	strb r6, [r4]
	b _00001F54
_00001F42:
	cmp r2, #3
	bne _00001F54
_00001F46:
	ldrb r0, [r4, #4]
	adds r5, r5, r0
	cmp r5, #0xff
	bcc _00001F54
	movs r5, #0xff
	.2byte 0x1E76 @ subs r6, r6, #1
	strb r6, [r4]
_00001F54:
	strb r5, [r4, #9]
	ldr r0, [sp, #0x14]
	ldrb r0, [r0, #7]
	.2byte 0x1C40 @ adds r0, r0, #1
	muls r0, r5, r0
	lsrs r5, r0, #4
	ldrb r0, [r4, #2]
	muls r0, r5, r0
	lsrs r0, r0, #8
	strb r0, [r4, #0xa]
	ldrb r0, [r4, #3]
	muls r0, r5, r0
	lsrs r0, r0, #8
	strb r0, [r4, #0xb]
	movs r0, #0x10
	ands r0, r6
	str r0, [sp, #0x10]
	beq _00001F88
	adds r0, r3, #0
	adds r0, #0x10
	ldr r1, [r3, #8]
	adds r0, r0, r1
	str r0, [sp, #0xc]
	ldr r0, [r3, #0xc]
	subs r0, r0, r1
	str r0, [sp, #0x10]
_00001F88:
	ldr r5, [sp, #8]
	ldr r2, [r4, #0x18]
	ldr r3, [r4, #0x28]
	add r0, pc, #0x4
	bx r0
	.ARM
	str r8, [sp]
	ldrb sl, [r4, #0xa]
	ldrb fp, [r4, #0xb]
	ldrb r0, [r4, #1]
	tst r0, #8
	beq _00001FFC
_00001FAC:
	ldrsb r6, [r3], #1
	mul r1, r6, fp
	ldrb r0, [r5, #0x630]
	add r0, r0, r1, asr #8
	strb r0, [r5, #0x630]
	mul r1, r6, sl
	ldrb r0, [r5]
	add r0, r0, r1, asr #8
	strb r0, [r5], #1
	subs r2, r2, #1
	bne _00001FF0
	ldr r2, [sp, #0x10]
	cmp r2, #0
	ldrne r3, [sp, #0xc]
	bne _00001FF0
	strb r2, [r4]
	b _000020D8
_00001FF0:
	subs r8, r8, #1
	bgt _00001FAC
	b _000020D0
_00001FFC:
	ldr r7, [r4, #0x1c]
	ldr lr, [r4, #0x20]
_00002004:
	cmp r7, sb, lsl #2
	bcc _00002028
_0000200C:
	cmp r2, #4
	ble _0000204C
	sub r2, r2, #4
	add r3, r3, #4
	sub r7, r7, sb, lsl #2
	cmp r7, sb, lsl #2
	bhs _0000200C
_00002028:
	cmp r7, sb, lsl #1
	bcc _00002044
	cmp r2, #2
	ble _0000204C
	sub r2, r2, #2
	add r3, r3, #2
	sub r7, r7, sb, lsl #1
_00002044:
	cmp r7, sb
	bcc _0000207C
_0000204C:
	subs r2, r2, #1
	bne _0000206C
	ldr r2, [sp, #0x10]
	cmp r2, #0
	ldrne r3, [sp, #0xc]
	bne _00002070
	strb r2, [r4]
	b _000020D8
_0000206C:
	add r3, r3, #1
_00002070:
	sub r7, r7, sb
	cmp r7, sb
	bhs _0000204C
_0000207C:
	ldrsb r0, [r3]
	ldrsb r1, [r3, #1]
	sub r1, r1, r0
	mul r6, r1, r7
	mul r1, r6, ip
	add r6, r0, r1, asr #23
	mul r1, r6, fp
	ldrb r0, [r5, #0x630]
	add r0, r0, r1, asr #8
	strb r0, [r5, #0x630]
	mul r1, r6, sl
	ldrb r0, [r5]
	add r0, r0, r1, asr #8
	strb r0, [r5], #1
	add r7, r7, lr
	subs r8, r8, #1
	beq _000020CC
	cmp r7, sb
	bcc _0000207C
	b _00002004
_000020CC:
	str r7, [r4, #0x1c]
_000020D0:
	str r2, [r4, #0x18]
	str r3, [r4, #0x28]
_000020D8:
	ldr r8, [sp]
	add r0, pc, #1
	bx r0
	.THUMB
_000020E4:
	ldr r0, [sp, #4]
	.2byte 0x1E40 @ subs r0, r0, #1
	ble _000020EE
	adds r4, #0x40
	b _00001EB0
_000020EE:
	ldr r0, [sp, #0x14]
	ldr r3, _00002144 @=0x68736D53
	str r3, [r0]
	add sp, #0x18
	pop {r0, r1, r2, r3, r4, r5, r6, r7}
	mov r8, r0
	mov sb, r1
	mov sl, r2
	mov fp, r3
	pop {r3}

	UNALIGNED_THUMB_FUNC_START sub_00002102
sub_00002102: @ 0x00002102
	bx r3
	.align 2, 0
_00002104: .4byte 0x00000350
_00002108: .4byte 0x00000630

	THUMB_FUNC_START swi_SoundDriverVSync
swi_SoundDriverVSync: @ 0x0000210C
	ldr r0, _00002140 @=gUnknown_03007FF0
	ldr r0, [r0]
	ldr r2, _00002144 @=0x68736D53
	ldr r3, [r0]
	cmp r2, r3
	bne _00002136
	ldrb r1, [r0, #4]
	.2byte 0x1E49 @ subs r1, r1, #1
	strb r1, [r0, #4]
	bgt _00002136
	ldrb r1, [r0, #0xb]
	strb r1, [r0, #4]
	movs r0, #0
	movs r1, #0xb6
	lsls r1, r1, #8
	ldr r2, _00002138 @=REG_DMA1CNT_H
	ldr r3, _0000213C @=REG_DMA2CNT_H
	strh r0, [r2]
	strh r0, [r3]
	strh r1, [r2]
	strh r1, [r3]
_00002136:
	bx lr
	.align 2, 0
_00002138: .4byte REG_DMA1CNT_H
_0000213C: .4byte REG_DMA2CNT_H
_00002140: .4byte gUnknown_03007FF0
_00002144: .4byte 0x68736D53

	THUMB_FUNC_START sub_00002148
sub_00002148: @ 0x00002148
	ldr r2, _000023AC @=0x68736D53
	ldr r3, [r0, #0x34]
	cmp r2, r3
	beq _00002152
	bx lr
_00002152:
	.2byte 0x1C5B @ adds r3, r3, #1
	str r3, [r0, #0x34]
	push {r4, r5, r6, r7, lr}
	mov r4, r8
	mov r5, sb
	mov r6, sl
	mov r7, fp
	push {r4, r5, r6, r7}
	adds r7, r0, #0
	ldr r3, [r7, #0x38]
	cmp r3, #0
	beq _00002170
	ldr r0, [r7, #0x3c]
	bl sub_00002102
_00002170:
	ldr r0, [r7, #4]
	cmp r0, #0
	bge _00002178
	b _00002392
_00002178:
	ldr r0, _000023A8 @=gUnknown_03007FF0
	ldr r0, [r0]
	mov r8, r0
	adds r0, r7, #0
	bl sub_00001534
	ldrh r0, [r7, #0x22]
	ldrh r1, [r7, #0x20]
	adds r0, r0, r1
	b _000022D6
_0000218C:
	ldrb r2, [r7, #8]
	ldr r5, [r7, #0x2c]
	movs r3, #1
	movs r4, #0
_00002194:
	ldrb r0, [r5]
	movs r1, #0x80
	tst r1, r0
	bne _0000219E
	b _000022B6
_0000219E:
	mov sb, r2
	mov sl, r3
	orrs r4, r3
	mov fp, r4
	ldr r4, [r5, #0x20]
	cmp r4, #0
	beq _000021D4
_000021AC:
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	beq _000021C8
	ldrb r0, [r4, #0x10]
	cmp r0, #0
	beq _000021CE
	.2byte 0x1E40 @ subs r0, r0, #1
	strb r0, [r4, #0x10]
	bne _000021CE
	movs r0, #0x40
	orrs r1, r0
	strb r1, [r4]
	b _000021CE
_000021C8:
	adds r0, r4, #0
	bl sub_000023C6
_000021CE:
	ldr r4, [r4, #0x34]
	cmp r4, #0
	bne _000021AC
_000021D4:
	ldrb r3, [r5]
	movs r0, #0x40
	tst r0, r3
	beq _00002254
	adds r0, r5, #0
	bl sub_000023B0
	movs r0, #0x80
	strb r0, [r5]
	movs r0, #2
	strb r0, [r5, #0xf]
	movs r0, #0x40
	strb r0, [r5, #0x13]
	movs r0, #0x16
	strb r0, [r5, #0x19]
	movs r0, #1
	adds r1, r5, #6
	strb r0, [r1, #0x1e]
	b _00002254
_000021FA:
	ldr r2, [r5, #0x40]
	ldrb r1, [r2]
	cmp r1, #0x80
	bhs _00002206
	ldrb r1, [r5, #7]
	b _00002210
_00002206:
	.2byte 0x1C52 @ adds r2, r2, #1
	str r2, [r5, #0x40]
	cmp r1, #0xbd
	bcc _00002210
	strb r1, [r5, #7]
_00002210:
	cmp r1, #0xcf
	bcc _00002226
	mov r0, r8
	ldr r3, [r0, #0x38]
	adds r0, r1, #0
	subs r0, #0xcf
	adds r1, r7, #0
	adds r2, r5, #0
	bl sub_00002102
	b _00002254
_00002226:
	cmp r1, #0xb0
	bls _0000224A
	adds r0, r1, #0
	subs r0, #0xb1
	strb r0, [r7, #0xa]
	mov r3, r8
	ldr r3, [r3, #0x34]
	lsls r0, r0, #2
	adds r3, r3, r0
	ldr r3, [r3]
	adds r0, r7, #0
	adds r1, r5, #0
	bl sub_00002102
	ldrb r0, [r5]
	cmp r0, #0
	beq _000022B0
	b _00002254
_0000224A:
	ldr r0, _000023A4 @=gUnknown_30D0
	subs r1, #0x80
	adds r1, r1, r0
	ldrb r0, [r1]
	strb r0, [r5, #1]
_00002254:
	ldrb r0, [r5, #1]
	cmp r0, #0
	beq _000021FA
	.2byte 0x1E40 @ subs r0, r0, #1
	strb r0, [r5, #1]
	ldrb r1, [r5, #0x19]
	cmp r1, #0
	beq _000022B0
	ldrb r0, [r5, #0x17]
	cmp r0, #0
	beq _000022B0
	ldrb r0, [r5, #0x1c]
	cmp r0, #0
	beq _00002276
	.2byte 0x1E40 @ subs r0, r0, #1
	strb r0, [r5, #0x1c]
	b _000022B0
_00002276:
	ldrb r0, [r5, #0x1a]
	adds r0, r0, r1
	strb r0, [r5, #0x1a]
	adds r1, r0, #0
	subs r0, #0x40
	lsls r0, r0, #0x18
	bpl _0000228A
	lsls r2, r1, #0x18
	asrs r2, r2, #0x18
	b _0000228E
_0000228A:
	movs r0, #0x80
	subs r2, r0, r1
_0000228E:
	ldrb r0, [r5, #0x17]
	muls r0, r2, r0
	asrs r2, r0, #6
	ldrb r0, [r5, #0x16]
	eors r0, r2
	lsls r0, r0, #0x18
	beq _000022B0
	strb r2, [r5, #0x16]
	ldrb r0, [r5]
	ldrb r1, [r5, #0x18]
	cmp r1, #0
	bne _000022AA
	movs r1, #0xc
	b _000022AC
_000022AA:
	movs r1, #3
_000022AC:
	orrs r0, r1
	strb r0, [r5]
_000022B0:
	mov r2, sb
	mov r3, sl
	mov r4, fp
_000022B6:
	.2byte 0x1E52 @ subs r2, r2, #1
	ble _000022C2
	movs r0, #0x50
	adds r5, r5, r0
	lsls r3, r3, #1
	b _00002194
_000022C2:
	mov r6, fp
	cmp r6, #0
	bne _000022D0
	movs r0, #0x80
	lsls r0, r0, #0x18
	str r0, [r7, #4]
	b _00002392
_000022D0:
	str r6, [r7, #4]
	ldrh r0, [r7, #0x22]
	subs r0, #0x96
_000022D6:
	strh r0, [r7, #0x22]
	cmp r0, #0x96
	bcc _000022DE
	b _0000218C
_000022DE:
	ldrb r2, [r7, #8]
	ldr r5, [r7, #0x2c]
_000022E2:
	ldrb r0, [r5]
	movs r1, #0x80
	tst r1, r0
	beq _00002388
	movs r1, #0xf
	tst r1, r0
	beq _00002388
	mov sb, r2
	adds r0, r7, #0
	adds r1, r5, #0
	bl sub_0000159C
	ldr r4, [r5, #0x20]
	cmp r4, #0
	beq _0000237E
_00002300:
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	bne _00002310
	adds r0, r4, #0
	bl sub_000023C6
	b _00002378
_00002310:
	ldrb r0, [r4, #1]
	movs r6, #7
	ands r6, r0
	ldrb r3, [r5]
	movs r0, #3
	tst r0, r3
	beq _0000233C
	ldrb r1, [r4, #0x12]
	ldrb r0, [r5, #0x10]
	muls r0, r1, r0
	asrs r0, r0, #7
	strb r0, [r4, #2]
	ldrb r0, [r5, #0x11]
	muls r0, r1, r0
	asrs r0, r0, #7
	strb r0, [r4, #3]
	cmp r6, #0
	beq _0000233C
	ldrb r0, [r4, #0x1d]
	movs r1, #1
	orrs r0, r1
	strb r0, [r4, #0x1d]
_0000233C:
	movs r0, #0xc
	tst r0, r3
	beq _00002378
	ldrb r1, [r4, #8]
	movs r0, #8
	ldrsb r0, [r5, r0]
	adds r2, r1, r0
	bpl _0000234E
	movs r2, #0
_0000234E:
	cmp r6, #0
	beq _0000236C
	mov r0, r8
	ldr r3, [r0, #0x30]
	adds r1, r2, #0
	ldrb r2, [r5, #9]
	adds r0, r6, #0
	bl sub_00002102
	str r0, [r4, #0x20]
	ldrb r0, [r4, #0x1d]
	movs r1, #2
	orrs r0, r1
	strb r0, [r4, #0x1d]
	b _00002378
_0000236C:
	adds r1, r2, #0
	ldrb r2, [r5, #9]
	ldr r0, [r4, #0x24]
	bl swi_MIDIKey2Freq
	str r0, [r4, #0x20]
_00002378:
	ldr r4, [r4, #0x34]
	cmp r4, #0
	bne _00002300
_0000237E:
	ldrb r0, [r5]
	movs r1, #0xf0
	ands r0, r1
	strb r0, [r5]
	mov r2, sb
_00002388:
	.2byte 0x1E52 @ subs r2, r2, #1
	ble _00002392
	movs r0, #0x50
	adds r5, r5, r0
	bgt _000022E2
_00002392:
	ldr r0, _000023AC @=0x68736D53
	str r0, [r7, #0x34]
	pop {r0, r1, r2, r3, r4, r5, r6, r7}
	mov r8, r0
	mov sb, r1
	mov sl, r2
	mov fp, r3
	pop {r0}
	bx r0
	.align 2, 0
_000023A4: .4byte gUnknown_30D0
_000023A8: .4byte gUnknown_03007FF0
_000023AC: .4byte 0x68736D53

	THUMB_FUNC_START sub_000023B0
sub_000023B0: @ 0x000023B0
	mov ip, r4
	movs r1, #0
	movs r2, #0
	movs r3, #0
	movs r4, #0
	stm r0!, {r1, r2, r3, r4}
	stm r0!, {r1, r2, r3, r4}
	stm r0!, {r1, r2, r3, r4}
	stm r0!, {r1, r2, r3, r4}
	mov r4, ip
	bx lr

	UNALIGNED_THUMB_FUNC_START sub_000023C6
sub_000023C6: @ 0x000023C6
	ldr r3, [r0, #0x2c]
	cmp r3, #0
	beq _000023E4
	ldr r1, [r0, #0x34]
	ldr r2, [r0, #0x30]
	cmp r2, #0
	beq _000023D8
	str r1, [r2, #0x34]
	b _000023DA
_000023D8:
	str r1, [r3, #0x20]
_000023DA:
	cmp r1, #0
	beq _000023E0
	str r2, [r1, #0x30]
_000023E0:
	movs r1, #0
	str r1, [r0, #0x2c]
_000023E4:
	bx lr

	UNALIGNED_THUMB_FUNC_START sub_000023E6
sub_000023E6: @ 0x000023E6
	push {r4, r5, r6, lr}
	adds r5, r1, #0
	ldrb r1, [r5]
	movs r0, #0x80
	tst r0, r1
	beq _0000241E
	ldr r4, [r5, #0x20]
	cmp r4, #0
	beq _0000241C
	movs r6, #0
_000023FA:
	ldrb r0, [r4]
	cmp r0, #0
	beq _00002416
	ldrb r0, [r4, #1]
	movs r3, #7
	ands r0, r3
	beq _00002412
	ldr r3, _00002620 @=gUnknown_03007FF0
	ldr r3, [r3]
	ldr r3, [r3, #0x2c]
	bl sub_00002102
_00002412:
	strb r6, [r4]
	str r6, [r4, #0x2c]
_00002416:
	ldr r4, [r4, #0x34]
	cmp r4, #0
	bne _000023FA
_0000241C:
	str r4, [r5, #0x20]
_0000241E:
	pop {r4, r5, r6}
	pop {r0}
	bx r0

	THUMB_FUNC_START sub_00002424
sub_00002424: @ 0x00002424
	push {r4, r5, r6, r7, lr}
	mov r4, r8
	mov r5, sb
	mov r6, sl
	mov r7, fp
	push {r4, r5, r6, r7}
	sub sp, #0x14
	str r1, [sp]
	adds r5, r2, #0
	ldr r1, _00002620 @=gUnknown_03007FF0
	ldr r1, [r1]
	str r1, [sp, #4]
	ldr r1, _00002624 @=gUnknown_30D0
	adds r0, r0, r1
	ldrb r0, [r0]
	strb r0, [r5, #4]
	ldr r3, [r5, #0x40]
	ldrb r0, [r3]
	cmp r0, #0x80
	bhs _0000246A
	strb r0, [r5, #5]
	.2byte 0x1C5B @ adds r3, r3, #1
	ldrb r0, [r3]
	cmp r0, #0x80
	bhs _00002468
	strb r0, [r5, #6]
	.2byte 0x1C5B @ adds r3, r3, #1
	ldrb r0, [r3]
	cmp r0, #0x80
	bhs _00002468
	ldrb r1, [r5, #4]
	adds r1, r1, r0
	strb r1, [r5, #4]
	.2byte 0x1C5B @ adds r3, r3, #1
_00002468:
	str r3, [r5, #0x40]
_0000246A:
	adds r4, r5, #0
	adds r4, #0x24
	ldrb r2, [r4]
	movs r0, #0xc0
	tst r0, r2
	beq _000024C0
	ldrb r3, [r5, #5]
	movs r0, #0x40
	tst r0, r2
	beq _00002486
	ldr r1, [r5, #0x2c]
	adds r1, r1, r3
	ldrb r0, [r1]
	b _00002488
_00002486:
	adds r0, r3, #0
_00002488:
	lsls r1, r0, #1
	adds r1, r1, r0
	lsls r1, r1, #2
	ldr r0, [r5, #0x28]
	adds r1, r1, r0
	mov sb, r1
	mov r6, sb
	ldrb r1, [r6]
	movs r0, #0xc0
	tst r0, r1
	beq _000024A0
	b _0000260E
_000024A0:
	movs r0, #0x80
	tst r0, r2
	beq _000024C4
	ldrb r1, [r6, #3]
	movs r0, #0x80
	tst r0, r1
	beq _000024BC
	subs r1, #0xc0
	lsls r1, r1, #1
	strb r1, [r5, #0x15]
	ldrb r0, [r5]
	movs r1, #3
	orrs r0, r1
	strb r0, [r5]
_000024BC:
	ldrb r3, [r6, #1]
	b _000024C4
_000024C0:
	mov sb, r4
	ldrb r3, [r5, #5]
_000024C4:
	str r3, [sp, #8]
	ldr r6, [sp]
	ldrb r1, [r6, #9]
	ldrb r0, [r5, #0x1d]
	adds r0, r0, r1
	cmp r0, #0xff
	bls _000024D4
	movs r0, #0xff
_000024D4:
	str r0, [sp, #0x10]
	mov r6, sb
	ldrb r0, [r6]
	movs r6, #7
	ands r6, r0
	str r6, [sp, #0xc]
	beq _00002514
	ldr r0, [sp, #4]
	ldr r4, [r0, #0x1c]
	cmp r4, #0
	bne _000024EC
	b _0000260E
_000024EC:
	.2byte 0x1E76 @ subs r6, r6, #1
	lsls r0, r6, #6
	adds r4, r4, r0
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	beq _00002568
	movs r0, #0x40
	tst r0, r1
	bne _00002568
	ldrb r1, [r4, #0x13]
	ldr r0, [sp, #0x10]
	cmp r1, r0
	bcc _00002568
	beq _0000250C
	b _0000260E
_0000250C:
	ldr r0, [r4, #0x2c]
	cmp r0, r5
	bhs _00002568
	b _0000260E
_00002514:
	ldr r6, [sp, #0x10]
	adds r7, r5, #0
	movs r2, #0
	mov r8, r2
	ldr r4, [sp, #4]
	ldrb r3, [r4, #6]
	adds r4, #0x50
_00002522:
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	beq _00002568
	movs r0, #0x40
	tst r0, r1
	beq _0000253C
	cmp r2, #0
	bne _00002540
	.2byte 0x1C52 @ adds r2, r2, #1
	ldrb r6, [r4, #0x13]
	ldr r7, [r4, #0x2c]
	b _0000255A
_0000253C:
	cmp r2, #0
	bne _0000255C
_00002540:
	ldrb r0, [r4, #0x13]
	cmp r0, r6
	bhs _0000254C
	adds r6, r0, #0
	ldr r7, [r4, #0x2c]
	b _0000255A
_0000254C:
	bhi _0000255C
	ldr r0, [r4, #0x2c]
	cmp r0, r7
	bls _00002558
	adds r7, r0, #0
	b _0000255A
_00002558:
	bcc _0000255C
_0000255A:
	mov r8, r4
_0000255C:
	adds r4, #0x40
	.2byte 0x1E5B @ subs r3, r3, #1
	bgt _00002522
	mov r4, r8
	cmp r4, #0
	beq _0000260E
_00002568:
	adds r0, r4, #0
	bl sub_000023C6
	movs r1, #0
	str r1, [r4, #0x30]
	ldr r3, [r5, #0x20]
	str r3, [r4, #0x34]
	cmp r3, #0
	beq _0000257C
	str r4, [r3, #0x30]
_0000257C:
	str r4, [r5, #0x20]
	str r5, [r4, #0x2c]
	ldrb r0, [r5, #0x1b]
	strb r0, [r5, #0x1c]
	cmp r0, r1
	beq _0000258C
	strb r1, [r5, #0x1a]
	strb r1, [r5, #0x16]
_0000258C:
	ldr r0, [sp]
	adds r1, r5, #0
	bl sub_0000159C
	ldr r0, [r5, #4]
	str r0, [r4, #0x10]
	ldr r0, [sp, #0x10]
	strb r0, [r4, #0x13]
	ldr r0, [sp, #8]
	strb r0, [r4, #8]
	mov r6, sb
	ldrb r0, [r6]
	strb r0, [r4, #1]
	ldr r7, [r6, #4]
	str r7, [r4, #0x24]
	ldr r0, [r6, #8]
	str r0, [r4, #4]
	ldrh r0, [r5, #0x1e]
	strh r0, [r4, #0xc]
	ldrb r1, [r4, #0x12]
	ldrb r0, [r5, #0x10]
	muls r0, r1, r0
	asrs r0, r0, #7
	strb r0, [r4, #2]
	ldrb r0, [r5, #0x11]
	muls r0, r1, r0
	asrs r0, r0, #7
	strb r0, [r4, #3]
	ldrb r1, [r4, #8]
	movs r0, #8
	ldrsb r0, [r5, r0]
	adds r3, r1, r0
	bpl _000025D0
	movs r3, #0
_000025D0:
	ldr r6, [sp, #0xc]
	cmp r6, #0
	beq _000025F6
	mov r6, sb
	ldrb r0, [r6, #2]
	strb r0, [r4, #0x1e]
	ldrb r1, [r6, #3]
	movs r0, #0x80
	tst r0, r1
	bne _000025E6
	strb r1, [r4, #0x1f]
_000025E6:
	ldrb r2, [r5, #9]
	adds r1, r3, #0
	ldr r0, [sp, #0xc]
	ldr r3, [sp, #4]
	ldr r3, [r3, #0x30]
	bl sub_00002102
	b _00002600
_000025F6:
	ldrb r2, [r5, #9]
	adds r1, r3, #0
	adds r0, r7, #0
	bl swi_MIDIKey2Freq
_00002600:
	str r0, [r4, #0x20]
	movs r0, #0x80
	strb r0, [r4]
	ldrb r1, [r5]
	movs r0, #0xf0
	ands r0, r1
	strb r0, [r5]
_0000260E:
	add sp, #0x14
	pop {r0, r1, r2, r3, r4, r5, r6, r7}
	mov r8, r0
	mov sb, r1
	mov sl, r2
	mov fp, r3
	pop {r0}
	bx r0
	.align 2, 0
_00002620: .4byte gUnknown_03007FF0
_00002624: .4byte gUnknown_30D0

	THUMB_FUNC_START sub_00002628
sub_00002628: @ 0x00002628
	push {r4, lr}
	ldr r2, [r1, #0x40]
	ldrb r3, [r2]
	cmp r3, #0x80
	bhs _0000263A
	strb r3, [r1, #5]
	.2byte 0x1C52 @ adds r2, r2, #1
	str r2, [r1, #0x40]
	b _0000263C
_0000263A:
	ldrb r3, [r1, #5]
_0000263C:
	ldr r1, [r1, #0x20]
	cmp r1, #0
	beq _0000265E
	movs r4, #0x83
_00002644:
	ldrb r2, [r1]
	tst r2, r4
	beq _00002658
	ldrb r0, [r1, #0x11]
	cmp r0, r3
	bne _00002658
	movs r0, #0x40
	orrs r2, r0
	strb r2, [r1]
	b _0000265E
_00002658:
	ldr r1, [r1, #0x34]
	cmp r1, #0
	bne _00002644
_0000265E:
	pop {r4}
	pop {r0}
	bx r0

	THUMB_FUNC_START sub_00002664
sub_00002664:
	push {r4, r5, lr}
	adds r5, r1, #0
	ldr r4, [r5, #0x20]
	cmp r4, #0
	beq _00002688
_0000266E:
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	beq _0000267C
	movs r0, #0x40
	orrs r1, r0
	strb r1, [r4]
_0000267C:
	adds r0, r4, #0
	bl sub_000023C6
	ldr r4, [r4, #0x34]
	cmp r4, #0
	bne _0000266E
_00002688:
	movs r0, #0
	strb r0, [r5]
	pop {r4, r5}
	pop {r0}
	bx r0

	UNALIGNED_THUMB_FUNC_START swi_GetJumpList
swi_GetJumpList: @ 0x00002692
	mov ip, lr
	movs r1, #0x24
	ldr r2, _000026C0 @=gUnknown_3738
_00002698:
	ldr r3, [r2]
	bl sub_000026AA
	stm r0!, {r3}
	.2byte 0x1D12 @ adds r2, r2, #4
	.2byte 0x1E49 @ subs r1, r1, #1
	bgt _00002698
	bx ip

	THUMB_FUNC_START sub_000026A8
sub_000026A8: @ 0x000026A8
	ldrb r3, [r2]
sub_000026AA:
	push {r0}
	lsrs r0, r2, #0x19
	bne _000026BC
	ldr r0, _000026C0 @=gUnknown_3738
	cmp r2, r0
	bcc _000026BA
	lsrs r0, r2, #0xe
	beq _000026BC
_000026BA:
	movs r3, #0
_000026BC:
	pop {r0}
	bx lr
	.align 2, 0
_000026C0: .4byte gUnknown_3738

	THUMB_FUNC_START sub_000026C4
sub_000026C4: @ 0x000026C4
	ldr r2, [r1, #0x40]

	UNALIGNED_THUMB_FUNC_START sub_000026C6
sub_000026C6: @ 0x000026C6
	adds r3, r2, #1
	str r3, [r1, #0x40]
	ldrb r3, [r2]
	b sub_000026AA

	UNALIGNED_THUMB_FUNC_START sub_000026CE
sub_000026CE:
	push {lr}
_000026D0:
	ldr r2, [r1, #0x40]
	ldrb r0, [r2, #3]
	lsls r0, r0, #8
	ldrb r3, [r2, #2]
	orrs r0, r3
	lsls r0, r0, #8
	ldrb r3, [r2, #1]
	orrs r0, r3
	lsls r0, r0, #8
	bl sub_000026A8
	orrs r0, r3
	str r0, [r1, #0x40]
	pop {r0}
	bx r0

	UNALIGNED_THUMB_FUNC_START sub_000026EE
sub_000026EE: @ 0x000026EE
	ldrb r2, [r1, #2]
	cmp r2, #3
	bhs _00002706
	lsls r2, r2, #2
	adds r3, r1, r2
	ldr r2, [r1, #0x40]
	.2byte 0x1D12 @ adds r2, r2, #4
	str r2, [r3, #0x44]
	ldrb r2, [r1, #2]
	.2byte 0x1C52 @ adds r2, r2, #1
	strb r2, [r1, #2]
	b sub_000026CE
_00002706:
	b sub_00002664

	THUMB_FUNC_START _00002708
sub_00002708: @ 0x00002708
	ldrb r2, [r1, #2]
	cmp r2, #0
	beq _0000271A
	.2byte 0x1E52 @ subs r2, r2, #1
	strb r2, [r1, #2]
	lsls r2, r2, #2
	adds r3, r1, r2
	ldr r2, [r3, #0x44]
	str r2, [r1, #0x40]
_0000271A:
	bx lr

	THUMB_FUNC_START sub_0000271C
sub_0000271C: @ 0x0000271C
	push {lr}
	ldr r2, [r1, #0x40]
	ldrb r3, [r2]
	cmp r3, #0
	bne _0000272C
	.2byte 0x1C52 @ adds r2, r2, #1
	str r2, [r1, #0x40]
	b _000026D0
_0000272C:
	ldrb r3, [r1, #3]
	.2byte 0x1C5B @ adds r3, r3, #1
	strb r3, [r1, #3]
	mov ip, r3
	bl sub_000026C4
	cmp ip, r3
	bhs _0000273E
	b _000026D0
_0000273E:
	movs r3, #0
	strb r3, [r1, #3]
	.2byte 0x1D52 @ adds r2, r2, #5
	str r2, [r1, #0x40]
	pop {r0}
	bx r0

	UNALIGNED_THUMB_FUNC_START sub_0000274A
sub_0000274A: @ 0x0000274A
	mov ip, lr
	bl sub_000026C4
	strb r3, [r1, #0x1d]
	bx ip

	THUMB_FUNC_START sub_00002754
sub_00002754: @ 0x00002754
	mov ip, lr
	bl sub_000026C4
	lsls r3, r3, #1
	strh r3, [r0, #0x1c]
	ldrh r2, [r0, #0x1e]
	muls r3, r2, r3
	lsrs r3, r3, #8
	strh r3, [r0, #0x20]
	bx ip

	THUMB_FUNC_START sub_00002768
sub_00002768: @ 0x00002768
	mov ip, lr
	bl sub_000026C4
	strb r3, [r1, #0xa]
	ldrb r3, [r1]
	movs r2, #0xc
	orrs r3, r2
	strb r3, [r1]
	bx ip

	UNALIGNED_THUMB_FUNC_START sub_0000277A
sub_0000277A: @ 0x0000277A
	mov ip, lr
	ldr r2, [r1, #0x40]
	ldrb r3, [r2]
	.2byte 0x1C52 @ adds r2, r2, #1
	str r2, [r1, #0x40]
	lsls r2, r3, #1
	adds r2, r2, r3
	lsls r2, r2, #2
	ldr r3, [r0, #0x30]
	adds r2, r2, r3
	ldr r3, [r2]
	bl sub_000026AA
	str r3, [r1, #0x24]
	ldr r3, [r2, #4]
	bl sub_000026AA
	str r3, [r1, #0x28]
	ldr r3, [r2, #8]
	bl sub_000026AA
	str r3, [r1, #0x2c]
	bx ip

	THUMB_FUNC_START sub_000027A8
sub_000027A8: @ 0x000027A8
	mov ip, lr
	bl sub_000026C4
	strb r3, [r1, #0x12]
	ldrb r3, [r1]
	movs r2, #3
	orrs r3, r2
	strb r3, [r1]
	bx ip

	UNALIGNED_THUMB_FUNC_START sub_000027BA
sub_000027BA: @ 0x000027BA
	mov ip, lr
	bl sub_000026C4
	subs r3, #0x40
	strb r3, [r1, #0x14]
	ldrb r3, [r1]
	movs r2, #3
	orrs r3, r2
	strb r3, [r1]
	bx ip

	UNALIGNED_THUMB_FUNC_START sub_000027CE
sub_000027CE: @ 0x000027CE
	mov ip, lr
	bl sub_000026C4
	subs r3, #0x40
	strb r3, [r1, #0xe]
	ldrb r3, [r1]
	movs r2, #0xc
	orrs r3, r2
	strb r3, [r1]
	bx ip

	UNALIGNED_THUMB_FUNC_START sub_000027E2
sub_000027E2: @ 0x000027E2
	mov ip, lr
	bl sub_000026C4
	strb r3, [r1, #0xf]
	ldrb r3, [r1]
	movs r2, #0xc
	orrs r3, r2
	strb r3, [r1]
	bx ip

	THUMB_FUNC_START sub_000027F4
sub_000027F4: @ 0x000027F4
	mov ip, lr
	bl sub_000026C4
	strb r3, [r1, #0x19]
	cmp r3, #0
	bne _00002802
	strb r3, [r1, #0x16]
_00002802:
	bx ip

	THUMB_FUNC_START sub_00002804
sub_00002804: @ 0x00002804
	mov ip, lr
	bl sub_000026C4
	strb r3, [r1, #0x1b]
	bx ip

	UNALIGNED_THUMB_FUNC_START sub_0000280E
sub_0000280E: @ 0x0000280E
	mov ip, lr
	bl sub_000026C4
	strb r3, [r1, #0x17]
	cmp r3, #0
	bne _0000281C
	strb r3, [r1, #0x16]
_0000281C:
	bx ip

	UNALIGNED_THUMB_FUNC_START sub_0000281E
sub_0000281E: @ 0x0000281E
	mov ip, lr
	bl sub_000026C4
	ldrb r0, [r1, #0x18]
	cmp r0, r3
	beq _00002834
	strb r3, [r1, #0x18]
	ldrb r3, [r1]
	movs r2, #0xf
	orrs r3, r2
	strb r3, [r1]
_00002834:
	bx ip

	UNALIGNED_THUMB_FUNC_START sub_00002836
sub_00002836: @ 0x00002836
	mov ip, lr
	bl sub_000026C4
	subs r3, #0x40
	strb r3, [r1, #0xc]
	ldrb r3, [r1]
	movs r2, #0xc
	orrs r3, r2
	strb r3, [r1]
	bx ip

	UNALIGNED_THUMB_FUNC_START sub_0000284A
sub_0000284A: @ 0x0000284A
	mov ip, lr
	ldr r2, [r1, #0x40]
	ldrb r3, [r2]
	.2byte 0x1C52 @ adds r2, r2, #1
	ldr r0, _00002860 @=REG_SOUND1CNT
	adds r0, r0, r3
	bl sub_000026C6
	strb r3, [r0]
	bx ip

	UNALIGNED_THUMB_FUNC_START sub_0000285E
sub_0000285E: @ 0x0000285E
	movs r0, r0
	.align 2, 0
_00002860: .4byte REG_SOUND1CNT

	THUMB_FUNC_START sub_00002864
sub_00002864: @ 0x00002864
	movs r6, #0x20
_00002866:
	adds r1, r5, #0
	eors r1, r2
	lsrs r5, r5, #1
	lsrs r1, r1, #1
	bcc _00002872
	eors r5, r0
_00002872:
	lsrs r2, r2, #1
	.2byte 0x1E76 @ subs r6, r6, #1
	bne _00002866
	bx lr

	UNALIGNED_THUMB_FUNC_START sub_0000287A
sub_0000287A: @ 0x0000287A
	push {r2, r4, r6, lr}
	mov ip, r1
	str r3, [r7, #0x54]
	ldr r3, [r7, #0x44]
	ldr r1, [r7, #0x38]
	subs r1, r1, r3
	asrs r1, r1, #2
	ble _000028BA
	cmp r1, #0x89
	ble _00002890
	movs r1, #0x89
_00002890:
	ldr r4, [r7, #4]
	ldrh r5, [r7, #0x20]
_00002894:
	str r1, [r7, #0x50]
	mov r1, ip
	muls r4, r1, r4
	.2byte 0x1C64 @ adds r4, r4, #1
	ldr r2, [r3]
	eors r2, r4
	negs r1, r3
	eors r2, r1
	ldr r1, [r7, #0x54]
	eors r2, r1
	stm r3!, {r2}
	strh r5, [r7, #0x22]
	bl sub_00002864
	ldr r1, [r7, #0x50]
	.2byte 0x1E49 @ subs r1, r1, #1
	bne _00002894
	strh r5, [r7, #0x20]
	str r4, [r7, #4]
_000028BA:
	pop {r2, r4, r6, pc}

	THUMB_FUNC_START sub_000028BC
sub_000028BC: @ 0x000028BC
	push {lr}
	bl sub_00002AA6
	pop {r1}
	mov lr, r1
_000028C6:
	ldrh r1, [r6, #8]
	lsrs r1, r1, #8
	bhs _000028C6
	bx lr

	UNALIGNED_THUMB_FUNC_START swi_MultiBoot
swi_MultiBoot: @ 0x000028CE
	push {r1, r3, r4, r5, r6, r7, lr}
	movs r3, #0xdf
	add r2, pc, #sub_00002C00 - . - 2
	bl sub_00002AA4
	adds r7, r0, #0
	movs r4, #0xff
	bl CheckDestInWritableRange_t
	beq _0000296E
	lsrs r4, r7, #0x14
	movs r3, #0xe8
	ands r3, r4
	cmp r3, #0x20
	bne _0000296E
	movs r4, #0
	cmp r1, #1
	beq _000028FA
	cmp r1, #2
	bgt _0000296E
	ldr r4, _00002C18 @=0xC3871089
	orrs r4, r1
_000028FA:
	strh r4, [r7, #0x3a]
	ldr r0, [r7, #0x20]
	str r0, [r7, #0x10]
	ldr r4, [r7, #0x24]
	subs r4, r4, r0
	ldr r3, _00002C08 @=0x0003FFF8
	ands r4, r3
	str r4, [r7, #0xc]
	bl CheckDestInWritableRange_t
	beq _0000296E
	ldr r4, _00002C0C @=REG_DMA0
	ldrh r0, [r4, #0xa]
	ldrh r2, [r4, #0x16]
	orrs r0, r2
	ldrh r2, [r4, #0x22]
	orrs r0, r2
	ldrh r2, [r4, #0x2e]
	orrs r0, r2
	lsrs r0, r0, #0x10
	bhs _0000296E
	ldr r6, _00002C10 @=REG_SIOMULTI0
	ldrb r0, [r7, #0x1e]
	lsls r0, r0, #0x1c
	lsrs r0, r0, #0x1d
	ldrh r1, [r6]
	ldrh r2, [r7, #0x3a]
	cmp r2, #0
	beq _0000293A
	lsls r0, r0, #0x1f
	lsrs r0, r0, #0x1f
	ldrb r1, [r7, #0x14]
_0000293A:
	strb r0, [r7, #8]
	strb r1, [r7, #4]
	ldr r3, _00002C18 @=0xC3871089
	lsrs r3, r3, #0x10
	ldr r1, _00002D2C @=0x0000C37B
	cmp r2, #0
	ldr r4, _00002D34 @=0x43202F2F
	bne _00002950
	ldr r1, _00002D30 @=0x0000A517
	ldr r3, _00002C08 @=0x0003FFF8
	ldr r4, _00002D38 @=0x6465646F
_00002950:
	strh r1, [r7, #0x3e]
	strh r3, [r7, #0x38]
	str r4, [r7, #0x40]
	ldr r1, [r7, #0x18]
	str r1, [r7]
	ldrb r1, [r7, #0x1c]
	strb r1, [r7]
	adds r4, r6, #0
_00002960:
	lsrs r0, r0, #1
	bcc _00002970
	ldrb r1, [r4, #3]
	cmp r1, #0x73
	bne _0000296E
_0000296A:
	.2byte 0x1CA4 @ adds r4, r4, #2
	b _00002960
_0000296E:
	b _00002A8E
_00002970:
	bne _0000296A
	ldr r5, [r7, #0xc]
	lsrs r0, r5, #2
	subs r0, #0x34
	ldr r1, [r7, #0x10]
	adds r1, r1, r5
	str r1, [r7, #0xc]
	ldr r1, _00002C08 @=0x0003FFF8
_00002980:
	.2byte 0x1E49 @ subs r1, r1, #1
	bne _00002980
	bl sub_000028BC
	ldrh r1, [r6, #2]
	strb r1, [r7, #5]
	ldrh r1, [r6, #4]
	ldrh r2, [r6, #6]
	ldrh r3, [r7, #0x3a]
	cmp r3, #0
	beq _0000299A
	movs r1, #0xff
	movs r2, #0xff
_0000299A:
	strb r1, [r7, #6]
	strb r2, [r7, #7]
	movs r4, #2
	mov ip, r4
	ldr r3, [r7, #0x10]
_000029A4:
	ldr r1, [r7, #0x20]
	subs r1, r1, r3
	lsrs r1, r1, #2
	ldrh r0, [r7, #0x3c]
	bhs _000029DE
	ldr r2, [r3]
	ldrh r0, [r7, #0x3e]
	ldrh r5, [r7, #0x38]
	bl sub_00002864
	strh r5, [r7, #0x38]
	ldr r1, [r7]
	ldr r0, _00002D44 @=0x6F646573
	muls r1, r0, r1
	.2byte 0x1C49 @ adds r1, r1, #1
	str r1, [r7]
	ldr r0, [r3]
	eors r0, r1
	ldr r1, [r7, #0x20]
	subs r2, r3, r1
	ldr r1, _00002D94 @=gUnknown_020000C0
	adds r2, r2, r1
	negs r1, r2
	ldr r2, [r7, #0x40]
	eors r1, r2
	eors r0, r1
	lsrs r2, r0, #0x10
	strh r2, [r7, #0x3c]
	ldr r6, _00002C10 @=REG_SIOMULTI0
_000029DE:
	bl _000028C6
	ldr r1, [r7, #0x20]
	cmp r1, r3
	beq _00002A1A
	mov lr, r4
	subs r4, r3, r1
	.2byte 0x1EA4 @ subs r4, r4, #2
	ldrh r1, [r7, #0x3a]
	cmp r1, #0
	beq _000029F6
	.2byte 0x1EA4 @ subs r4, r4, #2
_000029F6:
	ldr r1, _00002D94 @=gUnknown_020000C0
	adds r4, r4, r1
_000029FA:
	ldrb r2, [r7, #8]
	adds r5, r6, #0
_000029FE:
	lsrs r2, r2, #1
	bcc _00002A0E
	ldrh r1, [r5, #2]
	eors r1, r4
	lsls r1, r1, #0x10
	bne _00002A8E
_00002A0A:
	.2byte 0x1CAD @ adds r5, r5, #2
	b _000029FE
_00002A0E:
	bne _00002A0A
	mov r4, lr
	cmp r2, ip
	bne _00002A1A
	movs r0, #0
	b _00002A90
_00002A1A:
	bl sub_00002AA6
	cmp r4, #0
	beq _00002A3C
	.2byte 0x1C9B @ adds r3, r3, #2
	ldrh r1, [r7, #0x3a]
	cmp r1, #0
	beq _00002A2C
	.2byte 0x1C9B @ adds r3, r3, #2
_00002A2C:
	cmp r4, #2
	bne _00002A36
	ldr r1, [r7, #0xc]
	cmp r1, r3
	bne _000029A4
_00002A36:
	movs r0, #0x65
	.2byte 0x1E64 @ subs r4, r4, #1
	b _000029DE
_00002A3C:
	movs r4, #1
	bl _000028C6
	ldrb r2, [r7, #8]
	adds r3, r6, #0
_00002A46:
	lsrs r2, r2, #1
	bcc _00002A5E
	ldrh r1, [r3, #2]
	cmp r1, #0x75
	beq _00002A5A
	cmp r0, #0x65
	bne _00002A8E
	cmp r1, #0x74
	bne _00002A8E
	movs r4, #0
_00002A5A:
	.2byte 0x1C9B @ adds r3, r3, #2
	b _00002A46
_00002A5E:
	bne _00002A5A
	cmp r0, #0x66
	beq _00002A70
	cmp r4, #0
	beq _00002A6A
	movs r0, #0x66
_00002A6A:
	bl sub_00002AA6
	b _00002A3C
_00002A70:
	cmp r4, #0
	beq _00002A8E
	ldrh r0, [r7, #0x3e]
	ldrh r5, [r7, #0x38]
	ldr r2, [r7, #4]
	bl sub_00002864
	ldr r6, _00002C10 @=REG_SIOMULTI0
	adds r0, r5, #0
	bl sub_000028BC
	movs r1, #0
	mov ip, r1
	adds r4, r0, #0
	b _000029FA
_00002A8E:
	movs r0, #1
_00002A90:
	str r0, [r7, #0x38]
	str r0, [r7, #0x3c]
	str r0, [r7, #0x40]
	adds r1, r7, #0
	adds r1, #0x14
_00002A9A:
	stm r7!, {r0}
	cmp r1, r7
	bne _00002A9A
	pop {r1, r3, r4, r5, r6, r7}
	pop {r2}

	THUMB_FUNC_START sub_00002AA4
sub_00002AA4: @ 0x00002AA4
	bx r2

	UNALIGNED_THUMB_FUNC_START sub_00002AA6
sub_00002AA6: @ 0x00002AA6
	movs r1, #0x96
_00002AA8:
	.2byte 0x1E49 @ subs r1, r1, #1
	bne _00002AA8
	str r0, [r6]
	strh r0, [r6, #0xa]
	ldrh r1, [r7, #0x3a]
	cmp r1, #0
	bne _00002AB8
	ldr r1, _00002D98 @=0xA1C12083
_00002AB8:
	strh r1, [r6, #8]
	bx lr

	THUMB_FUNC_START sub_00002ABC
sub_00002ABC: @ 0x00002ABC
	push {lr}
	ldr r0, _00002D9C @=gUnknown_03007FF0 + 0xB
	ldrb r1, [r0]
	cmp r1, #1
	bne _00002AE4
	ldrb r0, [r7, #0xa]
	lsls r0, r0, #0x19
	bcc _00002AE4
	ldrb r0, [r7, #0x12]
	ldrb r1, [r7, #0x13]
	orrs r0, r1
	bne _00002AE8
	ldr r0, [r7, #0x38]
	ldr r1, _00002D94 @=gUnknown_020000C0
	subs r1, r1, r0
	bge _00002AE4
	movs r0, #0x78
	strb r0, [r7, #0x12]
	ldr r0, _00002D48 @=gUnknown_02000000
	b _00003038
_00002AE4:
	movs r0, #0
	pop {pc}
_00002AE8:
	ldr r2, [r7, #8]
	lsls r1, r2, #0xd
	lsrs r1, r1, #0x1e
	ldrb r0, [r7, #0x14]
_00002AF0:
	.2byte 0x1CC0 @ adds r0, r0, #3
	.2byte 0x1E49 @ subs r1, r1, #1
	bpl _00002AF0
	strb r0, [r7, #0x14]
	lsrs r0, r0, #2
	lsls r1, r0, #0x1a
	lsls r2, r2, #0xc
	eors r1, r2
	asrs r1, r1, #0x1f
	eors r0, r1
	movs r1, #0x1f
	ands r1, r0
	ldr r2, [r7, #8]
	lsls r0, r2, #9
	lsrs r0, r0, #0x1d
	cmp r0, #7
	blt _00002B1E
	movs r1, #0
	lsls r0, r2, #0xc
	lsrs r0, r0, #0x1d
	cmp r0, #7
	blt _00002B1E
	movs r0, #0
_00002B1E:
	movs r2, #0x1f
	bl sub_000007BC
	ldrb r0, [r7, #0x12]
	.2byte 0x1E40 @ subs r0, r0, #1
	blt _00002B2E
	strb r0, [r7, #0x12]
	bne _00002AE4
_00002B2E:
	movs r0, #5
	strb r0, [r7, #0x13]
	pop {pc}

	THUMB_FUNC_START sub_00002B34
sub_00002B34: @ 0x00002B34
	push {r4, r5, r6, r7}
	push {lr}
	ldr r7, _00002DA0 @=gUnknown_0300000C
	ldr r4, _00002C10 @=REG_SIOMULTI0
	ldr r0, [r7, #0x4c]
	ldr r1, _00002D40 @=0x6177614B
	muls r0, r1, r0
	.2byte 0x1C40 @ adds r0, r0, #1
	str r0, [r7, #0x4c]
	b _0000304A
_00002B48:
	ldr r0, [r7, #0x4c]
	movs r1, #0xe0
	bics r0, r1
	movs r1, #0xa0
	eors r0, r1
	movs r3, #0x80
	lsls r3, r3, #8
	bics r0, r3
	ldr r1, _00002D9C @=gUnknown_03007FF0 + 0xB
	ldrb r2, [r1]
	cmp r2, #1
	beq _00002B68
	ldr r1, _00002C1C @=gUnknown_03000064
	ldr r2, [r1, #0x24]
	.2byte 0x1C52 @ adds r2, r2, #1
	bne _00002B6A
_00002B68:
	orrs r0, r3
_00002B6A:
	str r0, [r7]
	ldrb r5, [r7, #0xf]
	ldrb r6, [r7, #0xe]
	ldrb r0, [r7, #0xd]
	cmp r0, #0
	bne _00002BAE
	bl sub_00002D5C
	ldrb r3, [r7, #0xc]
	ldrh r0, [r4, #0x10]
	cmp r6, #2
	bne _00002B8C
	.2byte 0x1E5B @ subs r3, r3, #1
	bpl _00002BA8
_00002B86:
	movs r6, #0
	movs r3, #6
	b _00002BA2
_00002B8C:
	cmp r6, #1
	bne _00002B9A
	.2byte 0x1E5B @ subs r3, r3, #1
	bpl _00002BA8
_00002B94:
	movs r6, #2
	movs r3, #6
	b _00002BA2
_00002B9A:
	.2byte 0x1E5B @ subs r3, r3, #1
	bpl _00002BA8
_00002B9E:
	movs r6, #1
	movs r3, #0x1e
_00002BA2:
	ldr r1, _00002C14 @=sub_0000301C
	str r1, [r7, #0x34]
	movs r5, #0
_00002BA8:
	strb r3, [r7, #0xc]
	bl sub_00002D64
_00002BAE:
	cmp r5, #0
	bne sub_00002C20
	str r5, [r7, #0x10]
	strb r5, [r7, #0xa]
	ldr r2, _00002D48 @=gUnknown_02000000
	str r2, [r7, #0x38]
	ldr r2, _00002D94 @=gUnknown_020000C0
	str r2, [r7, #0x3c]
	str r2, [r7, #0x44]
	movs r2, #1
	strb r2, [r7, #0xf]
	strb r6, [r7, #0xe]
	cmp r6, #0
	bne _00002BE2
	movs r2, #0xc0
	lsls r2, r2, #8
	strh r2, [r4, #0x14]
	ldr r1, [r4, #0x30]
	str r5, [r4, #0x34]
	strh r5, [r4, #0x38]
	movs r1, #7
	strh r1, [r4, #0x20]
	movs r1, #0xad
	lsls r1, r1, #5
_00002BDE:
	strh r1, [r7, #0x20]
	b _00002D56
_00002BE2:
	cmp r6, #1
	bne _00002BF4
	strh r5, [r4, #0x14]
	ldr r2, _00002D4C @=0x60032003
	ldr r1, _00002C08 @=0x0003FFF8
_00002BEC:
	strh r2, [r4, #8]
	strh r5, [r4, #0xa]
	str r5, [r4]
	b _00002BDE
_00002BF4:
	strh r5, [r4, #0x14]
	ldr r2, _00002F60 @=0x10085088
	lsrs r2, r2, #0x10
	ldr r1, _00002C18 @=0xC3871089
	lsrs r1, r1, #0x10
	b _00002BEC

	ARM_FUNC_START sub_00002C00
sub_00002C00: @ 0x00002C00
	msr cpsr_fc, r3
	bx lr
	.align 2, 0
_00002C08: .4byte 0x0003FFF8
_00002C0C: .4byte REG_DMA0
_00002C10: .4byte REG_SIOMULTI0
_00002C14: .4byte sub_0000301C
_00002C18: .4byte 0xC3871089
_00002C1C: .4byte gUnknown_03000064

	THUMB_FUNC_START sub_00002C20
sub_00002C20:
	cmp r5, #1
	bne _00002C58
	bl sub_00002D5C
	movs r1, #0x80
	strh r1, [r3, #2]
	ldrh r2, [r3]
	orrs r2, r1
	strh r2, [r3]
	strh r5, [r3, #8]
	cmp r6, #0
	bne _00002C44
	movs r1, #0x47
	strh r1, [r4, #0x20]
	add r2, pc, #0x324
	b _00002C50
_00002C40:
	ldr r1, _00002F60 @=0x10085088
	b _00002C4C
_00002C44:
	cmp r6, #1
	bne _00002C40
	ldr r1, _00002D4C @=0x60032003
	lsrs r1, r1, #0x10
_00002C4C:
	strh r1, [r4, #8]
	add r2, pc, #0x154
_00002C50:
	movs r1, #2
	strb r1, [r7, #0xf]
	str r2, [r7, #0x34]
	b _00002D56
_00002C58:
	cmp r5, #2
	bne _00002C5E
	b _00002D56
_00002C5E:
	bl sub_00002ABC
	cmp r5, #3
	beq _00002C6C
	cmp r0, #0
	beq _00002D56
	b _00002D58
_00002C6C:
	bl sub_00002D5C
	ldr r0, [r7, #0x30]
	.2byte 0x1E40 @ subs r0, r0, #1
	bpl _00002C8A
	cmp r6, #0
	bne _00002C84
	ldrh r1, [r4, #0x38]
	movs r2, #0x30
	ands r1, r2
	beq _00002C8C
	b _00002B86
_00002C84:
	cmp r6, #1
	bne _00002B94
	b _00002B9E
_00002C8A:
	str r0, [r7, #0x30]
_00002C8C:
	movs r0, #1
	strh r0, [r3, #8]
	ldrb r0, [r7, #0x11]
	cmp r0, #0
	bne _00002D50
	cmp r6, #0
	bne _00002CEE
	ldr r0, _00002D98 @=0xA1C12083
	lsrs r0, r0, #0x10
	ldr r1, _00003080 @=0x6177614B
	ldr r3, _00002D3C @=0x20796220
	bl sub_0000287A
	str r3, [r7, #0x44]
	ldr r1, [r7, #0x3c]
	cmp r3, r1
	bne _00002D56
	ldr r0, [r7, #0x38]
	eors r0, r3
	bne _00002D56
	.2byte 0x1F09 @ subs r1, r1, #4
	ldrh r2, [r1]
	ldrh r3, [r7, #0x22]
	cmp r3, r2
	bne _00002CE8
	str r0, [r1]
	ldr r1, [r7, #8]
	ldr r2, _0000309C @=0x80808080
	ands r1, r2
	cmp r1, r2
	bne _00002CE8
	ldrb r1, [r7, #0xa]
	ldrb r2, [r7, #8]
	adds r1, r1, r2
	ldrb r2, [r7, #9]
	adds r1, r1, r2
	ldrb r2, [r7, #0xb]
	subs r1, r1, r2
	lsls r1, r1, #0x19
	bne _00002CE8
	ldr r0, _000030A0 @=0xEA000036
	movs r1, #1
	bl sub_0000301E
	cmp r0, #0
	beq _00002D50
_00002CE8:
	movs r0, #0
	strb r0, [r7, #0xf]
	b _00002D56
_00002CEE:
	ldr r2, [r7, #0x3c]
	ldr r3, [r7, #0x44]
	cmp r3, r2
	beq _00002D56
	ldr r0, _00002D30 @=0x0000A517
	ldr r3, _00002D38 @=0x6465646F
	cmp r6, #2
	bne _00002D02
	ldr r0, _00002D2C @=0x0000C37B
	ldr r3, _00002D34 @=0x43202F2F
_00002D02:
	ldr r1, _00002D44 @=0x6F646573
	bl sub_0000287A
	cmp r2, r3
	bne _00002D26
	ldr r2, [r7, #0x1c]
	bl sub_00002864
	strh r5, [r7, #0x20]
	ldr r0, _000030A4 @=0xEA00002E
	movs r1, #4
	ldrb r6, [r7, #0xe]
	subs r1, r1, r6
	bl sub_0000301E
	cmp r0, #0
	bne _00002CE8
	ldr r3, [r7, #0x3c]
_00002D26:
	str r3, [r7, #0x44]
	b _00002D56
	.align 2, 0
_00002D2C: .4byte 0x0000C37B
_00002D30: .4byte 0x0000A517
_00002D34: .4byte 0x43202F2F
_00002D38: .4byte 0x6465646F
_00002D3C: .4byte 0x20796220
_00002D40: .4byte 0x6177614B
_00002D44: .4byte 0x6F646573
_00002D48: .4byte gUnknown_02000000
_00002D4C: .4byte 0x60032003
_00002D50:
	movs r0, #4
	strb r0, [r7, #0x11]
	strb r0, [r7, #0xf]
_00002D56:
	movs r0, #0
_00002D58:
	pop {r3, r4, r5, r6, r7}
	bx r3

	THUMB_FUNC_START sub_00002D5C
sub_00002D5C: @ 0x00002D5C
	movs r0, #0
_00002D5E:
	ldr r3, _00003088 @=REG_IE
	strh r0, [r3, #8]
	bx lr

	THUMB_FUNC_START sub_00002D64
sub_00002D64: @ 0x00002D64
	movs r0, #1
	b _00002D5E

	THUMB_FUNC_START sub_00002D68
sub_00002D68: @ 0x00002D68
	ldr r3, _00003098 @=gUnknown_0300000C
	movs r1, #0
	strb r1, [r3, #0xf]
	bx lr

	THUMB_FUNC_START sub_00002D70
sub_00002D70: @ 0x00002D70
	ldr r2, _00003078 @=REG_SIOMULTI0
	ldrh r1, [r2]
	ldr r3, _00003098 @=gUnknown_0300000C
	ldrb r0, [r3, #0xe]
	cmp r0, #1
	bne _00002D86
	ldrh r0, [r2, #8]
	lsrs r0, r0, #7
	bhs _00002E62
_00002D82:
	ldr r0, [r3, #0x34]
	mov pc, r0
	@ noreturn
_00002D86:
	cmp r0, #2
	beq _00002D82
	ldrh r1, [r2, #0x20]
	strh r1, [r2, #0x20]
	movs r0, #7
	ands r1, r0
	b _00002D82
	.align 2, 0
_00002D94: .4byte gUnknown_020000C0
_00002D98: .4byte 0xA1C12083
_00002D9C: .4byte gUnknown_03007FF0 + 0xB
_00002DA0: .4byte gUnknown_0300000C

	THUMB_FUNC_START _00002DA4
_00002DA4: @ 0x00002DA4
	lsrs r0, r1, #8
	cmp r0, #0x62
	bne _00002E84
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	bne _00002DB4
	movs r0, #1
	b _00002DBA
_00002DB4:
	ldrh r0, [r2, #8]
	lsls r0, r0, #0x1a
	lsrs r0, r0, #0x1e
_00002DBA:
	strb r0, [r3, #0x16]
	beq _00002E62
	movs r1, #1
	lsls r1, r0
	strb r1, [r3, #0x15]
	ldrh r1, [r2]
	add r0, pc, #0x28
	str r0, [r3, #0x34]
_00002DCA:
	strb r1, [r3, #0x10]
	movs r0, #0xb
	strb r0, [r3, #0xc]
	movs r0, #0x11
	ands r0, r1
	bne _00002E62
	lsrs r0, r1, #4
	orrs r0, r1
	lsrs r2, r1, #4
	eors r2, r1
	eors r2, r0
	lsls r2, r2, #0x1c
	bne _00002E62
	movs r0, #0x72
	lsls r0, r0, #8
	ldrb r1, [r3, #0x15]
	orrs r1, r0
	b _00002F3E
	.align 2, 0

	THUMB_FUNC_START _00002DF0
_00002DF0: @ 0x00002DF0
	lsrs r0, r1, #8
_00002DF2:
	cmp r0, #0x62
	beq _00002DCA
	cmp r0, #0x61
	bne _00002E62
	movs r0, #3
	strb r0, [r3, #0xf]
	strb r0, [r3, #0xd]
	ldr r2, _00003094 @=gUnknown_02000000
	str r2, [r3, #0x38]
	movs r2, #0x60
	add r0, pc, #0x4
	b _00002E1C
	.align 2, 0

	THUMB_FUNC_START _00002E0C
_00002E0C: @ 0x00002E0C
	ldr r2, [r3, #0x38]
	strh r1, [r2]
	.2byte 0x1C92 @ adds r2, r2, #2
	str r2, [r3, #0x38]
	ldr r2, [r3, #0x48]
	.2byte 0x1E52 @ subs r2, r2, #1
	bne _00002E1C
	add r0, pc, #0xC
_00002E1C:
	str r2, [r3, #0x48]
	lsls r2, r2, #8
	ldrb r1, [r3, #0x15]
	orrs r1, r2
	b _00002F3C
	.align 2, 0

	THUMB_FUNC_START _00002E28
_00002E28: @ 0x00002E28
	lsrs r0, r1, #8
	cmp r0, #0x63
	bne _00002DF2
	movs r0, #0xff
	strb r0, [r3, #0x1a]
	strb r0, [r3, #0x1b]
_00002E34:
	strb r1, [r3, #0xa]
	strb r1, [r3, #0x18]
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	bne _00002E44
	ldrb r0, [r3, #0x17]
	strb r0, [r3, #0x19]
	b _00002E50
_00002E44:
	ldrh r0, [r2, #2]
	strb r0, [r3, #0x19]
	ldrh r0, [r2, #4]
	strb r0, [r3, #0x1a]
	ldrh r0, [r2, #6]
	strb r0, [r3, #0x1b]
_00002E50:
	ldr r0, [r3, #0x18]
	str r0, [r3, #4]
	ldrb r2, [r3, #1]
	strb r2, [r3, #0x17]
	add r0, pc, #0x8
_00002E5A:
	movs r1, #0x73
	lsls r1, r1, #8
	orrs r1, r2
	b _00002F3C
_00002E62:
	b _00002F56

	THUMB_FUNC_START _00002E64
_00002E64: @ 0x00002E64
	lsrs r0, r1, #8
	cmp r0, #0x63
	beq _00002E34
	cmp r0, #0x64
	bne _00002F56
	strb r1, [r3, #0x1c]
	ldrb r2, [r3, #2]
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	bne _00002E80
	strb r2, [r3, #0x1d]
	movs r0, #0xff
	strb r0, [r3, #0x1e]
	strb r0, [r3, #0x1f]
_00002E80:
	add r0, pc, #0x4
	b _00002E5A
_00002E84:
	b _00002F44
	.align 2, 0

	THUMB_FUNC_START _00002E88
_00002E88: @ 0x00002E88
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	beq _00002E9A
	ldrh r0, [r2, #2]
	strb r0, [r3, #0x1d]
	ldrh r0, [r2, #4]
	strb r0, [r3, #0x1e]
	ldrh r0, [r2, #6]
	strb r0, [r3, #0x1f]
_00002E9A:
	lsls r1, r1, #2
	adds r1, #0xc8
	ldr r0, _0000307C @=0x0003FFF8
	ands r0, r1
	eors r1, r0
	bne _00002F56
	ldr r1, _0000308C @=gUnknown_020000C0
	adds r2, r1, r0
	adds r2, #8
	str r2, [r3, #0x3c]
	add r0, pc, #0x4
	b _00002F3C
	.align 2, 0

	THUMB_FUNC_START _00002EB4
_00002EB4: @ 0x00002EB4
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	ldr r0, [r3, #0x38]
	strh r1, [r0]
	bne _00002EC4
	ldr r1, [r2]
	str r1, [r0]
	@ adds r0, r0, #2
	.2byte 0x1C80
_00002EC4:
	adds r1, r0, #2
	str r1, [r3, #0x38]
	ldr r0, [r3, #0x3c]
	cmp r0, r1
	bne _00002F3E
	add r0, pc, #0x4
	b _00002F3C
	.align 2, 0

	THUMB_FUNC_START _00002ED4
_00002ED4: @ 0x00002ED4
	cmp r1, #0x65
	bne _00002F56
	ldr r1, [r3, #0x44]
	ldr r2, [r3, #0x3c]
	cmp r1, r2
	beq _00002EE4
	movs r1, #0x74
	b _00002F3E
_00002EE4:
	movs r1, #0x75
	add r0, pc, #0x4
	b _00002F3C
	.align 2, 0

	THUMB_FUNC_START _00002EEC
_00002EEC: @ 0x00002EEC
	cmp r1, #0x65
	beq _00002EE4
	cmp r1, #0x66
	bne _00002F56
	ldrh r1, [r3, #0x20]
	add r0, pc, #0x4
	b _00002F3C
	.align 2, 0

	THUMB_FUNC_START _00002EFC
_00002EFC: @ 0x00002EFC
	ldrh r0, [r3, #0x20]
	cmp r0, r1
	bne _00002F56
	ldrb r1, [r3, #0xe]
	cmp r1, #1
	bne _00002F22
	ldrb r3, [r3, #0x10]
	lsls r3, r3, #0x1c
	lsrs r3, r3, #0x1d
_00002F0E:
	lsrs r3, r3, #1
	bcc _00002F1C
	ldrh r1, [r2, #2]
	cmp r0, r1
	bne _00002F1E
_00002F18:
	@ adds r2, r2, #2
	.2byte 0x1C92
	b _00002F0E
_00002F1C:
	bne _00002F18
_00002F1E:
	ldr r3, _00003098 @=gUnknown_0300000C
	bne _00002F56
_00002F22:
	ldr r0, [r3, #0x1c]
	ldrb r1, [r3, #0x19]
	subs r0, r0, r1
	ldrb r1, [r3, #0x1a]
	subs r0, r0, r1
	ldrb r1, [r3, #0x1b]
	subs r0, r0, r1
	subs r0, #0x11
	lsls r0, r0, #0x18
	bne _00002F56
	movs r1, #0xff
	strb r1, [r3, #0x11]
	add r0, pc, #0xE0
_00002F3C:
	str r0, [r3, #0x34]
_00002F3E:
	ldr r2, _00003078 @=REG_SIOMULTI0
	strh r1, [r2, #0xa]
	strh r1, [r2, #2]
_00002F44:
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	bne _00002F50
	ldr r2, _00003078 @=REG_SIOMULTI0
	ldr r0, _00002F60 @=0x10085088
	strh r0, [r2, #8]
_00002F50:
	movs r0, #0xb
	str r0, [r3, #0x30]
	bx lr
_00002F56:
	movs r1, #0
	strb r1, [r3, #0xf]
	add r0, pc, #0xC0
	b _00002F3C
	.align 2, 0
_00002F60: .4byte 0x10085088

	THUMB_FUNC_START _00002F64
_00002F64: @ 0x00002F64
	cmp r1, #1
	bne _00002F56
	ldr r0, [r3]
	str r0, [r3, #4]
	ldr r1, _00003084 @=0x6F646573
	eors r0, r1
	str r0, [r2, #0x34]
	movs r0, #0xb
	strb r0, [r3, #0xc]
	movs r1, #0x10
	add r0, pc, #0x0
	b _00003014

	THUMB_FUNC_START _00002F7C
_00002F7C: @ 0x00002F7C
	cmp r1, #4
	bne _00002F56
	movs r0, #3
	strb r0, [r3, #0xf]
	strb r0, [r3, #0xd]
	add r0, pc, #0x4
	b _00003018
	.align 2, 0

	THUMB_FUNC_START _00002F8C
_00002F8C: @ 0x00002F8C
	cmp r1, #2
	bne _00002F56
	ldr r0, [r2, #0x30]
	movs r1, #2
	lsls r1, r1, #8
	ands r1, r0
	lsrs r1, r1, #7
	add r2, pc, #0xE4
	adds r2, r2, r1
	ldr r1, [r2]
	eors r0, r1
	str r0, [r3, #8]
	lsrs r1, r0, #8
	movs r2, #0x7f
	ands r1, r2
	lsls r0, r0, #0x10
	bcc _00002FB0
	adds r1, #0x80
_00002FB0:
	lsrs r0, r0, #0x10
	ands r0, r2
	lsls r1, r1, #7
	orrs r1, r0
	adds r1, #0x3f
	lsls r1, r1, #3
	ldr r0, _0000307C @=0x0003FFF8
	ands r0, r1
	cmp r0, r1
	beq _00002FD0
	ldrb r0, [r3, #0xa]
	lsls r0, r0, #0x19
	lsrs r0, r0, #0x19
	strb r0, [r3, #0xa]
	movs r0, #0x89
	lsls r0, r0, #7
_00002FD0:
	adds r0, #0xc
	ldr r1, _00003094 @=gUnknown_02000000
	adds r1, r1, r0
	str r1, [r3, #0x40]
	movs r1, #0x20
	add r0, pc, #0x4
	b _00003014
	.align 2, 0

	THUMB_FUNC_START _00002FE0
_00002FE0: @ 0x00002FE0
	cmp r1, #2
	bne _00002F56
	ldrh r0, [r2, #0x38]
	movs r1, #0x10
	eors r1, r0
	ldr r0, [r2, #0x30]
	strh r1, [r2, #0x38]
	ldr r1, [r3, #0x38]
	stm r1!, {r0}
	str r1, [r3, #0x38]
	ldr r0, [r3, #0x3c]
	cmp r0, r1
	bne _00002F44
	ldr r1, _0000308C @=gUnknown_020000C0
	cmp r0, r1
	bne _00003006
	ldr r0, [r3, #0x40]
	str r0, [r3, #0x3c]
	b _00002F44
_00003006:
	ldr r0, _00003090 @=gUnknown_020001F8
	ldr r1, [r0, #4]
	ldr r0, [r0]
	muls r0, r1, r0
	str r0, [r2, #0x34]
	movs r1, #0
	add r0, pc, #0x8
_00003014:
	ldr r2, _00003078 @=REG_SIOMULTI0
	strh r1, [r2, #0x38]
_00003018:
	str r0, [r3, #0x34]
	b _00002F44

	THUMB_FUNC_START sub_0000301C
sub_0000301C: @ 0x0000301C
	bx lr

	UNALIGNED_THUMB_FUNC_START sub_0000301E
sub_0000301E: @ 0x0000301E
	push {lr}
	ldr r2, _00003094 @=gUnknown_02000000
	str r0, [r2]
	ldr r3, _0000308C @=gUnknown_020000C0
	strb r1, [r3, #4]
	cmp r1, #1
	beq _00003030
	ldrb r0, [r7, #0x16]
	strb r0, [r3, #5]
_00003030:
	adds r0, r2, #4
	bl sub_000006E8
	pop {pc}
_00003038:
	@ adds r0, r0, #4
	.2byte 0x1D00
	bl sub_0000094A
	ldrh r0, [r7, #0x24]
	cmp r0, #0
	bne _00003048
	movs r0, #0x3c
	strh r0, [r7, #0x24]
_00003048:
	b _00002AE8
_0000304A:
	ldrb r0, [r7, #0x12]
	cmp r0, #0x77
	bne _00003056
	bl sub_00000974
	b _0000305E
_00003056:
	cmp r0, #0x76
	bne _0000305E
	bl sub_00000982
_0000305E:
	ldrh r0, [r7, #0x24]
	cmp r0, #0
	beq _00003074
	@ subs r0, r0, #1
	.2byte 0x1E40
	strh r0, [r7, #0x24]
	cmp r0, #0x39
	bne _00003074
	ldr r0, _000030A8 @=gUnknown_0300390C
	ldr r1, _000030AC @=gUnknown_3980
	bl swi_MusicPlayerStart
_00003074:
	b _00002B48
	.align 2, 0
_00003078: .4byte REG_SIOMULTI0
_0000307C: .4byte 0x0003FFF8
_00003080: .4byte 0x6177614B
_00003084: .4byte 0x6F646573
_00003088: .4byte REG_IE
_0000308C: .4byte gUnknown_020000C0
_00003090: .4byte gUnknown_020001F8
_00003094: .4byte gUnknown_02000000
_00003098: .4byte gUnknown_0300000C
_0000309C: .4byte 0x80808080
_000030A0: .4byte 0xEA000036
_000030A4: .4byte 0xEA00002E
_000030A8: .4byte gUnknown_0300390C
_000030AC: .4byte gUnknown_3980

	.global gUnknown_30B0
gUnknown_30B0:
	.2byte 0x0022, 0x0028, 0x0082, 0x0088, 0x00E2, 0x00E8, 0x0142, 0x0148

	.global gUnknown_30C0
gUnknown_30C0:
	@ a struct of some sort?
	.byte 0x00, 0x02, 0x02, 0x08, 0x00, 0x00, 0x00, 0x00

	.global gUnknown_30C8
gUnknown_30C8:
	.byte 0xC0, 0x01, 0x01, 0x08, 0x1E, 0x00, 0x00, 0x00

	.global gUnknown_30D0
gUnknown_30D0:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
	.byte 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x1C, 0x1E, 0x20, 0x24, 0x28, 0x2A, 0x2C
	.byte 0x30, 0x34, 0x36, 0x38, 0x3C, 0x40, 0x42, 0x44, 0x48, 0x4C, 0x4E, 0x50, 0x54, 0x58, 0x5A, 0x5C
	.byte 0x60, 0x00, 0x00, 0x00

	.global gUnknown_3104
gUnknown_3104:
	.byte 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB
	.byte 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xDB, 0xC0, 0xC1, 0xC2, 0xC3
	.byte 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7
	.byte 0xB8, 0xB9, 0xBA, 0xBB, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB
	.byte 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x80, 0x81, 0x82, 0x83
	.byte 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77
	.byte 0x78, 0x79, 0x7A, 0x7B, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B
	.byte 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x40, 0x41, 0x42, 0x43
	.byte 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37
	.byte 0x38, 0x39, 0x3A, 0x3B, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B
	.byte 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x00, 0x01, 0x02, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x00, 0x00, 0x00, 0x80, 0x97, 0x7C, 0x9C, 0x87
	.byte 0x1E, 0xD6, 0xAC, 0x8F, 0x52, 0xF0, 0x37, 0x98, 0xCC, 0x17, 0x45, 0xA1, 0x48, 0x08, 0xDC, 0xAA
	.byte 0x34, 0xF3, 0x04, 0xB5, 0xBB, 0x86, 0xC8, 0xBF, 0x2A, 0xF5, 0x2F, 0xCB, 0xCB, 0xFC, 0x44, 0xD7
	.byte 0x3A, 0xF0, 0x11, 0xE4, 0x39, 0xBF, 0xA1, 0xF1

	.global gUnknown_31E8
gUnknown_31E8:
	.byte 0x60, 0x00, 0x84, 0x00, 0xB0, 0x00, 0xE0, 0x00
	.byte 0x08, 0x01, 0x30, 0x01, 0x60, 0x01, 0xC0, 0x01, 0x10, 0x02, 0x60, 0x02, 0xA0, 0x02, 0xC0, 0x02

	.global gUnknown_3200
gUnknown_3200:
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0x1F, 0x00, 0xF0, 0x01, 0x1F, 0x28, 0xF0, 0x01, 0x1F, 0x58, 0xF0, 0x01
	.byte 0x00, 0x00, 0xF0, 0x01, 0x0A, 0x28, 0xF0, 0x01, 0x16, 0x58, 0xF0, 0x01, 0x00, 0x7C, 0xF0, 0x01
	.byte 0x0A, 0x7C, 0xF0, 0x01, 0x16, 0x7C, 0xF0, 0x01, 0x00, 0x7C, 0x00, 0x00, 0x0A, 0x7C, 0xA0, 0x00
	.byte 0x16, 0x7C, 0x60, 0x01, 0x1F, 0x7C, 0x00, 0x00, 0x1F, 0x7C, 0xA0, 0x00, 0x1F, 0x7C, 0x60, 0x01
	.byte 0x1F, 0x00, 0x00, 0x00, 0x1F, 0x28, 0xA0, 0x00, 0x1F, 0x58, 0x60, 0x01, 0x1F, 0x00, 0xF0, 0x01
	.byte 0x1F, 0x28, 0xF0, 0x01, 0x1F, 0x58, 0xF0, 0x01, 0x1F, 0x7C, 0xF0, 0x01, 0x1F, 0x7C, 0xF0, 0x01
	.byte 0x1F, 0x7C, 0xF0, 0x01

	.global gUnknown_3264
gUnknown_3264:
	.byte 0x00, 0x7C, 0x1F, 0xFF, 0x5F, 0xFD, 0x1F, 0x7C

	.global gUnknown_326C
gUnknown_326C:
	.byte 0x24, 0xD4, 0x00, 0x00
	.byte 0x0F, 0x40, 0x00, 0x00, 0x00, 0x01, 0x81, 0x82, 0x82, 0x83, 0x0F, 0x83, 0x0C, 0xC3, 0x03, 0x83
	.byte 0x01, 0x83, 0x04, 0xC3, 0x08, 0x0E, 0x02, 0xC2, 0x0D, 0xC2, 0x07, 0x0B, 0x06, 0x0A, 0x05, 0x09

	.global gUnknown_3290
gUnknown_3290:
	.byte 0x24, 0xFF, 0xAE, 0x51, 0x69, 0x9A, 0xA2, 0x21, 0x3D, 0x84, 0x82, 0x0A, 0x84, 0xE4, 0x09, 0xAD
	.byte 0x11, 0x24, 0x8B, 0x98, 0xC0, 0x81, 0x7F, 0x21, 0xA3, 0x52, 0xBE, 0x19, 0x93, 0x09, 0xCE, 0x20
	.byte 0x10, 0x46, 0x4A, 0x4A, 0xF8, 0x27, 0x31, 0xEC, 0x58, 0xC7, 0xE8, 0x33, 0x82, 0xE3, 0xCE, 0xBF
	.byte 0x85, 0xF4, 0xDF, 0x94, 0xCE, 0x4B, 0x09, 0xC1, 0x94, 0x56, 0x8A, 0xC0, 0x13, 0x72, 0xA7, 0xFC
	.byte 0x9F, 0x84, 0x4D, 0x73, 0xA3, 0xCA, 0x9A, 0x61, 0x58, 0x97, 0xA3, 0x27, 0xFC, 0x03, 0x98, 0x76
	.byte 0x23, 0x1D, 0xC7, 0x61, 0x03, 0x04, 0xAE, 0x56, 0xBF, 0x38, 0x84, 0x00, 0x40, 0xA7, 0x0E, 0xFD
	.byte 0xFF, 0x52, 0xFE, 0x03, 0x6F, 0x95, 0x30, 0xF1, 0x97, 0xFB, 0xC0, 0x85, 0x60, 0xD6, 0x80, 0x25
	.byte 0xA9, 0x63, 0xBE, 0x03, 0x01, 0x4E, 0x38, 0xE2, 0xF9, 0xA2, 0x34, 0xFF, 0xBB, 0x3E, 0x03, 0x44
	.byte 0x78, 0x00, 0x90, 0xCB, 0x88, 0x11, 0x3A, 0x94, 0x65, 0xC0, 0x7C, 0x63, 0x87, 0xF0, 0x3C, 0xAF
	.byte 0xD6, 0x25, 0xE4, 0x8B, 0x38, 0x0A, 0xAC, 0x72, 0x21, 0xD4, 0xF8, 0x07

	.global gUnknown_332C
gUnknown_332C:
	.byte 0x24, 0xC0, 0x03, 0x00
	.byte 0x0F, 0x00, 0x80, 0x01, 0x00, 0x41, 0x01, 0x42, 0x02, 0x05, 0xC2, 0x43, 0x43, 0x01, 0x43, 0xC4
	.byte 0x0A, 0x0F, 0xC3, 0x03, 0xC3, 0x02, 0xC3, 0x09, 0x0B, 0x04, 0x07, 0x08, 0x06, 0x0D, 0x0C, 0x0E
	.byte 0x00, 0x03, 0x54, 0x38, 0x02, 0x0C, 0x1C, 0x48, 0xC3, 0xC0, 0x56, 0x99, 0x08, 0x80, 0x6D, 0x75
	.byte 0xD9, 0xA6, 0x1A, 0x44, 0x21, 0x40, 0x84, 0x80, 0xA6, 0xB7, 0x35, 0x10, 0x98, 0x6C, 0xDB, 0xF1
	.byte 0xA2, 0x15, 0xD4, 0x66, 0x07, 0x0A, 0x2C, 0x00, 0x18, 0x04, 0xAC, 0xB1, 0xEB, 0x9D, 0xE1, 0x55
	.byte 0xDE, 0x48, 0xB0, 0x45, 0x1A, 0x6C, 0xEC, 0x46, 0x58, 0xD8, 0x04, 0x60, 0x04, 0x01, 0x2E, 0x29
	.byte 0xC7, 0x60, 0xAF, 0xE2, 0x61, 0xD6, 0x61, 0x10, 0x9D, 0xC6, 0x0F, 0xE4, 0x79, 0x13, 0x38, 0x40
	.byte 0x17, 0x56, 0x77, 0x1B, 0x8D, 0x6E, 0xB0, 0x5A, 0x30, 0xE2, 0x36, 0xBC, 0x28, 0x6C, 0x3D, 0xC3
	.byte 0xE7, 0xE1, 0xF0, 0xC1, 0x14, 0x9D, 0x9A, 0xB4, 0x94, 0x80, 0xA0, 0x0A, 0x46, 0x69, 0x74, 0x56
	.byte 0x05, 0xB5, 0x0D, 0xDA, 0x79, 0x30, 0x04, 0x5B, 0x68, 0x12, 0x0D, 0x22, 0x90, 0x19, 0xA5, 0x46
	.byte 0xD0, 0xE3, 0xF0, 0x91, 0x4D, 0x72, 0x25, 0xE2, 0x66, 0x18, 0x40, 0xC9, 0x18, 0x06, 0xAC, 0xA0
	.byte 0x85, 0x4C, 0xC8, 0x83, 0x81, 0xF1, 0x86, 0xB4, 0x6D, 0x28, 0xD9, 0xE5, 0xB6, 0x0A, 0x28, 0x6A
	.byte 0xB7, 0xB1, 0x94, 0x2F, 0x5B, 0x4D, 0xA3, 0x57, 0x7E, 0xF8, 0x1B, 0xCD, 0x0D, 0x43, 0xAF, 0xD3
	.byte 0x37, 0x9A, 0x37, 0xFA, 0xDA, 0x9B, 0xB6, 0x95, 0xC4, 0x12, 0x91, 0xB6, 0x1D, 0x5A, 0xA8, 0x00
	.byte 0x13, 0xA0, 0xB4, 0x79, 0xD2, 0x10, 0x81, 0x92, 0x46, 0xDA, 0x86, 0x0A, 0xA3, 0x30, 0xDC, 0x88
	.byte 0xC0, 0xD6, 0x6C, 0x30, 0x9C, 0xF1, 0x86, 0xE6, 0xF4, 0x00, 0xC3, 0x00, 0xC6, 0x82, 0x1E, 0x16
	.byte 0x60, 0xD0, 0xBB, 0x6A, 0x20, 0x63, 0x05, 0x24, 0x0A, 0xA5, 0xFB, 0x2B, 0x38, 0x54, 0x9E, 0x1B
	.byte 0x90, 0x97, 0x90, 0x5A, 0x7F, 0xDE, 0x90, 0x38, 0x83, 0x82, 0x32, 0x0A, 0xB0, 0xB5, 0x12, 0x80
	.byte 0x04, 0x79, 0xC3, 0x98, 0xE3, 0x62, 0x38, 0xD0, 0x5F, 0x5D, 0x46, 0xDF, 0xC3, 0x29, 0x1F, 0xD9
	.byte 0x5F, 0xE5, 0xA1, 0x54, 0x69, 0x00, 0x48, 0xCA, 0xA3, 0xEC, 0x16, 0x6C, 0x06, 0x35, 0x0C, 0xB3
	.byte 0xB7, 0xF5, 0xAD, 0xF6, 0x5B, 0x06, 0xDA, 0xF0, 0xC0, 0x9B, 0xBC, 0x6D, 0xAE, 0x69, 0x4B, 0x4B
	.byte 0x2A, 0x0F, 0x87, 0x21, 0x5B, 0xA4, 0x0C, 0x10, 0xDA, 0xAF, 0x10, 0x65, 0xF2, 0xDC, 0x86, 0x5B
	.byte 0xC3, 0x1B, 0xD1, 0xB8, 0x51, 0x7A, 0x98, 0xE6, 0x75, 0x96, 0xB6, 0xD8, 0xDD, 0x39, 0xE7, 0xAD
	.byte 0xE7, 0xDB, 0x37, 0xCE, 0x74, 0xCE, 0xCF, 0x28, 0xD8, 0xDC, 0x66, 0x50, 0x4A, 0xDB, 0xDA, 0xB6
	.byte 0xA1, 0x26, 0xC8, 0xDB, 0x42, 0xD5, 0x20, 0xF6, 0x19, 0x4B, 0xE1, 0xDE, 0xBA, 0x37, 0x8D, 0xAA
	.byte 0x9C, 0xF2, 0xCC, 0xBC, 0xC7, 0xEE, 0x79, 0xB4, 0x02, 0x2C, 0x20, 0xCF, 0xCE, 0x4C, 0x5B, 0xD2
	.byte 0x63, 0xBB, 0x7A, 0x8D, 0xFA, 0xDA, 0x64, 0x03, 0x70, 0xFE, 0x99, 0xF9, 0x9F, 0xAA, 0x20, 0x75
	.byte 0x2E, 0x27, 0x6F, 0x83, 0x52, 0x50, 0xF5, 0x39, 0x7E, 0x58, 0xB2, 0x6E, 0xB9, 0x55, 0xF2, 0x9A
	.byte 0x0D, 0xDA, 0x05, 0x8A, 0xAB, 0x79, 0xB0, 0xBA, 0xB7, 0xF5, 0xAD, 0x7E, 0x99, 0x8F, 0xE6, 0xE8
	.byte 0x48, 0x92, 0xEE, 0x77, 0x54, 0x19, 0x85, 0x18, 0xDE, 0x5C, 0x48, 0x08, 0x4C, 0x5A, 0x68, 0x73
	.byte 0x7D, 0xE6, 0x41, 0x84, 0x83, 0x48, 0xD4, 0xF0, 0xB7, 0x37, 0xBC, 0x36, 0x6A, 0x72, 0x3A, 0xE5
	.byte 0xAE, 0x9E, 0x99, 0x90, 0x0A, 0x19, 0x03, 0x24, 0x74, 0x85, 0xAE, 0xF0, 0x35, 0xAD, 0xC5, 0xEC
	.byte 0xDF, 0x48, 0xBC, 0x61, 0x8F, 0x62, 0x4A, 0x3F, 0xCD, 0x5C, 0x32, 0x93, 0xAD, 0xCC, 0xB3, 0x99
	.byte 0x2A, 0x0C, 0x65, 0x8E, 0x50, 0x49, 0xAA, 0xBB, 0xCB, 0x29, 0x6D, 0x30, 0xA3, 0x9F, 0x4E, 0x5F
	.byte 0x6D, 0x74, 0x33, 0x53, 0xA5, 0x15, 0x6B, 0x38, 0x96, 0x09, 0x2D, 0xC6, 0x4E, 0xF6, 0x31, 0x8A
	.byte 0xE2, 0x3D, 0xA5, 0x7E, 0x24, 0x5C, 0x48, 0xA8, 0x95, 0x68, 0x08, 0x31, 0x1C, 0x42, 0x99, 0x8B
	.byte 0xBB, 0xC3, 0xB5, 0x18, 0x1C, 0xD9, 0x3B, 0x9A, 0xDE, 0xB5, 0xA2, 0xCD, 0x38, 0x6D, 0x77, 0xAA
	.byte 0xD0, 0x8E, 0x43, 0x6F, 0xF1, 0xE4, 0x4A, 0xEF, 0x05, 0xA8, 0x2F, 0x9C, 0x51, 0x06, 0xA5, 0x65
	.byte 0x6C, 0xEA, 0x66, 0xA7, 0xD9, 0xF0, 0xB3, 0xFF, 0x37, 0x4C, 0xEE, 0x86, 0x09, 0xAD, 0x6F, 0xB4
	.byte 0x93, 0xD2, 0x69, 0xD0, 0x19, 0x22, 0xCC, 0xA4, 0xCD, 0x7C, 0xBE, 0x7B, 0x0B, 0xBA, 0x7C, 0x10
	.byte 0x4E, 0xAB, 0x2A, 0xFF, 0x32, 0x91, 0x07, 0x81, 0x50, 0xA5, 0x65, 0x52, 0x16, 0x30, 0x73, 0xB1
	.byte 0x45, 0x66, 0x04, 0xAD, 0x5A, 0xAB, 0x5B, 0x82, 0xD2, 0x84, 0x48, 0xED, 0x5E, 0x18, 0x29, 0x64
	.byte 0x32, 0xCB, 0xEA, 0x4B, 0x58, 0xBB, 0x5F, 0x02, 0x5C, 0xDB, 0xEF, 0x5A, 0xDA, 0x77, 0x6D, 0xAE
	.byte 0xDB, 0xC4, 0xEB, 0x4F, 0x66, 0x74, 0x51, 0x76, 0x58, 0xCB, 0x6D, 0x15, 0x3F, 0xF4, 0x5E, 0x95
	.byte 0x52, 0xFA, 0xA2, 0x73, 0x19, 0xE1, 0x4C, 0x48, 0x34, 0x19, 0xCD, 0x1F, 0x98, 0x39, 0x14, 0xD1
	.byte 0xA0, 0x7F, 0xD5, 0x77, 0x37, 0x4A, 0x1A, 0xE5, 0xF6, 0x2A, 0x6D, 0x21, 0x87, 0xEC, 0x31, 0xA5
	.byte 0x00, 0x26, 0x9F, 0xE7, 0x0A, 0x10, 0x02, 0x05, 0x5C, 0x81, 0x08, 0x81, 0x98, 0x20, 0x22, 0x88
	.byte 0xB0, 0x40, 0x44, 0x85, 0x81, 0x15, 0x05, 0x68, 0x44, 0x88, 0x48, 0xD2, 0xC4, 0x42, 0x24, 0x5A
	.byte 0x91, 0xFD, 0x5A, 0x13, 0x32, 0xE8, 0x22, 0x10, 0x44, 0x80, 0xC8, 0x22, 0x88, 0x08, 0x81, 0x88
	.byte 0x14, 0x15, 0x46, 0xAC, 0xC4, 0x21, 0xAA, 0x21, 0xAA, 0xC5, 0x97, 0x61, 0x88, 0x08, 0x90, 0x64
	.byte 0x88, 0x6B, 0xC4, 0xB4, 0x5B, 0x23, 0xC4, 0x45, 0x83, 0x2F, 0x88, 0x69, 0x58, 0xD7, 0x9E, 0xA5
	.byte 0x9B, 0x15, 0x21, 0x8C, 0x7D, 0x48, 0x70, 0xAA, 0x67, 0xE9, 0x02, 0x5A, 0x62, 0x23, 0xA6, 0xB5
	.byte 0x0D, 0x90, 0xC5, 0x3E, 0xA8, 0x00, 0x11, 0x42, 0xAB, 0x98, 0x82, 0x0E, 0x58, 0x61, 0x98, 0xB9
	.byte 0x19, 0x50, 0xA9, 0x2F, 0xDC, 0xBE, 0x99, 0x41, 0x04, 0x88, 0x44, 0x0B, 0x00, 0x44, 0x24, 0xA1
	.byte 0x88, 0x90, 0x5D, 0xD4, 0x00, 0x4E, 0x29, 0x74, 0x00, 0x00, 0x00, 0x00

	.global gUnknown_369C
gUnknown_369C:
	.byte 0x20, 0x26, 0xAD, 0xC2
	.byte 0x40, 0x0A, 0x00, 0x01, 0x20, 0x26, 0x96, 0xC4, 0x8C, 0x09, 0x40, 0x00, 0x20, 0x26, 0x7F, 0xC6
	.byte 0x80, 0x09, 0x00, 0x00, 0x20, 0x26, 0x68, 0xC8, 0xCC, 0x08, 0x00, 0x00, 0x20, 0x26, 0x50, 0xCA
	.byte 0xC0, 0x08, 0x00, 0x00, 0x20, 0x26, 0x39, 0xCC, 0x0C, 0x08, 0x00, 0x00, 0x20, 0x26, 0x22, 0xCE
	.byte 0x00, 0x08, 0x00, 0x00, 0x66, 0x64, 0x37, 0xC0, 0x40, 0x5B, 0x00, 0x00, 0x66, 0x64, 0x77, 0xC0
	.byte 0x50, 0x5B, 0x00, 0x00, 0x68, 0x22, 0x74, 0x81, 0x90, 0x02, 0x00, 0x00

	.global gUnknown_36EC
gUnknown_36EC:
	.byte 0xFE, 0xFE, 0xFE, 0xFF
	.byte 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0xFF, 0xFF
	.byte 0x00, 0xFF, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0x00, 0xFF, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00

	THUMB_INTERWORK_VENEER swi_Halt
	THUMB_INTERWORK_VENEER Dispcnt_Something_And_Custom_Halt
	THUMB_INTERWORK_VENEER swi_DivArm
	THUMB_INTERWORK_VENEER swi_VBlankIntrWait
	THUMB_INTERWORK_VENEER swi_ObjAffineSet

	.section .rodata
	.global gUnknown_3738
gUnknown_3738:
	.4byte sub_00002664
	.4byte sub_000026CE
	.4byte sub_000026EE
	.4byte sub_00002708
	.4byte sub_0000271C
	.4byte sub_00002664
	.4byte sub_00002664
	.4byte sub_00002664
	.4byte sub_00002664
	.4byte sub_0000274A
	.4byte sub_00002754
	.4byte sub_00002768
	.4byte sub_0000277A
	.4byte sub_000027A8
	.4byte sub_000027BA
	.4byte sub_000027CE
	.4byte sub_000027E2
	.4byte sub_000027F4
	.4byte sub_00002804
	.4byte sub_0000280E
	.4byte sub_0000281E
	.4byte sub_00002664
	.4byte sub_00002664
	.4byte sub_00002836
	.4byte sub_00002664
	.4byte sub_00002664
	.4byte sub_00002664
	.4byte sub_0000284A
	.4byte sub_00002664
	.4byte sub_00002628
	.4byte sub_0000170A
	.4byte sub_000023E6
	.4byte sub_00001534
	.4byte sub_0000159C
	.4byte sub_000023C6
	.4byte sub_000023B0

	.4byte gUnknown_3C00
	.4byte gUnknown_382C

	.byte 0xFF, 0x00, 0x4D, 0xBC, 0x00, 0x3C, 0x00, 0x00
	.byte 0xD0, 0x39, 0x00, 0x00, 0xFF, 0xA5, 0x9A, 0xF9, 0x00, 0x3C, 0x00, 0x00, 0x2C, 0x38, 0x00, 0x00
	.byte 0xFF, 0xA5, 0x80, 0xF6, 0xBC, 0x00, 0xBB, 0x5F, 0xBD, 0x00, 0xBE, 0x4B, 0xBF, 0x40, 0x8F, 0xD5
	.byte 0x5B, 0x70, 0x86, 0xB1, 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x4B, 0xBF, 0x40, 0x8A, 0xD5, 0x56, 0x70
	.byte 0x86, 0xB1, 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x4B, 0xBF, 0x40, 0x85, 0xD5, 0x53, 0x70, 0x86, 0xB1

	.global gUnknown_3818
gUnknown_3818:
	.byte 0x03, 0x00, 0x00, 0xBC, 0xC8, 0x37, 0x00, 0x00, 0xEC, 0x37, 0x00, 0x00, 0xFC, 0x37, 0x00, 0x00
	.byte 0x0A, 0x38, 0x00, 0x00

	.global gUnknown_382C
gUnknown_382C:
	.byte 0x00, 0x00, 0x00, 0x40, 0x95, 0xB4, 0x82, 0x00, 0x01, 0x00, 0x00, 0x00
	.byte 0x21, 0x00, 0x00, 0x00, 0x00, 0x19, 0x31, 0x47, 0x5A, 0x6A, 0x75, 0x7D, 0x7F, 0x7D, 0x75, 0x6A
	.byte 0x5A, 0x47, 0x31, 0x19, 0x00, 0xE7, 0xCF, 0xB9, 0xA6, 0x96, 0x8B, 0x83, 0x81, 0x83, 0x8B, 0x96
	.byte 0xA6, 0xB9, 0xCF, 0xE7, 0x00, 0x19, 0x00, 0x00, 0xBC, 0x00, 0xBB, 0x54, 0xBD, 0x00, 0xBE, 0x55
	.byte 0xBF, 0x40, 0x8F, 0xD5, 0x56, 0x70, 0x86, 0xB1, 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x55, 0xBF, 0x40
	.byte 0x8A, 0xD5, 0x5B, 0x70, 0x86, 0xB1, 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x55, 0xBF, 0x40, 0x85, 0xD5
	.byte 0x56, 0x70, 0x86, 0xB1, 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x55, 0xBF, 0x40, 0xD5, 0x5B, 0x70, 0x86
	.byte 0xB1, 0x00, 0x00, 0x00

	.global gUnknown_389C
gUnknown_389C:
	.byte 0x04, 0x00, 0x00, 0xB7, 0xC8, 0x37, 0x00, 0x00, 0x60, 0x38, 0x00, 0x00
	.byte 0x70, 0x38, 0x00, 0x00, 0x7E, 0x38, 0x00, 0x00, 0x8C, 0x38, 0x00, 0x00, 0xBC, 0x00, 0xBB, 0x4A
	.byte 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0xE7, 0x41, 0x60, 0x98, 0xB1, 0xBC, 0x00, 0xBD, 0x01, 0xBE
	.byte 0x78, 0xBF, 0x40, 0xE7, 0x48, 0x70, 0x98, 0xB1, 0xBC, 0x00, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40
	.byte 0x82, 0xE7, 0x4C, 0x6C, 0x98, 0xB1, 0xBC, 0x00, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0x84, 0xE7
	.byte 0x4F, 0x6C, 0x98, 0xB1, 0xBC, 0x00, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0x86, 0xE7, 0x53, 0x6C
	.byte 0x98, 0xB1, 0xBC, 0x00, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0x8A, 0xE7, 0x56, 0x60, 0x98, 0xB1

	.global gUnknown_3908
gUnknown_3908:
	.byte 0x06, 0x00, 0x00, 0xD0, 0xC8, 0x37, 0x00, 0x00, 0xB4, 0x38, 0x00, 0x00, 0xC3, 0x38, 0x00, 0x00
	.byte 0xD0, 0x38, 0x00, 0x00, 0xDE, 0x38, 0x00, 0x00, 0xEC, 0x38, 0x00, 0x00, 0xFA, 0x38, 0x00, 0x00
	.byte 0xBC, 0x00, 0xBB, 0x63, 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0x8F, 0xD5, 0x64, 0x78, 0x86, 0xB1
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0x8A, 0xD5, 0x62, 0x78, 0x86, 0xB1, 0xBC, 0x00
	.byte 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0x85, 0xD5, 0x60, 0x78, 0x86, 0xB1, 0xBC, 0x00, 0xBD, 0x00
	.byte 0xBE, 0x5E, 0xBF, 0x40, 0xD5, 0x5F, 0x50, 0x86, 0xB1, 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x5E, 0xBF
	.byte 0x40, 0x94, 0xD5, 0x66, 0x78, 0x86, 0xB1, 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0x98
	.byte 0x81, 0xDB, 0x67, 0x78, 0x8C, 0xB1, 0x00, 0x00

	.global gUnknown_3980
gUnknown_3980:
	.byte 0x06, 0x00, 0x00, 0xB2, 0xC8, 0x37, 0x00, 0x00
	.byte 0x28, 0x39, 0x00, 0x00, 0x38, 0x39, 0x00, 0x00, 0x46, 0x39, 0x00, 0x00, 0x54, 0x39, 0x00, 0x00
	.byte 0x61, 0x39, 0x00, 0x00, 0x6F, 0x39, 0x00, 0x00, 0xBC, 0x00, 0xBB, 0x4A, 0xBD, 0x02, 0xBE, 0x55
	.byte 0xBF, 0x40, 0x84, 0xD3, 0x6C, 0x78, 0x85, 0xB1, 0xBC, 0x00, 0xBD, 0x02, 0xBE, 0x55, 0xBF, 0x40
	.byte 0xD3, 0x60, 0x70, 0x84, 0xB1, 0x00, 0x00, 0x00

	.global gUnknown_39C0
gUnknown_39C0:
	.byte 0x02, 0x00, 0x00, 0xD0, 0xC8, 0x37, 0x00, 0x00
	.byte 0xA0, 0x39, 0x00, 0x00, 0xB0, 0x39, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x58, 0x56, 0x2F, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x20, 0x05, 0x00, 0x00, 0x0B, 0x3B, 0x48, 0x3E, 0x24, 0xEB, 0xC3, 0xC6
	.byte 0xDF, 0x0F, 0x35, 0x37, 0x2A, 0xFF, 0xC0, 0xAD, 0xBD, 0xE2, 0x1A, 0x32, 0x27, 0x10, 0xD6, 0xB0
	.byte 0xBD, 0xD9, 0x0D, 0x44, 0x46, 0x33, 0x0D, 0xD1, 0xBE, 0xD1, 0xF4, 0x32, 0x58, 0x52, 0x3E, 0x05
	.byte 0xC4, 0xB5, 0xC9, 0xF6, 0x31, 0x44, 0x3B, 0x1B, 0xD4, 0xA5, 0xAC, 0xC9, 0x03, 0x35, 0x35, 0x23
	.byte 0xF3, 0xB3, 0xAE, 0xC7, 0xF1, 0x34, 0x51, 0x41, 0x27, 0xE9, 0xBA, 0xC4, 0xDF, 0x15, 0x51, 0x5C
	.byte 0x4D, 0x26, 0xDB, 0xB0, 0xBB, 0xDD, 0x19, 0x46, 0x45, 0x30, 0xF6, 0xB1, 0xA2, 0xB8, 0xE5, 0x26
	.byte 0x3D, 0x2F, 0x0E, 0xCB, 0xA6, 0xB8, 0xD8, 0x15, 0x4E, 0x4D, 0x37, 0x08, 0xC6, 0xB7, 0xCF, 0xF8
	.byte 0x3A, 0x60, 0x58, 0x3D, 0xFF, 0xBB, 0xAF, 0xCA, 0xFC, 0x39, 0x4E, 0x3E, 0x15, 0xCE, 0xA0, 0xA9
	.byte 0xCD, 0x09, 0x3C, 0x3C, 0x22, 0xEC, 0xAE, 0xA9, 0xC7, 0xF6, 0x39, 0x56, 0x44, 0x22, 0xE3, 0xB4
	.byte 0xBE, 0xE2, 0x1A, 0x56, 0x64, 0x4C, 0x1E, 0xD6, 0xAA, 0xB8, 0xE2, 0x1D, 0x4D, 0x4C, 0x2A, 0xF0
	.byte 0xAF, 0x9D, 0xBA, 0xEC, 0x29, 0x45, 0x31, 0x06, 0xC9, 0xA3, 0xB5, 0xDF, 0x19, 0x50, 0x53, 0x32
	.byte 0x01, 0xC5, 0xB1, 0xCF, 0xFF, 0x3B, 0x66, 0x5B, 0x34, 0xFA, 0xB7, 0xA9, 0xCE, 0x00, 0x3A, 0x56
	.byte 0x3C, 0x0C, 0xCE, 0x9D, 0xA8, 0xD5, 0x0C, 0x40, 0x41, 0x1A, 0xE7, 0xB0, 0xA4, 0xCA, 0xFE, 0x38
	.byte 0x5B, 0x43, 0x17, 0xE2, 0xB2, 0xBA, 0xE9, 0x1D, 0x57, 0x6A, 0x46, 0x15, 0xD7, 0xA6, 0xBA, 0xEB
	.byte 0x1C, 0x52, 0x4F, 0x1F, 0xEE, 0xB2, 0x9A, 0xC1, 0xF2, 0x28, 0x4B, 0x2D, 0xFD, 0xCD, 0xA2, 0xB3
	.byte 0xE9, 0x19, 0x4F, 0x56, 0x29, 0xFD, 0xC8, 0xAC, 0xD3, 0x05, 0x38, 0x6A, 0x5B, 0x27, 0xF9, 0xB9
	.byte 0xA7, 0xD7, 0x02, 0x39, 0x5C, 0x34, 0x03, 0xD4, 0x9C, 0xAA, 0xDF, 0x09, 0x41, 0x43, 0x0D, 0xE7
	.byte 0xB7, 0xA1, 0xD2, 0x03, 0x33, 0x5C, 0x3E, 0x0C, 0xE7, 0xB3, 0xBA, 0xF3, 0x1C, 0x54, 0x6B, 0x3A
	.byte 0x0E, 0xDB, 0xA5, 0xBF, 0xF2, 0x19, 0x53, 0x4D, 0x13, 0xF1, 0xB7, 0x9A, 0xCA, 0xF5, 0x24, 0x4D
	.byte 0x25, 0xF6, 0xD6, 0xA4, 0xB6, 0xF2, 0x17, 0x4B, 0x53, 0x1D, 0xFB, 0xCD, 0xAB, 0xDA, 0x0A, 0x34
	.byte 0x69, 0x53, 0x1C, 0xFB, 0xBB, 0xAB, 0xE0, 0x03, 0x37, 0x5B, 0x29, 0x00, 0xDB, 0x9F, 0xB1, 0xE6
	.byte 0x06, 0x3E, 0x3E, 0x03, 0xEB, 0xBE, 0xA3, 0xDA, 0x05, 0x2D, 0x58, 0x35, 0x06, 0xEC, 0xB6, 0xBF
	.byte 0xFA, 0x1A, 0x50, 0x66, 0x2F, 0x0B, 0xE0, 0xAA, 0xC7, 0xF5, 0x17, 0x51, 0x44, 0x0B, 0xF5, 0xBD
	.byte 0xA0, 0xD2, 0xF5, 0x20, 0x47, 0x1B, 0xF5, 0xDE, 0xAA, 0xBC, 0xF8, 0x14, 0x44, 0x4B, 0x15, 0xFD
	.byte 0xD4, 0xB1, 0xE1, 0x0B, 0x2F, 0x62, 0x49, 0x16, 0xFC, 0xC3, 0xB4, 0xE4, 0x02, 0x33, 0x51, 0x20
	.byte 0x00, 0xE1, 0xA9, 0xBA, 0xE9, 0x04, 0x37, 0x33, 0x00, 0xF0, 0xC6, 0xAC, 0xE0, 0x05, 0x27, 0x4C
	.byte 0x2C, 0x05, 0xF0, 0xBE, 0xC7, 0xFD, 0x19, 0x49, 0x58, 0x28, 0x0A, 0xE4, 0xB6, 0xCF, 0xF5, 0x15
	.byte 0x47, 0x38, 0x0A, 0xF8, 0xC6, 0xAD, 0xD7, 0xF6, 0x1B, 0x39, 0x14, 0xF9, 0xE4, 0xB5, 0xC5, 0xF8
	.byte 0x11, 0x39, 0x3D, 0x12, 0xFF, 0xDB, 0xBE, 0xE5, 0x0A, 0x2C, 0x52, 0x3D, 0x15, 0xFD, 0xCF, 0xC1
	.byte 0xE4, 0x02, 0x2C, 0x41, 0x1D, 0x02, 0xE7, 0xB8, 0xC2, 0xE8, 0x04, 0x2A, 0x27, 0x02, 0xF5, 0xD1
	.byte 0xBA, 0xE1, 0x04, 0x20, 0x3A, 0x25, 0x08, 0xF3, 0xCD, 0xD1, 0xFA, 0x18, 0x3C, 0x48, 0x27, 0x09
	.byte 0xEB, 0xC9, 0xD3, 0xF4, 0x14, 0x35, 0x2E, 0x0E, 0xFA, 0xD5, 0xBD, 0xD6, 0xF6, 0x12, 0x26, 0x13
	.byte 0xFF, 0xEA, 0xC7, 0xCC, 0xF5, 0x0F, 0x28, 0x2F, 0x16, 0x00, 0xE5, 0xCE, 0xE6, 0x09, 0x26, 0x3E
	.byte 0x36, 0x17, 0xFE, 0xDF, 0xCE, 0xE2, 0x02, 0x20, 0x2F, 0x1F, 0x05, 0xEE, 0xCD, 0xC7, 0xE6, 0x01
	.byte 0x16, 0x1C, 0x0B, 0xF9, 0xDF, 0xCA, 0xDF, 0x02

	.global gUnknown_3C00
gUnknown_3C00:
	.byte 0x15, 0x25, 0x24, 0x0C, 0xF7, 0xDE, 0xD9, 0xF7
	.byte 0x16, 0x2B, 0x37, 0x28, 0x0A, 0xF5, 0xDB, 0xD5, 0xF2, 0x0F, 0x21, 0x27, 0x15, 0xFD, 0xE5, 0xCB
	.byte 0xD3, 0xF5, 0x05, 0x14, 0x17, 0x04, 0xF1, 0xDA, 0xD2, 0xF1, 0x09, 0x13, 0x23, 0x1B, 0x02, 0xF1
	.byte 0xDE, 0xE4, 0x06, 0x1B, 0x29, 0x32, 0x1A, 0x01, 0xF1, 0xD9, 0xE0, 0x00, 0x10, 0x1F, 0x23, 0x09
	.byte 0xF8, 0xE0, 0xCC, 0xE3, 0xFB, 0x03, 0x16, 0x13, 0xFE, 0xEF, 0xD8, 0xDD, 0xFD, 0x06, 0x13, 0x24
	.byte 0x11, 0xFE, 0xF0, 0xE0, 0xF3, 0x0F, 0x18, 0x2B, 0x2A, 0x0D, 0x00, 0xEC, 0xD9, 0xEF, 0x04, 0x0F
	.byte 0x24, 0x1A, 0x02, 0xF7, 0xD8, 0xD2, 0xEF, 0xF7, 0x06, 0x1B, 0x0B, 0xFC, 0xEB, 0xD6, 0xEB, 0xFF
	.byte 0x01, 0x1B, 0x20, 0x08, 0xFE, 0xEB, 0xE5, 0x00, 0x0C, 0x18, 0x2D, 0x1E, 0x0A, 0x00, 0xE3, 0xDF
	.byte 0xF8, 0x00, 0x15, 0x25, 0x10, 0x03, 0xEF, 0xD0, 0xDE, 0xEE, 0xF4, 0x13, 0x1A, 0x06, 0xFC, 0xE3
	.byte 0xDC, 0xF2, 0xF6, 0x07, 0x23, 0x18, 0x07, 0xFC, 0xE6, 0xEF, 0x02, 0x08, 0x21, 0x2A, 0x16, 0x0B
	.byte 0xF7, 0xDD, 0xE8, 0xF7, 0x02, 0x20, 0x20, 0x0D, 0x02, 0xE1, 0xD2, 0xE3, 0xE8, 0xFF, 0x1E, 0x15
	.byte 0x07, 0xF6, 0xDD, 0xE3, 0xED, 0xF6, 0x15, 0x23, 0x14, 0x08, 0xF3, 0xE7, 0xF4, 0xFE, 0x0E, 0x27
	.byte 0x24, 0x16, 0x07, 0xEB, 0xDE, 0xEA, 0xF5, 0x0E, 0x26, 0x1C, 0x0E, 0xF8, 0xD7, 0xD5, 0xDE, 0xED
	.byte 0x10, 0x21, 0x14, 0x05, 0xEC, 0xDC, 0xE1, 0xE9, 0x01, 0x20, 0x22, 0x13, 0x01, 0xEE, 0xE9, 0xF1
	.byte 0x00, 0x18, 0x2A, 0x24, 0x13, 0xFD, 0xE3, 0xDD, 0xE8, 0xFE, 0x1B, 0x29, 0x1C, 0x08, 0xEB, 0xD2
	.byte 0xD1, 0xDF, 0xFD, 0x1E, 0x23, 0x11, 0xFC, 0xE4, 0xD6, 0xDB, 0xF0, 0x10, 0x27, 0x23, 0x0D, 0xFA
	.byte 0xE9, 0xE3, 0xF1, 0x08, 0x21, 0x2F, 0x22, 0x0A, 0xF4, 0xDB, 0xD9, 0xF0, 0x0A, 0x27, 0x2C, 0x16
	.byte 0xFE, 0xDF, 0xC7, 0xD0, 0xEC, 0x0E, 0x2A, 0x23, 0x08, 0xF4, 0xD9, 0xCC, 0xE1, 0xFF, 0x1D, 0x30
	.byte 0x1D, 0x03, 0xF5, 0xDD, 0xDF, 0xFB, 0x11, 0x2D, 0x34, 0x17, 0x01, 0xE8, 0xCE, 0xDE, 0xFD, 0x18
	.byte 0x35, 0x2A, 0x0A, 0xF4, 0xCD, 0xBF, 0xDC, 0xFC, 0x1F, 0x34, 0x19, 0xFF, 0xEA, 0xC6, 0xCC, 0xF1
	.byte 0x0B, 0x2E, 0x32, 0x0E, 0xFF, 0xE8, 0xD0, 0xE9, 0x04, 0x1D, 0x3E, 0x2C, 0x0A, 0xFB, 0xD4, 0xCA
	.byte 0xEE, 0x08, 0x2A, 0x3D, 0x1A, 0x00, 0xE3, 0xB9, 0xC7, 0xEF, 0x0C, 0x34, 0x30, 0x09, 0xF9, 0xD3
	.byte 0xB9, 0xDF, 0xFE, 0x1D, 0x3F, 0x23, 0x04, 0xF8, 0xD0, 0xD2, 0xF9, 0x0C, 0x33, 0x41, 0x18, 0x04
	.byte 0xE8, 0xC0, 0xD8, 0xFD, 0x16, 0x41, 0x33, 0x0A, 0xF8, 0xC6, 0xB2, 0xDE, 0xFE, 0x24, 0x42, 0x1D
	.byte 0x00, 0xEA, 0xB6, 0xC4, 0xF2, 0x09, 0x38, 0x3D, 0x0F, 0x00, 0xE1, 0xC1, 0xE5, 0x0B, 0x3B, 0x49
	.byte 0x19, 0x03, 0xE3, 0xB9, 0xD6, 0xFF, 0x1B, 0x4B, 0x39, 0x0B, 0xF7, 0xBE, 0xAC, 0xE0, 0x00, 0x2B
	.byte 0x4A, 0x20, 0x00, 0xE3, 0xAB, 0xC0, 0xF2, 0x0D, 0x3F, 0x42, 0x10, 0xFC, 0xD7, 0xBB, 0xE1, 0x00
	.byte 0x24, 0x4F, 0x33, 0x09, 0xF5, 0xC6, 0xC0, 0xEF, 0x0B, 0x39, 0x4E, 0x1F, 0x00, 0xDA, 0xA8, 0xC4
	.byte 0xF6, 0x15, 0x46, 0x3C, 0x0A, 0xF3, 0xBF, 0xAA, 0xDC, 0x00, 0x29, 0x4D, 0x29, 0x00, 0xE9, 0xBF
	.byte 0xC8, 0xF4, 0x11, 0x41, 0x4A, 0x1A, 0xFD, 0xDB, 0xBA, 0xD7, 0x00, 0x24, 0x4E, 0x3B, 0x0A, 0xED
	.byte 0xB9, 0xAE, 0xE2, 0x08, 0x33, 0x4C, 0x22, 0xFB, 0xD6, 0xA9, 0xC0, 0xF4, 0x16, 0x43, 0x42, 0x10
	.byte 0xF1, 0xCE, 0xBB, 0xDD, 0x05, 0x2D, 0x4F, 0x35, 0x04, 0xE9, 0xC5, 0xC3, 0xEF, 0x15, 0x3F, 0x4E
	.byte 0x20, 0xF8, 0xD1, 0xAB, 0xC8, 0xFC, 0x21, 0x48, 0x3D, 0x09, 0xE4, 0xB8, 0xAD, 0xDC, 0x09, 0x31
	.byte 0x4B, 0x2A, 0xF9, 0xDA, 0xBF, 0xC7, 0xF4, 0x1D, 0x44, 0x49, 0x19, 0xF0, 0xD4, 0xC0, 0xD7, 0x07
	.byte 0x2F, 0x4E, 0x3C, 0x06, 0xDF, 0xBA, 0xB4, 0xE5, 0x14, 0x39, 0x4A, 0x24, 0xF0, 0xC8, 0xAD, 0xC1
	.byte 0xF8, 0x22, 0x43, 0x40, 0x0D, 0xE0, 0xC9, 0xBF, 0xDB, 0x0E, 0x35, 0x4C, 0x34, 0xFC, 0xDB, 0xCA
	.byte 0xC9, 0xF2, 0x22, 0x43, 0x4B, 0x20, 0xEA, 0xC9, 0xB4, 0xCC, 0x03, 0x2D, 0x47, 0x3C, 0x04, 0xD3
	.byte 0xB7, 0xB3, 0xDD, 0x14, 0x36, 0x46, 0x29, 0xED, 0xCD, 0xC3, 0xC8, 0xF8, 0x29, 0x42, 0x45, 0x15
	.byte 0xE0, 0xD1, 0xC9, 0xDC, 0x11, 0x38, 0x4A, 0x3A, 0xFE, 0xD2, 0xBF, 0xBD, 0xEC, 0x21, 0x3D, 0x46
	.byte 0x21, 0xE1, 0xBF, 0xB4, 0xC5, 0x00, 0x2C, 0x40, 0x3E, 0x05, 0xD0, 0xC7, 0xC3, 0xDE, 0x19, 0x39
	.byte 0x47, 0x30, 0xEF, 0xD1, 0xD0, 0xD0, 0xFB, 0x2D, 0x43, 0x47, 0x1A, 0xDC, 0xC6, 0xBF, 0xD5, 0x0F
	.byte 0x35, 0x44, 0x38, 0xFA, 0xC5, 0xBA, 0xBA, 0xE4, 0x1F, 0x38, 0x42, 0x22, 0xDE, 0xC6, 0xC6, 0xCD
	.byte 0x01, 0x31, 0x40, 0x40, 0x0A, 0xD4, 0xD1, 0xD2, 0xE6, 0x1D, 0x3C, 0x47, 0x33, 0xF1, 0xC9, 0xC5
	.byte 0xC9, 0xF8, 0x2B, 0x3E, 0x41, 0x17, 0xD2, 0xBB, 0xBA, 0xCE, 0x0A, 0x32, 0x3D, 0x36, 0xF8, 0xC6
	.byte 0xC7, 0xC9, 0xE9, 0x22, 0x39, 0x40, 0x23, 0xE3, 0xCF, 0xD7, 0xDE, 0x07, 0x31, 0x3E, 0x3C, 0x0C
	.byte 0xD6, 0xCC, 0xCE, 0xE6, 0x18, 0x33, 0x3A, 0x29, 0xED, 0xC5, 0xC5, 0xCB, 0xF2, 0x21, 0x31, 0x33
	.byte 0x10, 0xD8, 0xCB, 0xD1, 0xDE, 0x0B, 0x2B, 0x33, 0x2C, 0xFC, 0xD7, 0xDB, 0xE1, 0xF8, 0x1E, 0x30
	.byte 0x35, 0x1E, 0xEB, 0xD5, 0xD7, 0xE1, 0x04, 0x25, 0x2F, 0x2C, 0x05, 0xD7, 0xCE, 0xD2, 0xE6, 0x0D
	.byte 0x24, 0x2A, 0x1C, 0xEF, 0xD4, 0xD7, 0xDE, 0xFA, 0x0B

	.rept 256
	.byte 0x00
	.endr
