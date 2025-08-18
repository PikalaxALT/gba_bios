	.include "asm/macro.inc"
	.include "asm/gba_constants.inc"

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
	ldr sp, _01C4 @=IWRAM_END - 0x10
	push {r12, lr}
	mrs r12, spsr
	mrs lr, apsr
	push {r12, lr}
	mov r12, #0x8000000
	ldrb lr, [r12, #0x9c]
	cmp lr, #0xa5
	bne _0054
	ldrbeq lr, [r12, #0xb4]
	andseq lr, lr, #0x80
	adr lr, _0054
	ldrne pc, _0274 @=0x09FE2000
	ldreq pc, _0278 @=0x09FFC000
_0054:
	ldr sp, _01C0 @=IWRAM_END - 0x20
	pop {r12, lr}
	msr spsr_fc, r12
	pop {r12, lr}
	subs pc, lr, #4

	ARM_FUNC_START reset_vector
reset_vector:
	cmp lr, #0
	moveq lr, #4
	mov r12, #REG_BASE
	ldrb r12, [r12, #0x300]
	teq r12, #1
	mrseq r12, apsr
	orreq r12, r12, #0xc0
	msreq cpsr_fc, r12
	beq reserved_vector
swi_HardReset: @ 0x0000008C
	mov r0, #0xdf
	msr cpsr_fc, r0
	mov r4, #REG_BASE
	strb r4, [r4, #REG_OFFSET_IME]
	bl InitSystemStack
	adr r0, sub_0300
	str r0, [sp, #0xfc]
	ldr r0, _027C @=DoSystemBoot
	adr lr, swi_SoftReset
	bx r0

	ARM_FUNC_START swi_SoftReset
swi_SoftReset: @ 0x000000B4
	mov r4, #0x04000000
	ldrb r2, [r4, #-6]
	bl InitSystemStack
	cmp r2, #0 @ Test whether we are in a multiboot state
	ldmdb r4, {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12}
	movne lr, #EWRAM
	moveq lr, #ROM
	mov r0, #0x1f
	msr cpsr_fc, r0
	mov r0, #0
	bx lr

	ARM_FUNC_START InitSystemStack
InitSystemStack:
	mov r0, #0xd3
	msr cpsr_fc, r0
	ldr sp, _01C0 @=IWRAM_END - 0x20
	mov lr, #0
	msr spsr_fc, lr
	mov r0, #0xd2
	msr cpsr_fc, r0
	ldr sp, _01BC @=IWRAM_END - 0x60
	mov lr, #0
	msr spsr_fc, lr
	mov r0, #0x5f
	msr cpsr_fc, r0
	ldr sp, _01B8 @=IWRAM_END - 0x100
	adr r0, _011C+1
	bx r0
	.THUMB
_011C:
	movs r0, #0
	ldr r1, _0280 @=0xFFFFFE00
_0120:
	str r0, [r4, r1]
	@ FIXME: Why is it assembling the wrong opcode?
	@ This occurs throughout
	.2byte 0x1D09 @ adds r1, r1, #4
	blt _0120
	bx lr

	ARM_FUNC_START irq_vector
irq_vector:
	push {r0, r1, r2, r3, r12, lr}
	mov r0, #REG_BASE
	adr lr, irq_complete
	ldr pc, [r0, #-4]
irq_complete:
	pop {r0, r1, r2, r3, r12, lr}
	subs pc, lr, #4

	ARM_FUNC_START swi_vector
swi_vector:
	push {r11, r12, lr}
	ldrb r12, [lr, #-2]
	adr r11, swi_branch_table
	ldr r12, [r11, r12, lsl #2]
	mrs r11, spsr
	stmdb sp!, {r11}
	and r11, r11, #0x80
	orr r11, r11, #0x1f
	msr cpsr_fc, r11
	push {r2, lr}
	adr lr, swi_complete
	bx r12
swi_complete: @ 0x00000170
	pop {r2, lr}
	mov r12, #0xd3
	msr cpsr_fc, r12
	ldm sp!, {r11}
	msr spsr_fc, r11
	pop {r11, r12, lr}
	movs pc, lr

	ARM_FUNC_START DoSwitchToCGBMode
	@ Function does not return
DoSwitchToCGBMode:
	mov r12, #REG_DISPCNT
	mov r2, #DISPCNT_BG2_ON >> 8
	strb r2, [r12, #1]
	mov r2, #DISPCNT_CGB_MODE
	strb r2, [r12]

	ARM_FUNC_START swi_Halt
swi_Halt:
	mov r2, #0
	b swi_CustomHalt

	ARM_FUNC_START swi_Stop
swi_Stop: @ 0x000001A8
	mov r2, #0x80
swi_CustomHalt:
	mov r12, #REG_BASE
	strb r2, [r12, #0x301]
	bx lr
	.align 2, 0
_01B8: .4byte IWRAM_END - 0x100
_01BC: .4byte IWRAM_END - 0x60
_01C0: .4byte IWRAM_END - 0x20
_01C4: .4byte IWRAM_END - 0x10

swi_branch_table:
	.4byte swi_SoftReset            @ 0x00
	.4byte swi_RegisterRamReset     @ 0x01
	.4byte swi_Halt                 @ 0x02
	.4byte swi_Stop                 @ 0x03
	.4byte swi_IntrWait             @ 0x04
	.4byte swi_VBlankIntrWait       @ 0x05
	.4byte swi_Div                  @ 0x06
	.4byte swi_DivArm               @ 0x07
	.4byte swi_Sqrt                 @ 0x08
	.4byte swi_ArcTan               @ 0x09
	.4byte swi_ArcTan2              @ 0x0a
	.4byte swi_CPUSet               @ 0x0b
	.4byte swi_CPUFastSet           @ 0x0c
	.4byte swi_BiosChecksum         @ 0x0d
	.4byte swi_BgAffineSet          @ 0x0e
	.4byte swi_ObjAffineSet         @ 0x0f
	.4byte swi_BitUnPack            @ 0x10
	.4byte swi_LZ77UnCompWRAM       @ 0x11
	.4byte swi_LZ77UnCompVRAM       @ 0x12
	.4byte swi_HuffUnComp           @ 0x13
	.4byte swi_RLUnCompWRAM         @ 0x14
	.4byte swi_RLUnCompVRAM         @ 0x15
	.4byte swi_Diff8bitUnFilterWRAM @ 0x16
	.4byte swi_Diff8bitUnFilterVRAM @ 0x17
	.4byte swi_Diff16bitUnFilter    @ 0x18
	.4byte swi_SoundBiasChange      @ 0x19
	.4byte swi_SoundDriverInit      @ 0x1a
	.4byte swi_SoundDriverMode      @ 0x1b
	.4byte swi_SoundDriverMain      @ 0x1c
	.4byte swi_SoundDriverVSync     @ 0x1d
	.4byte swi_SoundChannelClear    @ 0x1e
	.4byte swi_MIDIKey2Freq         @ 0x1f
	.4byte swi_MusicPlayerOpen      @ 0x20
	.4byte swi_MusicPlayerStart     @ 0x21
	.4byte swi_MusicPlayerStop      @ 0x22
	.4byte swi_MusicPlayerContinue  @ 0x23
	.4byte swi_MusicPlayerFadeOut   @ 0x24
	.4byte swi_MultiBoot            @ 0x25
	.4byte swi_HardReset            @ 0x26
	.4byte swi_CustomHalt           @ 0x27
	.4byte swi_SoundDriverVSyncOff  @ 0x28
	.4byte swi_SoundDriverVSyncOn   @ 0x29
	.4byte swi_GetJumpList          @ 0x2a

_0274: .4byte 0x09FE2000
_0278: .4byte 0x09FFC000
_027C: .4byte DoSystemBoot
_0280: .4byte 0xFFFFFE00

	THUMB_FUNC_START SwitchToCGBMode
	@ Function does not return
SwitchToCGBMode: @ 0x00000284
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
	bl sub_079E
	movs r0, #0x83
	lsls r0, r0, #7
	strh r0, [r4, #REG_OFFSET_BG2CNT]
	ldr r0, _02F4 @=0xFFFFD800
	str r0, [r4, #REG_OFFSET_BG2X_L]
	asrs r0, r0, #0x10
	lsls r0, r0, #0xb
	str r0, [r4, #REG_OFFSET_BG2Y_L]
	ldr r3, _02F8 @=0x7FFF7BDE
	str r3, [r5]
	ldrh r3, [r5]
	ldr r7, _02FC @=0x00000C63
_02C6:
	lsrs r2, r4, #0x11
	adds r2, r2, r4
	strh r7, [r2, #2]
	bl swi_Halt_t
	movs r0, #4
	strb r0, [r4, #1]
	strb r0, [r4]
	subs r3, r3, r7
	strh r3, [r5]
	bgt _02C6
	mvns r0, r1
	str r0, [sp, #8]
	adds r4, #0xd4
	add r1, sp, #8
	str r1, [r4]
	str r6, [r4, #4]
	ldr r1, _02F0 @=0x85006000
	str r1, [r4, #8]
	bl DoSwitchToCGBMode_t
	.align 2, 0
_02F0: .4byte 0x85006000
_02F4: .4byte 0xFFFFD800
_02F8: .4byte 0x7FFF7BDE
_02FC: .4byte 0x00000C63

	ARM_FUNC_START sub_0300
sub_0300: @ 0x00000300
	mov r3, #REG_BASE
	ldr r2, [r3, #0x200]
	and r2, r2, r2, lsr #16
	ands r1, r2, #0x80
	ldrne r0, _0AB8
	andeq r1, r2, #1
	ldreq r0, _0ABC
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
	blne sub_0358
_0344:
	strb r3, [r12, #0x301]
	bl sub_0358
	beq _0344
	pop {r4, lr}
	bx lr

	ARM_FUNC_START sub_0358
sub_0358: @ 0x00000358
	mov r12, #REG_BASE
	strb r3, [r12, #0x208]
	ldrh r2, [r12, #-8]
	ands r0, r1, r2
	eorne r2, r2, r0
	strhne r2, [r12, #-8]
	strb r4, [r12, #0x208]
	bx lr

	ARM_FUNC_START swi_BiosChecksum
swi_BiosChecksum: @ 0x00000378
	mov r0, #0
	mov r3, #0
_0380:
	mov r12, #0xdf
	ldm r3!, {r2}
	msr cpsr_fc, r12
	add r0, r0, r2
	lsrs r1, r3, #0xe
	beq _0380
	bx lr

	THUMB_FUNC_START sub_039C
sub_039C: @ 0x0000039C
	cmp r0, #0
	bgt _03A2
	negs r0, r0
_03A2:
	bx lr

	THUMB_FUNC_START swi_Div_t
swi_Div_t: @ 0x000003A4
	adr r3, swi_Div
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
	eors r12, r3, r0, asr #32
	rsbhs r0, r0, #0
	movs r2, r1
_03C8:
	cmp r2, r0, lsr #1
	lslls r2, r2, #1
	bcc _03C8
_03D4:
	cmp r0, r2
	adc r3, r3, r3
	subhs r0, r0, r2
	teq r2, r1
	lsrne r2, r2, #1
	bne _03D4
	mov r1, r0
	mov r0, r3
	lsls r12, r12, #1
	rsbhs r0, r0, #0
	rsbmi r1, r1, #0
	bx lr

	ARM_FUNC_START swi_Sqrt
swi_Sqrt: @ 0x00000404
	stmdb sp!, {r4}
	mov r12, r0
	mov r1, #1
_0410:
	cmp r0, r1
	lsrhi r0, r0, #1
	lslhi r1, r1, #1
	bhi _0410
_0420:
	mov r0, r12
	mov r4, r1
	mov r3, #0
	mov r2, r1
_0430:
	cmp r2, r0, lsr #1
	lslls r2, r2, #1
	bcc _0430
_043C:
	cmp r0, r2
	adc r3, r3, r3
	subhs r0, r0, r2
	teq r2, r1
	lsrne r2, r2, #1
	bne _043C
	add r1, r1, r3
	lsrs r1, r1, #1
	cmp r1, r4
	bcc _0420
	mov r0, r4
	ldm sp!, {r4}
	bx lr

	THUMB_FUNC_START swi_ArcTan_t
swi_ArcTan_t: @ 0x00000470
	adr r3, swi_ArcTan
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
	bne _0510
	cmp r0, #0
	blt _050A
	movs r0, #0
	b _059E
_050A:
	movs r0, #0x80
	lsls r0, r0, #8
	b _059E
_0510:
	cmp r0, #0
	bne _0524
	cmp r1, #0
	blt _051E
	movs r0, #0x40
	lsls r0, r0, #8
	b _059E
_051E:
	movs r0, #0xc0
	lsls r0, r0, #8
	b _059E
_0524:
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
	blt _0572
	cmp r0, #0
	blt _055E
	cmp r0, r1
	blt _0550
	adds r1, r0, #0
	adds r0, r3, #0
	bl swi_Div_t
	bl swi_ArcTan_t
	b _059E
_0550:
	adds r0, r2, #0
	bl swi_Div_t
	bl swi_ArcTan_t
	subs r0, r6, r0
	b _059E
_055E:
	cmp r4, r1
	blt _0550
_0562:
	adds r1, r0, #0
	adds r0, r3, #0
	bl swi_Div_t
	bl swi_ArcTan_t
	adds r0, r7, r0
	b _059E
_0572:
	cmp r0, #0
	bgt _058A
	cmp r4, r5
	bgt _0562
_057A:
	adds r0, r2, #0
	bl swi_Div_t
	bl swi_ArcTan_t
	adds r6, r6, r7
	subs r0, r6, r0
	b _059E
_058A:
	cmp r0, r5
	blt _057A
	adds r1, r0, #0
	adds r0, r3, #0
	bl swi_Div_t
	bl swi_ArcTan_t
	adds r7, r7, r7
	adds r0, r7, r0
_059E:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	THUMB_FUNC_START sub_05A4
sub_05A4: @ 0x000005A4
	push {r3, r4, r5, r6, lr}
	movs r6, #8
	lsls r6, r6, #0x18
	movs r5, #0x9e
	adds r5, r5, r6
	subs r0, r5, #1
	movs r1, #0x1b
	bl sub_06AC
	movs r4, #0xc
	muls r4, r0, r4
	ldrb r3, [r5]
	lsls r3, r3, #0x1e
	lsrs r3, r3, #0x1e
	movs r2, #0x30
	muls r2, r3, r2
	adds r4, r4, r2
	adr r5, gUnknown_05EC
	adds r5, r5, r4
	movs r4, #0
_05CC:
	adds r0, r4, #0
	bl sub_06CE
	cmp r4, #3
	blt _05E4
	cmp r4, #9
	bge _05E4
	ldrh r1, [r5]
	lsls r1, r1, #1
	orrs r1, r6
	ldrh r0, [r1]
	.2byte 0x1CAD @ adds r5, r5, #2
_05E4:
	.2byte 0x1C64 @ adds r4, r4, #1
	cmp r4, #0xb
	bne _05CC
	pop {r3, r4, r5, r6, pc}

	.global gUnknown_05EC
gUnknown_05EC:
	.2byte 0x479B, 0x7426, 0x11BC, 0x6D4F, 0x11BD, 0x32F1
	.2byte 0x7FD9, 0x2CE7, 0x5DA5, 0x11BD, 0x4610, 0x5DA4
	.2byte 0x4E90, 0x6173, 0x2A84, 0x4E91, 0x106A, 0x75FE
	.2byte 0x29C8, 0x7839, 0x420E, 0x5D1B, 0x7838, 0x12A8

	.2byte 0x3F7D, 0x67B9, 0x26F3, 0x54EF, 0x7C23, 0x26F2
	.2byte 0x6BC6, 0x4137, 0x15AB, 0x730D, 0x6BC7, 0x3B4F
	.2byte 0x5F24, 0x3DDA, 0x253F, 0x1749, 0x3DDB, 0x70E6
	.2byte 0x746C, 0x30F7, 0x531F, 0x6738, 0x531E, 0x1A51

	.2byte 0x1971, 0x5B7D, 0x4ED6, 0x1970, 0x3F27, 0x75CB
	.2byte 0x3D62, 0x128C, 0x74B8, 0x2FAD, 0x74B9, 0x64FD
	.2byte 0x6C9A, 0x4F3A, 0x276D, 0x73EF, 0x38B1, 0x4F3B
	.2byte 0x571E, 0x7EA3, 0x6249, 0x3587, 0x1B7C, 0x3586

	.2byte 0x7AFB, 0x67E4, 0x5C92, 0x67E5, 0x2BCA, 0x438C
	.2byte 0x2E6F, 0x587F, 0x14B7, 0x2E6E, 0x4CB9, 0x6FA2
	.2byte 0x38F0, 0x719E, 0x475A, 0x1F3C, 0x6AD8, 0x475B
	.2byte 0x5199, 0x3264, 0x7B41, 0x49EF, 0x5198, 0x1CD7

	THUMB_FUNC_START sub_06AC
sub_06AC: @ 0x000006AC
	push {r4, r5, lr}
	movs r4, #3
	movs r3, #0
_06B2:
	ldrb r2, [r0]
	rors r3, r4
	movs r5, #4
_06B8:
	eors r3, r2
	lsls r2, r2, #8
	.2byte 0x1E6D @ subs r5, r5, #1
	bgt _06B8
	.2byte 0x1C40 @ adds r0, r0, #1
	.2byte 0x1E49 @ subs r1, r1, #1
	bgt _06B2
	adds r0, r3, #0
	lsls r0, r0, #0x1b
	lsrs r0, r0, #0x1e
	pop {r4, r5, pc}

	UNALIGNED_THUMB_FUNC_START sub_06CE
sub_06CE: @ 0x000006CE
	push {r4, lr}
	movs r4, #0x14
	muls r4, r0, r4
	movs r3, #8
	lsls r3, r3, #0x18
	adds r0, r3, #4
	adds r0, r0, r4
	ldr r1, _0AC0 @=gUnknown_03000064 + 0x24
	adds r1, r1, r4
	movs r2, #0xa
	bl swi_CPUSet
	pop {r4, pc}

	THUMB_FUNC_START ValidateROMHeader
ValidateROMHeader: @ 0x000006E8
	push {r4, r5, r6, lr}
	ldr r1, _0AC4 @=gNintendoLogo + 0x24
	movs r6, #0
_06EE:
	movs r4, #0xff
	cmp r6, #0x98
	bne _06F6
	movs r4, #0x7b
_06F6:
	cmp r6, #0x9a
	bne _06FC
	movs r4, #0xfc
_06FC:
	cmp r6, #0x9c
	bge _070E
	ldrb r2, [r0, r6]
	ldrb r3, [r1, r6]
	ands r2, r4
	.2byte 0x1C76 @ adds r6, r6, #1
	cmp r2, r3
	beq _06EE
	b _0722
_070E:
	movs r4, #0x19
_0710:
	ldrb r2, [r0, r6]
	adds r4, r4, r2
	.2byte 0x1C76 @ adds r6, r6, #1
	cmp r6, #0xba
	blt _0710
	lsls r0, r4, #0x18
	bne _0722
	movs r0, #0
	b _0724
_0722:
	movs r0, #1
_0724:
	pop {r4, r5, r6, pc}

	UNALIGNED_THUMB_FUNC_START sub_0726
sub_0726: @ 0x00000726
	ldr r3, _0AC8 @=gUnknown_03003580
	movs r2, #8
	movs r0, #0x7e
	negs r0, r0
_072E:
	str r0, [r3, r2]
	adds r2, #0x10
	cmp r2, #0x78
	blt _072E
	bx lr

	THUMB_FUNC_START sub_0738
sub_0738: @ 0x00000738
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
	bgt _0766
	movs r6, #0x1a
	muls r6, r2, r6
	subs r2, #0x48
	muls r6, r2, r6
	movs r3, #0x68
	lsls r3, r3, #8
	adds r6, r6, r3
	str r6, [r1, #4]
_0766:
	pop {r6, pc}

	THUMB_FUNC_START sub_0768
sub_0768: @ 0x00000768
	push {r4, r5, r6, r7, lr}
	adds r7, r1, #0
	ldm r0!, {r4, r5, r6}
	adds r6, #0x80
	adds r1, r6, #0
	movs r0, #0x80
	lsls r0, r0, #0x10
	bl swi_Div_t
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

	UNALIGNED_THUMB_FUNC_START sub_079E
sub_079E: @ 0x0000079E
	push {r4, r5, r6, r7, lr}
	ldr r4, [sp, #0x14]
	ldr r5, [sp, #0x18]
	movs r7, #0
_07A6:
	movs r6, #0
_07A8:
	strh r0, [r4, r6]
	adds r0, r0, r1
	.2byte 0x1CB6 @ adds r6, r6, #2
	cmp r6, r2
	blt _07A8
	adds r4, r4, r5
	.2byte 0x1C7F @ adds r7, r7, #1
	cmp r7, r3
	blt _07A6
	pop {r4, r5, r6, r7, pc}

	THUMB_FUNC_START sub_07BC
sub_07BC: @ 0x000007BC
	push {r4, r5, r6, r7, lr}
	movs r7, #2
_07C0:
	ldr r4, _0ACC @=gUnknown_3200
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
	ldr r3, _0AD0 @=PLTT + 0x0200
	adds r3, r6, r3
	strh r4, [r3]
	.2byte 0x1E7F @ subs r7, r7, #1
	bge _07C0
	pop {r4, r5, r6, r7, pc}

	THUMB_FUNC_START swi_SoundBiasChange
swi_SoundBiasChange:
	movs r1, #2
	lsls r1, r1, #8
	mov r12, r1
	ldr r3, _0AD4 @=REG_SOUNDBIAS
	ldrh r2, [r3]
	ldr r3, _0AD4 @=REG_SOUNDBIAS
	lsls r1, r2, #0x16
	lsrs r1, r1, #0x16
	cmp r0, #0
	beq _081C
	cmp r1, r12
	bge _082C
	.2byte 0x1C92 @ adds r2, r2, #2
	b _0822
_081C:
	cmp r1, #0
	ble _082C
	.2byte 0x1E92 @ subs r2, r2, #2
_0822:
	strh r2, [r3]
	movs r2, #8
_0826:
	.2byte 0x1E52 @ subs r2, r2, #1
	bpl _0826
	b swi_SoundBiasChange
_082C:
	bx lr

	UNALIGNED_THUMB_FUNC_START sub_082E
sub_082E: @ 0x0000082E
	ldr r1, _0AD8 @=gGameboyLogoBuffer
	@ movs r2, #0x370
	movs r2, #0x37
	lsls r2, r2, #4
	ldr r0, _0ADC @=gUnknown_332C
	b safecopy32

	THUMB_FUNC_START sub_0838
sub_0838: @ 0x00000838
	ldr r1, _0AD8 @=gGameboyLogoBuffer
	movs r2, #0x24
	ldr r0, _0AE0 @=gNintendoLogo
	b safecopy32

	THUMB_FUNC_START sub_0840
sub_0840: @ 0x00000840
	movs r1, #OAM >> 24
	lsls r1, r1, #0x18
	movs r2, #0x50
	ldr r0, _0AE4 @=gUnknown_369C
	b safecopy32

	UNALIGNED_THUMB_FUNC_START sub_084A
sub_084A: @ 0x0000084A
	ldr r1, _0AE8 @=PLTT + 0x0038
	cmp r0, #0
	beq _0854
	lsls r0, r0, #9
	adds r1, r1, r0
_0854:
	movs r2, #8
	ldr r0, _0AEC @=gUnknown_3264
safecopy32:
	push {r4, r5, lr}
	adds r2, r2, r1
_085C:
	ldr r3, _0ACC @=gUnknown_3200
	cmp r0, r3
	blt _0872
	@ movs r3, #BIOS_END
	movs r3, #4
	lsls r3, r3, #0xc
	cmp r0, r3
	bge _0872
	ldm r0!, {r3}
	stm r1!, {r3}
	cmp r1, r2
	blt _085C
_0872:
	pop {r4, r5, pc}

	THUMB_FUNC_START ReadLogos
ReadLogos: @ 0x00000874
	push {r4, r5, r6, r7, lr}
	sub sp, #0x14
	ldr r1, _0AF0 @=gUnknown_30C0 @ 512, 2, 8, 0
	ldm r1!, {r5, r7}
	add r0, sp, #8
	stm r0!, {r5, r7}
	ldr r0, _0AF4 @=0x0BFE1FE0
	ldr r3, _0AF8 @=ROM_HEADER_DEVICE
	ldrb r3, [r3]
	lsrs r3, r3, #7
	bne _088C
	ldr r0, _0AFC @=0x0BFFFFE0
_088C:
	ldr r1, _0AD8 @=gGameboyLogoBuffer
	movs r2, #0xa
	bl swi_CPUSet
	bl sub_05A4
	ldr r1, _0AC0 @=gUnknown_03000064 + 0x24
	adds r3, r1, #0
	adds r3, #0xae
	ldrb r0, [r3]
	cmp r0, #0x96
	beq _08B0
	ldr r2, _0B00 @=0x85000027
	asrs r3, r2, #0x1f
	str r3, [sp, #0x10]
	add r0, sp, #0x10
	bl swi_CPUSet
_08B0:
	bl sub_082E
	ldr r0, _0AD8 @=gGameboyLogoBuffer
	ldr r1, _0B04 @=gGameboyLogoBuffer2
	bl swi_HuffUnComp_t
	ldr r0, _0B04 @=gGameboyLogoBuffer2
	ldr r1, _0AD8 @=gGameboyLogoBuffer
	bl swi_LZ77UnCompWRAM_t
	movs r7, #0
_08C6:
	lsls r0, r7, #2
	str r0, [sp, #0xc]
	ldr r2, _0AD8 @=gGameboyLogoBuffer
	lsls r0, r7, #8
	adds r0, r0, r2
	ldr r3, _0B08 @=VRAM + 0x00040
	lsls r1, r7, #0xa
	adds r1, r1, r3
	add r2, sp, #8
	bl swi_BitUnPack_t
	.2byte 0x1C7F @ adds r7, r7, #1
	cmp r7, #8
	blt _08C6
	movs r7, #0xe
_08E4:
	movs r4, #3
_08E6:
	ldr r3, _0B08 @=VRAM + 0x00040
	lsls r0, r7, #1
	adds r0, r0, r4
	lsls r0, r0, #8
	adds r0, r0, r3
	ldr r3, _0B0C @=gUnknown_30B0
	ldrh r2, [r3, r7]
	ldr r3, _0B10 @=VRAM + 0x10000
	lsls r1, r4, #4
	adds r1, r1, r2
	lsls r1, r1, #6
	adds r1, r1, r3
	movs r2, #0x80
	bl swi_CPUSet
	.2byte 0x1E64 @ subs r4, r4, #1
	bge _08E6
	.2byte 0x1EBF @ subs r7, r7, #2
	bge _08E4
	ldr r0, _0AC0 @=gUnknown_03000064 + 0x24
	bl sub_094A
	bl sub_0974
	bl sub_0982
	movs r2, #0x20
	str r2, [sp, #4]
	ldr r1, _0B14 @=VRAM + 0x0B880
	str r1, [sp]
	movs r3, #4
	movs r2, #4
	ldr r1, _0B18 @=0x00000202
	ldr r0, _0B1C @=0x00007271
	bl sub_079E
	movs r1, #5
	lsls r1, r1, #0x18
	mvns r0, r1
	strh r0, [r1]
	movs r0, #0
	bl sub_084A
	movs r0, #1
	bl sub_084A
	bl sub_0840
	add sp, #0x14
	pop {r4, r5, r6, r7, pc}

	UNALIGNED_THUMB_FUNC_START sub_094A
sub_094A: @ 0x0000094A
	push {r0, r4, r5, r6, r7, lr}
	ldr r4, _0B20 @=gUnknown_03007FF0 + 7
	strb r0, [r4]
	bl sub_0838
	ldr r0, [sp]
	ldr r1, _0B24 @=gGameboyLogoBuffer + 0x24
	movs r2, #0x4e
	bl swi_CPUSet
	ldr r0, _0AD8 @=gGameboyLogoBuffer
	ldr r1, _0B04 @=gGameboyLogoBuffer2
	bl swi_HuffUnComp_t
	ldr r0, _0B04 @=gGameboyLogoBuffer2
	ldr r2, _0B28 @=0x0000D082
	str r2, [r0]
	ldr r1, _0AD8 @=gGameboyLogoBuffer
	bl swi_Diff16bitUnFilter
	pop {r0, r4, r5, r6, r7, pc}

	THUMB_FUNC_START sub_0974
sub_0974: @ 0x00000974
	push {r0, r4, r5, r6, r7, lr}
	ldr r0, _0AD8 @=gGameboyLogoBuffer
	ldr r1, _0B04 @=gGameboyLogoBuffer2
	ldr r2, _0B2C @=gUnknown_30C8
	bl swi_BitUnPack_t
	pop {r0, r4, r5, r6, r7, pc}

	UNALIGNED_THUMB_FUNC_START sub_0982
sub_0982: @ 0x00000982
	push {r0, r4, r5, r6, r7, lr}
	ldr r6, _0B04 @=gGameboyLogoBuffer2
	ldr r4, _0B30 @=VRAM + 0x024C0
	movs r7, #2
_098A:
	movs r5, #0x34
_098C:
	ldm r6!, {r0, r1, r2, r3}
	stm r4!, {r0, r1, r2, r3}
	.2byte 0x1E6D @ subs r5, r5, #1
	bgt _098C
	adds r4, #0xc0
	.2byte 0x1E7F @ subs r7, r7, #1
	bgt _098A
	movs r7, #3
_099C:
	lsls r3, r7, #0xa
	ldr r0, _0B34 @=VRAM + 0x02040
	adds r0, r0, r3
	ldr r1, _0B38 @=VRAM + 0x16800
	adds r1, r1, r3
	movs r2, #1
	lsls r2, r2, #8
	bl swi_CPUFastSet_t
	.2byte 0x1E7F @ subs r7, r7, #1
	bgt _099C
	mov r0, sp
	str r7, [r0]
	ldr r1, _0AD8 @=gGameboyLogoBuffer
	movs r2, #8
	lsls r2, r2, #8
	bl _0AB2
	pop {r0, r4, r5, r6, r7, pc}

	UNALIGNED_THUMB_FUNC_START swi_RegisterRamReset
swi_RegisterRamReset: @ 0x000009C2
	push {r4, r5, r6, r7, lr}
	sub sp, #4
	adds r7, r0, #0
	ldr r5, _0B3C @=0x85000000
	movs r4, #4
	lsls r4, r4, #0x18
	movs r3, #0
	str r3, [sp]
	movs r1, #0x80
	strh r1, [r4]
	movs r6, #0x80
	tst r6, r7
	beq _0A18
	lsrs r1, r4, #0x11
	adds r1, r1, r4
	movs r2, #8
	bl sub_0AAC
	subs r1, #0x20
	mvns r0, r2
	strh r0, [r1, #2]
	lsrs r1, r4, #0x10
	adds r1, r1, r4
	strb r0, [r1, #0x10]
	adds r1, r4, #4
	movs r2, #8
	bl sub_0AAC
	.2byte 0x1F09 @ subs r1, r1, #4
	movs r2, #0x10
	bl sub_0AAC
	movs r1, #0xb0
	adds r1, r1, r4
	movs r2, #0x18
	bl sub_0AAC
	str r2, [r1, #0x20]
	lsrs r0, r4, #0x12
	strh r0, [r4, #0x20]
	strh r0, [r4, #0x30]
	strh r0, [r4, #0x26]
	strh r0, [r4, #0x36]
_0A18:
	movs r6, #0x20
	ldr r1, _0B40 @=0x04000110
	movs r2, #8
	bl sub_0AAC
	lsrs r2, r4, #0xb
	strh r2, [r1, #4]
	adds r1, #0x10
	movs r2, #7
	strb r2, [r1]
	bl sub_0AAC
	movs r6, #0x40
	tst r6, r7
	beq _0A6A
	movs r1, #0x80
	adds r1, r1, r4
	ldr r0, _0B44 @=0x880E0000
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
	bl sub_0AAC
	subs r1, #0x40
	strb r2, [r1]
	adds r1, #0x20
	movs r2, #8
	bl sub_0AAC
	movs r2, #0
	movs r1, #0x80
	adds r1, r1, r4
	strb r2, [r1, #4]
_0A6A:
	movs r6, #1
	lsrs r1, r4, #1
	lsrs r2, r4, #0xa
	bl sub_0AAC
	movs r6, #8
	movs r1, #6
	lsls r1, r1, #0x18
	lsrs r2, r1, #0xc
	bl sub_0AAC
	movs r6, #0x10
	movs r1, #7
	lsls r1, r1, #0x18
	lsrs r2, r4, #0x12
	bl sub_0AAC
	movs r6, #4
	movs r1, #5
	lsls r1, r1, #0x18
	lsrs r2, r4, #0x12
	bl sub_0AAC
	movs r6, #2
	movs r1, #3
	lsls r1, r1, #0x18
	ldr r2, _0B48 @=0x00001F80
	bl sub_0AAC
	add sp, #4
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	THUMB_FUNC_START sub_0AAC
sub_0AAC: @ 0x00000AAC
	tst r6, r7
	bne _0AB2
	bx lr
_0AB2:
	mov r0, sp
	orrs r2, r5
	b swi_CPUFastSet_t
	.align 2, 0
_0AB8: .4byte sub_2D70
_0ABC: .4byte swi_SoundDriverVSync
_0AC0: .4byte gUnknown_03000064 + 0x24
_0AC4: .4byte gNintendoLogo + 0x24
_0AC8: .4byte gUnknown_03003580
_0ACC: .4byte gUnknown_3200
_0AD0: .4byte PLTT + 0x0200
_0AD4: .4byte REG_SOUNDBIAS
_0AD8: .4byte gGameboyLogoBuffer
_0ADC: .4byte gUnknown_332C
_0AE0: .4byte gNintendoLogo
_0AE4: .4byte gUnknown_369C
_0AE8: .4byte PLTT + 0x0038
_0AEC: .4byte gUnknown_3264
_0AF0: .4byte gUnknown_30C0
_0AF4: .4byte 0x0BFE1FE0
_0AF8: .4byte ROM_HEADER_DEVICE
_0AFC: .4byte 0x0BFFFFE0
_0B00: .4byte 0x85000027
_0B04: .4byte gGameboyLogoBuffer2
_0B08: .4byte VRAM + 0x00040
_0B0C: .4byte gUnknown_30B0
_0B10: .4byte VRAM + 0x10000
_0B14: .4byte VRAM + 0x0B880
_0B18: .4byte 0x00000202
_0B1C: .4byte 0x00007271
_0B20: .4byte gUnknown_03007FF0 + 7
_0B24: .4byte gGameboyLogoBuffer + 0x24
_0B28: .4byte 0x0000D082
_0B2C: .4byte gUnknown_30C8
_0B30: .4byte VRAM + 0x024C0
_0B34: .4byte VRAM + 0x02040
_0B38: .4byte VRAM + 0x16800
_0B3C: .4byte 0x85000000
_0B40: .4byte 0x04000110
_0B44: .4byte 0x880E0000
_0B48: .4byte 0x00001F80

	THUMB_FUNC_START swi_CPUSet
swi_CPUSet: @ 0x00000B4C
	push {r4, r5, lr}
	lsls r4, r2, #0xb
	lsrs r4, r4, #9
	bl CheckDestInWritableRange_t
	beq _0B96
	movs r5, #0
	lsrs r3, r2, #0x1b
	bcc _0B78
	adds r5, r1, r4
	lsrs r3, r2, #0x19
	bcc _0B6E
	ldm r0!, {r3}
_0B66:
	cmp r1, r5
	bge _0B96
	stm r1!, {r3}
	b _0B66
_0B6E:
	cmp r1, r5
	bge _0B96
	ldm r0!, {r3}
	stm r1!, {r3}
	b _0B6E
_0B78:
	lsrs r4, r4, #1
	lsrs r3, r2, #0x19
	bcc _0B8A
	ldrh r3, [r0]
_0B80:
	cmp r5, r4
	bge _0B96
	strh r3, [r1, r5]
	.2byte 0x1CAD @ adds r5, r5, #2
	b _0B80
_0B8A:
	cmp r5, r4
	bge _0B96
	ldrh r3, [r0, r5]
	strh r3, [r1, r5]
	.2byte 0x1CAD @ adds r5, r5, #2
	b _0B8A
_0B96:
	pop {r4, r5}
	pop {r3}
	bx r3

	THUMB_INTERWORK_FALLTHROUGH_2 CheckDestInWritableRange
CheckDestInWritableRange: @ 0x00000BA4
@ start addr: r0
@ size: r12
@ Sets eq if size is 0 or if any write is outside the acceptable range.
	cmp r12, #0
	beq _0BBC
	bic r12, r12, #0xfe000000
	add r12, r0, r12
	tst r0, #0xe000000
	tstne r12, #0xe000000
_0BBC:
	bx lr

	THUMB_INTERWORK_FALLTHROUGH swi_CPUFastSet
swi_CPUFastSet: @ 0x00000BC4
	push {r4, r5, r6, r7, r8, r9, r10, lr}
	lsl r10, r2, #0xb
	lsrs r12, r10, #9
	bl CheckDestInWritableRange
	beq _0C24
	add r10, r1, r10, lsr #9
	lsrs r2, r2, #0x19
	bcc _0C14
	ldr r2, [r0]
	mov r3, r2
	mov r4, r2
	mov r5, r2
	mov r6, r2
	mov r7, r2
	mov r8, r2
	mov r9, r2
_0C04:
	cmp r1, r10
	stmlt r1!, {r2, r3, r4, r5, r6, r7, r8, r9}
	blt _0C04
	b _0C24
_0C14:
	cmp r1, r10
	ldmlt r0!, {r2, r3, r4, r5, r6, r7, r8, r9}
	stmlt r1!, {r2, r3, r4, r5, r6, r7, r8, r9}
	blt _0C14
_0C24:
	pop {r4, r5, r6, r7, r8, r9, r10, lr}
	bx lr

	ARM_FUNC_START swi_BgAffineSet
swi_BgAffineSet: @ 0x00000C2C
	push {r4, r5, r6, r7, r8, r9, r10, r11}
_0C30:
	subs r2, r2, #1
	blt _0CD8
	ldrh r3, [r0, #0x10]
	lsr r3, r3, #8
	adr r12, gUnknown_0D5C
	add r8, r3, #0x40
	and r8, r8, #0xff
	lsl r8, r8, #1
	ldrsh r11, [r8, r12]
	lsl r8, r3, #1
	ldrsh r12, [r8, r12]
	ldrsh r9, [r0, #0xc]
	ldrsh r10, [r0, #0xe]
	mul r8, r11, r9
	asr r3, r8, #0xe
	mul r8, r12, r9
	asr r4, r8, #0xe
	mul r8, r12, r10
	asr r5, r8, #0xe
	mul r8, r11, r10
	asr r6, r8, #0xe
	ldm r0, {r9, r10, r12}
	lsl r11, r12, #0x10
	asr r11, r11, #0x10
	asr r12, r12, #0x10
	rsb r8, r11, #0
	mla r9, r3, r8, r9
	mla r8, r4, r12, r9
	str r8, [r1, #8]
	rsb r8, r11, #0
	mla r10, r5, r8, r10
	rsb r8, r12, #0
	mla r8, r6, r8, r10
	str r8, [r1, #0xc]
	strh r3, [r1]
	rsb r4, r4, #0
	strh r4, [r1, #2]
	strh r5, [r1, #4]
	strh r6, [r1, #6]
	add r0, r0, #0x14
	add r1, r1, #0x10
	b _0C30
_0CD8:
	pop {r4, r5, r6, r7, r8, r9, r10, r11}
	bx lr

	ARM_FUNC_START swi_ObjAffineSet
swi_ObjAffineSet:
	push {r8, r9, r10, r11}
_0CE4:
	subs r2, r2, #1
	blt _0D54
	ldrh r9, [r0, #4]
	lsr r9, r9, #8
	adr r12, gUnknown_0D5C
	add r8, r9, #0x40
	and r8, r8, #0xff
	lsl r8, r8, #1
	ldrsh r11, [r8, r12]
	lsl r8, r9, #1
	ldrsh r12, [r8, r12]
	ldrsh r9, [r0]
	ldrsh r10, [r0, #2]
	mul r8, r11, r9
	asr r8, r8, #0xe
	strh r8, [r1], r3
	mul r8, r12, r9
	asr r8, r8, #0xe
	rsb r8, r8, #0
	strh r8, [r1], r3
	mul r8, r12, r10
	asr r8, r8, #0xe
	strh r8, [r1], r3
	mul r8, r11, r10
	asr r8, r8, #0xe
	strh r8, [r1], r3
	add r0, r0, #8
	b _0CE4
_0D54:
	pop {r8, r9, r10, r11}
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
	push {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, sp, #8
	ldrh r7, [r2]
	movs r12, r7
	bl CheckDestInWritableRange
	beq _1004
	ldrb r6, [r2, #2]
	rsb r10, r6, #8
	mov lr, #0
	ldr r11, [r2, #4]
	lsr r8, r11, #0x1f
	ldr r11, [r2, #4]
	lsl r11, r11, #1
	lsr r11, r11, #1
	str r11, [sp, #4]
	ldrb r2, [r2, #3]
	mov r3, #0
_0FA4:
	subs r7, r7, #1
	blt _1004
	mov r11, #0xff
	asr r5, r11, r10
	ldrb r9, [r0], #1
	mov r4, #0
_0FBC:
	cmp r4, #8
	bge _0FA4
	and r11, r9, r5
	lsrs r12, r11, r4
	cmpeq r8, #0
	beq _0FDC
	ldr r11, [sp, #4]
	add r12, r12, r11
_0FDC:
	orr lr, lr, r12, lsl r3
	add r3, r3, r2
	cmp r3, #0x20
	blt _0FF8
	str lr, [r1], #4
	mov lr, #0
	mov r3, #0
_0FF8:
	lsl r5, r5, r6
	add r4, r4, r6
	b _0FBC
_1004:
	add sp, sp, #8
	pop {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	bx lr

	THUMB_INTERWORK_FALLTHROUGH swi_HuffUnComp
swi_HuffUnComp: @ 0x00001014
	push {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, sp, #8
	movs r12, #0x2000000
	bl CheckDestInWritableRange
	beq _10EC
	add r2, r0, #4
	add r7, r2, #1
	ldrb r10, [r0]
	and r4, r10, #0xf
	mov r3, #0
	mov lr, #0
	and r10, r4, #7
	add r11, r10, #4
	str r11, [sp, #4]
	ldr r10, [r0]
	lsr r12, r10, #8
	ldrb r10, [r2]
	add r10, r10, #1
	add r0, r2, r10, lsl #1
	mov r2, r7
_1064:
	cmp r12, #0
	ble _10EC
	mov r8, #0x20
	ldr r5, [r0], #4
_1074:
	subs r8, r8, #1
	blt _1064
	mov r10, #1
	and r9, r10, r5, lsr #31
	ldrb r6, [r2]
	lsl r6, r6, r9
	lsr r10, r2, #1
	lsl r10, r10, #1
	ldrb r11, [r2]
	and r11, r11, #0x3f
	add r11, r11, #1
	add r10, r10, r11, lsl #1
	add r2, r10, r9
	tst r6, #0x80
	beq _10DC
	lsr r3, r3, r4
	ldrb r10, [r2]
	rsb r11, r4, #0x20
	orr r3, r3, r10, lsl r11
	mov r2, r7
	add lr, lr, #1
	ldr r11, [sp, #4]
	cmp lr, r11
	streq r3, [r1], #4
	subeq r12, r12, #4
	moveq lr, #0
_10DC:
	cmp r12, #0
	lslgt r5, r5, #1
	bgt _1074
	b _1064
_10EC:
	add sp, sp, #8
	pop {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	bx lr

	THUMB_INTERWORK_FALLTHROUGH swi_LZ77UnCompWRAM
swi_LZ77UnCompWRAM: @ 0x000010FC
	push {r4, r5, r6, lr}
	ldr r5, [r0], #4
	lsr r2, r5, #8
	movs r12, r2
	bl CheckDestInWritableRange
	beq _118C
_1114:
	cmp r2, #0
	ble _118C
	ldrb lr, [r0], #1
	mov r4, #8
_1124:
	subs r4, r4, #1
	blt _1114
	tst lr, #0x80
	bne _1144
	ldrb r6, [r0], #1
	strb r6, [r1], #1
	sub r2, r2, #1
	b _117C
_1144:
	ldrb r5, [r0]
	mov r6, #3
	add r3, r6, r5, asr #4
	ldrb r6, [r0], #1
	and r5, r6, #0xf
	lsl r12, r5, #8
	ldrb r6, [r0], #1
	orr r5, r6, r12
	add r12, r5, #1
	sub r2, r2, r3
_116C:
	ldrb r5, [r1, -r12]
	strb r5, [r1], #1
	subs r3, r3, #1
	bgt _116C
_117C:
	cmp r2, #0
	lslgt lr, lr, #1
	bgt _1124
	b _1114
_118C:
	pop {r4, r5, r6, lr}
	bx lr

	ARM_FUNC_START swi_LZ77UnCompVRAM
swi_LZ77UnCompVRAM: @ 0x00001194
	push {r4, r5, r6, r7, r8, r9, r10, lr}
	mov r3, #0
	ldr r8, [r0], #4
	lsr r10, r8, #8
	mov r2, #0
	movs r12, r10
	bl CheckDestInWritableRange
	beq _1270
_11B4:
	cmp r10, #0
	ble _1270
	ldrb r6, [r0], #1
	mov r7, #8
_11C4:
	subs r7, r7, #1
	blt _11B4
	tst r6, #0x80
	bne _11F0
	ldrb r9, [r0], #1
	orr r3, r3, r9, lsl r2
	sub r10, r10, #1
	eors r2, r2, #8
	strheq r3, [r1], #2
	moveq r3, #0
	b _1260
_11F0:
	ldrb r9, [r0]
	mov r8, #3
	add r5, r8, r9, asr #4
	ldrb r9, [r0], #1
	and r8, r9, #0xf
	lsl r4, r8, #8
	ldrb r9, [r0], #1
	orr r8, r9, r4
	add r4, r8, #1
	rsb r8, r2, #8
	and r9, r4, #1
	eor lr, r8, r9, lsl #3
	sub r10, r10, r5
_1224:
	eor lr, lr, #8
	rsb r8, r2, #8
	add r8, r4, r8, lsr #3
	lsr r8, r8, #1
	lsl r8, r8, #1
	ldrh r9, [r1, -r8]
	mov r8, #0xff
	and r8, r9, r8, lsl lr
	asr r8, r8, lr
	orr r3, r3, r8, lsl r2
	eors r2, r2, #8
	strheq r3, [r1], #2
	moveq r3, #0
	subs r5, r5, #1
	bgt _1224
_1260:
	cmp r10, #0
	lslgt r6, r6, #1
	bgt _11C4
	b _11B4
_1270:
	pop {r4, r5, r6, r7, r8, r9, r10, lr}
	bx lr

	UNALIGNED_THUMB_FUNC_START swi_RLUnCompWRAM
swi_RLUnCompWRAM: @ 0x00001278
	push {r4, r5, r6, r7, lr}
	ldm r0!, {r3}
	lsrs r7, r3, #8
	adds r4, r7, #0
	bl CheckDestInWritableRange_t
	beq _12BA
_1286:
	cmp r7, #0
	ble _12BA
	ldrb r4, [r0]
	.2byte 0x1C40 @ adds r0, r0, #1
	lsls r2, r4, #0x19
	lsrs r2, r2, #0x19
	lsrs r3, r4, #8
	bhs _12A8
	.2byte 0x1C52 @ adds r2, r2, #1
	subs r7, r7, r2
_129A:
	ldrb r3, [r0]
	strb r3, [r1]
	.2byte 0x1C40 @ adds r0, r0, #1
	.2byte 0x1C49 @ adds r1, r1, #1
	.2byte 0x1E52 @ subs r2, r2, #1
	bgt _129A
	b _1286
_12A8:
	.2byte 0x1CD2 @ adds r2, r2, #3
	subs r7, r7, r2
	ldrb r5, [r0]
	.2byte 0x1C40 @ adds r0, r0, #1
_12B0:
	strb r5, [r1]
	.2byte 0x1C49 @ adds r1, r1, #1
	.2byte 0x1E52 @ subs r2, r2, #1
	bgt _12B0
	b _1286
_12BA:
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
	beq _132A
	movs r4, #0
_12D4:
	cmp r5, #0
	ble _132A
	ldrb r3, [r0]
	str r3, [sp, #4]
	.2byte 0x1C40 @ adds r0, r0, #1
	ldr r3, [sp, #4]
	lsls r2, r3, #0x19
	lsrs r2, r2, #0x19
	ldr r6, [sp, #4]
	lsrs r3, r6, #8
	bhs _1308
	.2byte 0x1C52 @ adds r2, r2, #1
	subs r5, r5, r2
_12EE:
	ldrb r6, [r0]
	lsls r6, r4
	orrs r7, r6
	.2byte 0x1C40 @ adds r0, r0, #1
	movs r3, #8
	eors r4, r3
	bne _1302
	strh r7, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
	movs r7, #0
_1302:
	.2byte 0x1E52 @ subs r2, r2, #1
	bgt _12EE
	b _12D4
_1308:
	.2byte 0x1CD2 @ adds r2, r2, #3
	subs r5, r5, r2
	ldrb r6, [r0]
	str r6, [sp, #8]
	.2byte 0x1C40 @ adds r0, r0, #1
_1312:
	ldr r6, [sp, #8]
	lsls r6, r4
	orrs r7, r6
	movs r3, #8
	eors r4, r3
	bne _1324
	strh r7, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
	movs r7, #0
_1324:
	.2byte 0x1E52 @ subs r2, r2, #1
	bgt _1312
	b _12D4
_132A:
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
	beq _1356
	ldrb r2, [r0]
	.2byte 0x1C40 @ adds r0, r0, #1
	strb r2, [r1]
	.2byte 0x1C49 @ adds r1, r1, #1
_1346:
	.2byte 0x1E64 @ subs r4, r4, #1
	ble _1356
	ldrb r3, [r0]
	adds r2, r3, r2
	.2byte 0x1C40 @ adds r0, r0, #1
	strb r2, [r1]
	.2byte 0x1C49 @ adds r1, r1, #1
	b _1346
_1356:
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
	beq _1392
	movs r4, #8
	ldrb r7, [r0]
	.2byte 0x1C40 @ adds r0, r0, #1
	adds r2, r7, #0
_1372:
	.2byte 0x1E6D @ subs r5, r5, #1
	ble _1392
	ldrb r3, [r0]
	adds r7, r3, r7
	.2byte 0x1C40 @ adds r0, r0, #1
	lsls r6, r7, #0x18
	lsrs r6, r6, #0x18
	lsls r6, r4
	orrs r2, r6
	movs r3, #8
	eors r4, r3
	bne _1372
	strh r2, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
	movs r2, #0
	b _1372
_1392:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	UNALIGNED_THUMB_FUNC_START swi_Diff16bitUnFilter
swi_Diff16bitUnFilter: @ 0x00001398
	push {r4, lr}
	ldm r0!, {r4}
	lsrs r4, r4, #8
	bl CheckDestInWritableRange_t
	beq _13BC
	ldrh r2, [r0]
	.2byte 0x1C80 @ adds r0, r0, #2
	strh r2, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
_13AC:
	.2byte 0x1EA4 @ subs r4, r4, #2
	ble _13BC
	ldrh r3, [r0]
	adds r2, r3, r2
	.2byte 0x1C80 @ adds r0, r0, #2
	strh r2, [r1]
	.2byte 0x1C89 @ adds r1, r1, #2
	b _13AC
_13BC:
	pop {r4}
	pop {r2}

	THUMB_FUNC_START sub_13C0
sub_13C0: @ 0x000013C0
	bx r2

	UNALIGNED_THUMB_FUNC_START sub_13C2
sub_13C2: @ 0x000013C2
	bx r1

	THUMB_FUNC_START swi_MusicPlayerOpen
swi_MusicPlayerOpen: @ 0x000013C4
	push {r4, r5, r7, lr}
	adds r4, r2, #0
	adds r5, r1, #0
	adds r7, r0, #0
	cmp r2, #1
	blt _141E
	cmp r4, #0x10
	ble _13D6
	movs r4, #0x10
_13D6:
	adds r0, r7, #0
	bl SoundMainBTM
	str r5, [r7, #0x2c]
	ldr r0, _1424 @=0x80000000
	strb r4, [r7, #8]
	str r0, [r7, #4]
	movs r0, #0
	b _13F2
_13E8:
	subs r1, r4, #1
	lsls r4, r1, #0x18
	lsrs r4, r4, #0x18
	strb r0, [r5]
	adds r5, #0x50
_13F2:
	cmp r4, #0
	bgt _13E8
	ldr r1, _1428 @=gUnknown_03007FC0
	ldr r4, _142C @=0x68736D53
	ldr r1, [r1, #0x30]
	ldr r2, [r1]
	cmp r2, r4
	bne _141E
	adds r2, #1
	str r2, [r1]
	ldr r2, [r1, #0x20]
	cmp r2, #0
	beq _1414
	str r2, [r7, #0x38]
	ldr r2, [r1, #0x24]
	str r2, [r7, #0x3c]
	str r0, [r1, #0x20]
_1414:
	ldr r0, _1430 @=sub_2148
	str r7, [r1, #0x24]
	str r0, [r1, #0x20]
	str r4, [r1]
	str r4, [r7, #0x34]
_141E:
	pop {r4, r5, r7}
	pop {r3}
	bx r3
	.align 2, 0
_1424: .4byte 0x80000000
_1428: .4byte gUnknown_03007FC0
_142C: .4byte 0x68736D53
_1430: .4byte sub_2148

	THUMB_FUNC_START swi_MusicPlayerStart
swi_MusicPlayerStart: @ 0x00001434
	push {r4, r5, r6, r7, lr}
	adds r7, r0, #0
	ldr r0, [r0, #0x34]
	ldr r3, _14BC @=0x68736D53
	adds r4, r1, #0
	cmp r0, r3
	bne _14B4
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
	b _1482
_146A:
	adds r0, r7, #0
	adds r1, r5, #0
	bl TrackStop
	movs r0, #0xc0
	strb r0, [r5]
	lsls r0, r6, #2
	adds r0, r0, r4
	ldr r0, [r0, #8]
	str r0, [r5, #0x40]
	adds r5, #0x50
	adds r6, #1
_1482:
	ldrb r0, [r4]
	cmp r6, r0
	bge _14A0
	ldrb r0, [r7, #8]
	cmp r0, r6
	bgt _146A
	b _14A0
_1490:
	adds r0, r7, #0
	adds r1, r5, #0
	bl TrackStop
	movs r0, #0
	strb r0, [r5]
	adds r5, #0x50
	adds r6, #1
_14A0:
	ldrb r0, [r7, #8]
	cmp r0, r6
	bgt _1490
	ldrb r0, [r4, #3]
	lsrs r1, r0, #8
	bcc _14B0
	bl swi_SoundDriverMode
_14B0:
	ldr r0, _14BC @=0x68736D53
	str r0, [r7, #0x34]
_14B4:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3
	.align 2, 0
_14BC: .4byte 0x68736D53

	THUMB_FUNC_START swi_MusicPlayerStop
swi_MusicPlayerStop: @ 0x000014C0
	push {r4, r5, r6, r7, lr}
	adds r7, r0, #0
	ldr r0, [r0, #0x34]
	ldr r6, _14F8 @=0x68736D53
	cmp r0, r6
	bne _14F0
	adds r0, #1
	str r0, [r7, #0x34]
	ldr r0, [r7, #4]
	lsls r3, r6, #0x1f
	orrs r0, r3
	str r0, [r7, #4]
	ldrb r5, [r7, #8]
	ldr r4, [r7, #0x2c]
	b _14EA
_14DE:
	adds r0, r7, #0
	adds r1, r4, #0
	bl TrackStop
	adds r4, #0x50
	subs r5, #1
_14EA:
	cmp r5, #0
	bgt _14DE
	str r6, [r7, #0x34]
_14F0:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3
	.align 2, 0
_14F8: .4byte 0x68736D53

	THUMB_FUNC_START swi_MusicPlayerContinue
swi_MusicPlayerContinue: @ 0x000014FC
	ldr r2, [r0, #0x34]
	ldr r1, _1510 @=0x68736D53
	cmp r2, r1
	bne _150E
	ldr r2, [r0, #4]
	str r1, [r0, #0x34]
	lsls r2, r2, #1
	lsrs r2, r2, #1
	str r2, [r0, #4]
_150E:
	bx lr
	.align 2, 0
_1510: .4byte 0x68736D53

	THUMB_FUNC_START swi_MusicPlayerFadeOut
swi_MusicPlayerFadeOut: @ 0x00001514
	push {r7}
	ldr r7, [r0, #0x34]
	ldr r2, _1530 @=0x68736D53
	cmp r7, r2
	bne _152A
	strh r1, [r0, #0x26]
	strh r1, [r0, #0x24]
	movs r1, #0xff
	adds r1, #1
	strh r1, [r0, #0x28]
	str r2, [r0, #0x34]
_152A:
	pop {r7}
	bx lr
	.align 2, 0
_1530: .4byte 0x68736D53

	THUMB_FUNC_START FadeOutBody
FadeOutBody: @ 0x00001534
	push {r4, r5, r6, r7, lr}
	adds r7, r0, #0
	ldrh r0, [r0, #0x24]
	cmp r0, #0
	beq _1572
	ldrh r1, [r7, #0x26]
	subs r1, #1
	lsls r1, r1, #0x10
	lsrs r1, r1, #0x10
	strh r1, [r7, #0x26]
	bne _1572
	ldrh r1, [r7, #0x28]
	subs r1, #0x10
	strh r1, [r7, #0x28]
	lsls r1, r1, #0x10
	asrs r1, r1, #0x10
	cmp r1, #0
	bgt _1578
	ldrb r5, [r7, #8]
	ldr r4, [r7, #0x2c]
	movs r6, #0
	b _156E
_1560:
	adds r0, r7, #0
	adds r1, r4, #0
	bl TrackStop
	strb r6, [r4]
	adds r4, #0x50
	subs r5, #1
_156E:
	cmp r5, #0
	bgt _1560
_1572:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3

	THUMB_FUNC_START _1578
_1578:
	strh r0, [r7, #0x26]
	ldrb r1, [r7, #8]
	ldr r0, [r7, #0x2c]
	b _1596
_1580:
	ldrb r2, [r0]
	lsrs r3, r2, #8
	bcc _1592
	ldrh r3, [r7, #0x28]
	lsrs r3, r3, #2
	strb r3, [r0, #0x13]
	movs r3, #3
	orrs r2, r3
	strb r2, [r0]
_1592:
	adds r0, #0x50
	subs r1, #1
_1596:
	cmp r1, #0
	bgt _1580
	b _1572

	THUMB_FUNC_START TrkVolPitSet
TrkVolPitSet: @ 0x0000159C
	push {r4, r5, r7, lr}
	ldrb r5, [r1]
	adds r7, r1, #0
	lsrs r1, r5, #1
	bcc _1608
	ldrb r1, [r7, #0x12]
	ldrb r2, [r7, #0x13]
	ldrb r4, [r7, #0x18]
	muls r1, r2, r1
	lsrs r2, r1, #5
	cmp r4, #1
	bne _15BA
	movs r3, #0x16
	ldrsb r1, [r7, r3]
	adds r2, r1, r2
_15BA:
	movs r3, #0x14
	ldrsb r1, [r7, r3]
	lsls r1, r1, #1
	movs r3, #0x15
	ldrsb r3, [r7, r3]
	adds r1, r1, r3
	cmp r4, #2
	bne _15D0
	movs r3, #0x16
	ldrsb r3, [r7, r3]
	adds r1, r3, r1
_15D0:
	movs r3, #0x80
	cmn r1, r3
	bge _15DA
	negs r1, r3
	b _15E0
_15DA:
	cmp r1, #0x7f
	ble _15E0
	movs r1, #0x7f
_15E0:
	adds r3, r1, #7
	adds r3, #0x79
	muls r3, r2, r3
	lsrs r3, r3, #8
	lsls r3, r3, #0x18
	lsrs r3, r3, #0x18
	cmp r3, #0xff
	bls _15F2
	movs r3, #0xff
_15F2:
	strb r3, [r7, #0x10]
	movs r3, #0x7f
	subs r1, r3, r1
	muls r1, r2, r1
	lsrs r1, r1, #8
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	cmp r1, #0xff
	bls _1606
	movs r1, #0xff
_1606:
	strb r1, [r7, #0x11]
_1608:
	lsrs r1, r5, #3
	bcc _1646
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
	bne _1640
	movs r3, #0x16
	ldrsb r2, [r7, r3]
	lsls r2, r2, #4
	adds r1, r2, r1
_1640:
	asrs r2, r1, #8
	strb r2, [r7, #8]
	strb r1, [r7, #9]
_1646:
	ldr r2, _1660 @=gUnknown_03007FC0
	adds r1, r7, #0
	ldr r2, [r2, #0x30]
	ldr r2, [r2, #0x3c]
	bl sub_13C0
	ldrb r0, [r7]
	movs r3, #5
	bics r0, r3
	strb r0, [r7]
	pop {r4, r5, r7}
	pop {r3}
	bx r3
	.align 2, 0
_1660: .4byte gUnknown_03007FC0

	THUMB_FUNC_START swi_SoundDriverInit
swi_SoundDriverInit: @ 0x00001664
	push {r3, r7, lr}
	adds r7, r0, #0
	ldr r1, _16DC @=REG_DMA1DAD
	movs r0, #0
	strh r0, [r1, #6]
	strh r0, [r1, #0x12]
	ldr r0, _16E0 @=REG_SOUNDCNT
	movs r2, #0x8f
	strh r2, [r0, #4]
	ldr r2, _16E4 @=0x0000A90E
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
	ldr r0, _16E8 @=REG_FIFO_A
	movs r3, #0x13
	lsls r3, r3, #7
	str r0, [r1]
	adds r0, r7, r3
	str r0, [r1, #8]
	ldr r0, _16EC @=REG_FIFO_B
	ldr r2, _16F4 @=0x050003EC
	str r0, [r1, #0xc]
	ldr r0, _16F0 @=gUnknown_03007FC0
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
	ldr r0, _16F8 @=sub_2424
	str r0, [r7, #0x38]
	ldr r0, _16FC @=sub_1708
	str r0, [r7, #0x28]
	str r0, [r7, #0x2c]
	str r0, [r7, #0x30]
	str r0, [r7, #0x3c]
	ldr r0, _1700 @=gJumpList
	str r0, [r7, #0x34]
	movs r0, #1
	lsls r0, r0, #0x12
	bl SampleFreqSet
	ldr r0, _1704 @=0x68736D53
	str r0, [r7]
	pop {r3, r7}
	pop {r3}
	bx r3
	.align 2, 0
_16DC: .4byte REG_DMA1DAD
_16E0: .4byte REG_SOUNDCNT
_16E4: .4byte 0x0000A90E
_16E8: .4byte REG_FIFO_A
_16EC: .4byte REG_FIFO_B
_16F0: .4byte gUnknown_03007FC0
_16F4: .4byte 0x050003EC
_16F8: .4byte sub_2424
_16FC: .4byte sub_1708
_1700: .4byte gJumpList
_1704: .4byte 0x68736D53

	THUMB_FUNC_START sub_1708
sub_1708: @ 0x00001708
	bx lr

	UNALIGNED_THUMB_FUNC_START SampleFreqSet
SampleFreqSet: @ 0x0000170A
	push {r4, r7, lr}
	ldr r1, _1784 @=gUnknown_03007FC0
	movs r3, #0xf
	lsls r3, r3, #0x10
	ands r0, r3
	ldr r7, [r1, #0x30]
	lsrs r0, r0, #0x10
	strb r0, [r7, #8]
	ldr r1, _1788 @=gUnknown_31E8
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
	ldr r0, _178C @=0x00091D1B
	ldr r3, _1790 @=0x00001388
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
	ldr r4, _1794 @=REG_TM0CNT
	movs r0, #0
	strh r0, [r4, #2]
	ldr r0, [r7, #0x10]
	ldr r1, _1798 @=0x00044940
	bl swi_DivArm_t
	movs r1, #1
	lsls r1, r1, #0x10
	subs r0, r1, r0
	strh r0, [r4]
	bl swi_SoundDriverVSyncOn
	movs r0, #1
	lsls r0, r0, #0x1a
_176E:
	ldrb r1, [r0, #6]
	cmp r1, #0x9f
	beq _176E
_1774:
	ldrb r1, [r0, #6]
	cmp r1, #0x9f
	bne _1774
	movs r0, #0x80
	strh r0, [r4, #2]
	pop {r4, r7}
	pop {r3}
	bx r3
	.align 2, 0
_1784: .4byte gUnknown_03007FC0
_1788: .4byte gUnknown_31E8
_178C: .4byte 0x00091D1B
_1790: .4byte 0x00001388
_1794: .4byte REG_TM0CNT
_1798: .4byte 0x00044940

	THUMB_FUNC_START swi_SoundDriverMode
swi_SoundDriverMode: @ 0x0000179C
	push {r4, r5, r7, lr}
	ldr r1, _1818 @=gUnknown_03007FC0
	ldr r5, _181C @=0x68736D53
	ldr r7, [r1, #0x30]
	ldr r1, [r7]
	cmp r1, r5
	bne _1812
	adds r1, #1
	str r1, [r7]
	lsls r1, r0, #0x18
	lsrs r1, r1, #0x18
	beq _17BA
	lsls r1, r1, #0x19
	lsrs r1, r1, #0x19
	strb r1, [r7, #5]
_17BA:
	movs r1, #0xf
	lsls r1, r1, #8
	ands r1, r0
	beq _17D6
	lsrs r1, r1, #8
	strb r1, [r7, #6]
	movs r1, #0xc
	movs r3, #0
	adds r2, r7, #7
	adds r2, #0x49
_17CE:
	strb r3, [r2]
	adds r2, #0x40
	subs r1, #1
	bne _17CE
_17D6:
	movs r1, #0xf
	lsls r1, r1, #0xc
	ands r1, r0
	beq _17E2
	lsrs r1, r1, #0xc
	strb r1, [r7, #7]
_17E2:
	movs r1, #0xb
	lsls r1, r1, #0x14
	ands r1, r0
	beq _17FE
	movs r3, #3
	lsls r3, r3, #0x14
	ldr r2, _1820 @=REG_SOUNDCNT
	ands r1, r3
	ldrb r3, [r2, #9]
	lsrs r1, r1, #0xe
	lsls r3, r3, #0x1a
	lsrs r3, r3, #0x1a
	orrs r1, r3
	strb r1, [r2, #9]
_17FE:
	movs r4, #0xf
	lsls r4, r4, #0x10
	ands r4, r0
	beq _1810
	bl swi_SoundDriverVSyncOff
	adds r0, r4, #0
	bl SampleFreqSet
_1810:
	str r5, [r7]
_1812:
	pop {r4, r5, r7}
	pop {r3}
	bx r3
	.align 2, 0
_1818: .4byte gUnknown_03007FC0
_181C: .4byte 0x68736D53
_1820: .4byte REG_SOUNDCNT

	THUMB_FUNC_START swi_SoundChannelClear
swi_SoundChannelClear: @ 0x00001824
	push {r4, r5, r6, r7, lr}
	ldr r0, _1870 @=gUnknown_03007FC0
	ldr r6, _1874 @=0x68736D53
	ldr r7, [r0, #0x30]
	ldr r0, [r7]
	cmp r0, r6
	bne _1868
	adds r0, #1
	str r0, [r7]
	adds r0, r7, #7
	movs r1, #0xc
	adds r0, #0x49
_183C:
	movs r2, #0
	strb r2, [r0]
	adds r0, #0x40
	subs r1, #1
	cmp r1, #0
	bgt _183C
	ldr r5, [r7, #0x1c]
	cmp r5, #0
	beq _1866
	movs r4, #1
_1850:
	lsls r0, r4, #0x18
	lsrs r0, r0, #0x18
	ldr r1, [r7, #0x2c]
	bl sub_13C2
	adds r4, #1
	adds r5, #0x40
	cmp r4, #4
	ble _1850
	movs r2, #0
	strb r2, [r5]
_1866:
	str r6, [r7]
_1868:
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3
	.align 2, 0
_1870: .4byte gUnknown_03007FC0
_1874: .4byte 0x68736D53

	THUMB_FUNC_START swi_SoundDriverVSyncOff
swi_SoundDriverVSyncOff: @ 0x00001878
	push {r3, r7, lr}
	ldr r0, _18B8 @=gUnknown_03007FC0
	ldr r3, _18BC @=0x68736D53
	ldr r7, [r0, #0x30]
	ldr r0, [r7]
	cmp r0, r3
	bcc _18B0
	adds r3, #1
	cmp r0, r3
	bhi _18B0
	adds r0, #1
	str r0, [r7]
	movs r0, #0
	ldr r1, _18C0 @=REG_DMA1DAD
	movs r3, #0x35
	strh r0, [r1, #6]
	strh r0, [r1, #0x12]
	strb r0, [r7, #4]
	lsls r3, r3, #4
	adds r1, r7, r3
	str r0, [sp]
	mov r0, sp
	ldr r2, _18C4 @=PLTT + 0x0318
	bl swi_CPUSet
	ldr r0, [r7]
	subs r0, #1
	str r0, [r7]
_18B0:
	pop {r3, r7}
	pop {r3}
	bx r3
	.align 2, 0
_18B8: .4byte gUnknown_03007FC0
_18BC: .4byte 0x68736D53
_18C0: .4byte REG_DMA1DAD
_18C4: .4byte PLTT + 0x0318

	THUMB_FUNC_START swi_SoundDriverVSyncOn
swi_SoundDriverVSyncOn: @ 0x000018C8
	movs r1, #0x5b
	ldr r0, _18D4 @=REG_DMA1DAD
	lsls r1, r1, #9
	strh r1, [r0, #6]
	strh r1, [r0, #0x12]
	bx lr
	.align 2, 0
_18D4: .4byte REG_DMA1DAD

	UNALIGNED_THUMB_FUNC_START swi_MIDIKey2Freq
swi_MIDIKey2Freq: @ 0x000018D8
	push {r4, r5, r6, r7, lr}
	lsls r2, r2, #0x18
	adds r7, r0, #0
	cmp r1, #0xb2
	ble _18E6
	ldr r2, _1920 @=0xFF000000
	movs r1, #0xb2
_18E6:
	ldr r0, _1924 @=gUnknown_3104
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
_1920: .4byte 0xFF000000
_1924: .4byte gUnknown_3104

	THUMB_FUNC_START DoSystemBoot
DoSystemBoot: @ 0x00001928
	push {r4, r5, r6, r7, lr}
	sub sp, #0x34
	movs r1, #0
	movs r0, #0
	str r0, [sp, #0x14]
	movs r0, #0x10
	str r0, [sp, #0xc]
	mvns r7, r1
	movs r0, #0xff  @ RESET_ALL
	str r1, [sp, #0x10]
	str r1, [sp]
	bl swi_RegisterRamReset
	ldr r0, _1D2C @=REG_POSTFLG
	movs r5, #1
	strb r5, [r0]
	movs r0, #1
	bl swi_SoundBiasChange
	@ Turn on VBlank interrupt
	ldr r6, _1D30 @=REG_IE
	movs r0, #8  @ REG_DISPCNT >> 23
	lsls r1, r0, #0x17
	strh r5, [r6]  @ INTR_FLAG_VBLANK
	strh r0, [r1, #REG_OFFSET_DISPSTAT]  @ VBLANK_INTR_ENABLE
	@ Test for CGB
	ldrh r0, [r6, #REG_OFFSET_WAITCNT - REG_OFFSET_IE]
	lsrs r0, r0, #0xf
	beq _1962
	bl SwitchToCGBMode
	@ noreturn
_1962:
	bl ReadLogos
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
	ldr r1, _1D38 @=REG_WIN0H
	ldr r0, _1D34 @=0x10003F5F
	str r0, [r1, #0x10]
	bl sub_0726
	bl sub_2D68
	ldr r0, _1D3C @=gSoundDriver
	bl swi_SoundDriverInit
	ldr r0, _1D40 @=0x00940A00
	bl swi_SoundDriverMode
	ldr r1, _1D44 @=gUnknown_0300372C
	ldr r0, _1D48 @=gUnknown_030036EC
	movs r2, #6
	bl swi_MusicPlayerOpen
	ldr r1, _1D4C @=gUnknown_0300394C
	ldr r0, _1D50 @=gUnknown_0300390C
	movs r2, #6
	bl swi_MusicPlayerOpen
	b _1C62
_19B4:
	movs r5, #7
	b _1B0A
_19B8:
	movs r0, #6
	subs r2, r0, r5
	lsls r0, r2, #2
	adds r0, r0, r2
	adds r0, #8
	cmp r0, r7
	str r2, [sp, #0x30]
	bgt _19D2
	ldr r3, _1D54 @=gUnknown_03003564
	lsls r1, r5, #2
	ldr r2, [r3, r1]
	adds r2, #1
	str r2, [r3, r1]
_19D2:
	ldr r3, _1D54 @=gUnknown_03003564
	lsls r1, r5, #2
	ldr r2, [r3, r1]
	ldr r3, _1D58 @=gUnknown_03003580
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
	bge _1AC2
	cmp r0, r7
	bgt _19FA
	adds r6, #2
	str r6, [r1, #8]
_19FA:
	lsls r0, r5, #0x10
	asrs r0, r0, #0x10
	ldr r1, [sp, #0x18]
	bl sub_0738
	movs r0, #0x14
	muls r0, r5, r0
	ldr r1, _1D5C @=gUnknown_030035F0
	adds r1, r0, r1
	str r1, [sp, #0x28]
	str r1, [sp, #0x24]
	ldr r0, [sp, #0x18]
	bl sub_0768
	lsls r0, r5, #5
	ldr r3, _1D60 @=OAM + 0x26
	movs r2, #1
	adds r1, r0, r3
	ldr r0, [sp, #0x24]
	movs r3, #8
	adds r0, #0xc
	bl swi_ObjAffineSet_t
	movs r3, #0x60
	cmn r6, r3
	ble _1AAC
	ldr r0, [r4]
	lsls r2, r3, #3
	orrs r2, r0
	movs r0, #0x3f
	mvns r0, r0
	adds r1, r0, #0
	cmp r6, r0
	str r2, [r4]
	bge _1A44
	cmp r5, #4
	bge _1A84
_1A44:
	movs r3, #0x4b
	cmn r6, r3
	blt _1A84
	cmp r6, #0
	bge _1A76
	ldrh r0, [r4]
	movs r3, #1
	lsls r3, r3, #0xf
	orrs r0, r3
	strh r0, [r4]
	ldr r0, [sp, #0x2c]
	ldr r2, _1D64 @=gUnknown_369C
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
	b _1A84
_1A76:
	movs r3, #3
	lsls r3, r3, #8
	bics r2, r3
	movs r0, #0xf
	mvns r0, r0
	lsls r1, r0, #1
	str r2, [r4]
_1A84:
	ldr r2, [sp, #0x28]
	ldr r3, _1D68 @=0xFE00FFFF
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
_1AAC:
	negs r0, r6
	lsls r1, r0, #0x1c
	lsrs r1, r1, #0x1c
	lsls r1, r1, #1
	ldr r2, [sp, #0x30]
	asrs r0, r0, #4
	lsls r2, r2, #2
	adds r0, #1
	adds r2, #1
	bl sub_07BC
_1AC2:
	ldr r2, [sp, #0x1c]
	subs r0, r2, #7
	subs r0, #0x38
	cmp r0, #0x22
	bhi _1AE6
	ldr r0, _1D6C @=gUnknown_36EC
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
_1AE6:
	ldr r2, [sp, #0x1c]
	subs r1, r2, #7
	subs r1, #0x59
	cmp r1, #0x50
	bhi _1B0A
	movs r0, #5
	bl swi_DivArm_t
	subs r0, #8
	bl sub_039C
	ldr r2, [sp, #0x30]
	lsls r1, r0, #2
	lsls r0, r2, #2
	adds r2, r0, #1
	movs r0, #0
	bl sub_07BC
_1B0A:
	subs r5, #1
	bmi _1B10
	b _19B8
_1B10:
	movs r4, #7
	lsls r4, r4, #0x18
	cmp r7, #0x6c
	beq _1B1C
	cmp r7, #0xb4
	bne _1B38
_1B1C:
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
	ldr r0, _1D70 @=0x10001F5F
	ldr r1, _1D38 @=REG_WIN0H
	str r0, [r1, #0x10]
	b _1BC4
_1B38:
	cmp r7, #0x6c
	ble _1BBC
	ldr r0, [sp, #8]
	subs r0, #3
	str r0, [sp, #8]
	ldr r0, [sp, #0x20]
	cmp r0, #0
	bne _1B4C
	movs r0, #1
	b _1B4E
_1B4C:
	movs r0, #2
_1B4E:
	movs r3, #3
	ldr r1, [r4, #0x48]
	lsls r3, r3, #8
	bics r1, r3
	lsls r0, r0, #0x1e
	lsrs r0, r0, #0x1e
	lsls r0, r0, #8
	orrs r0, r1
	ldr r1, _1D68 @=0xFE00FFFF
	ands r1, r0
	movs r3, #1
	lsls r3, r3, #0x12
	adds r0, r0, r3
	ldr r3, _1D68 @=0xFE00FFFF
	bics r0, r3
	orrs r0, r1
	str r0, [r4, #0x48]
	movs r5, #0
_1B72:
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
	blt _1B72
	movs r0, #6
	adds r1, r7, #0
	bl swi_DivArm_t
	cmp r1, #0
	bne _1BB2
	ldr r1, [sp, #0x10]
	ldr r0, [sp, #0xc]
	adds r1, #1
	subs r0, #1
	str r0, [sp, #0xc]
	lsls r0, r0, #8
	orrs r0, r1
	str r1, [sp, #0x10]
	ldr r1, _1D38 @=REG_WIN0H
	strh r0, [r1, #0x12]
_1BB2:
	ldr r0, _1D74 @=0x00003F27
	ldr r1, _1D38 @=REG_WIN0H
	strh r0, [r1, #0xa]
	ldr r0, _1D78 @=0x00009802
	b _1BBE
_1BBC:
	ldr r0, _1D7C @=0x00001002
_1BBE:
	movs r1, #1
	lsls r1, r1, #0x1a
	strh r0, [r1]
_1BC4:
	ldr r0, [sp, #8]
	lsls r0, r0, #8
	movs r1, #1
	lsls r1, r1, #0x1a
	str r0, [r1, #0x38]
	ldr r0, [sp, #4]
	lsls r0, r0, #8
	str r0, [r1, #0x3c]
	cmp r7, #0x10
	blt _1BE4
	bl swi_SoundDriverMain
	cmp r7, #0x10
	bne _1BE4
	ldr r1, _1D80 @=gUnknown_3908
	b _1BEA
_1BE4:
	cmp r7, #0xa2
	bne _1BF0
	ldr r1, _1D84 @=gUnknown_39C0
_1BEA:
	ldr r0, _1D48 @=gUnknown_030036EC
	bl swi_MusicPlayerStart
_1BF0:
	subs r0, r7, #7
	subs r0, #0x3a
	cmp r0, #0x4f
	bhs _1C1C
	ldr r0, [sp, #0x20]
	cmp r0, #0
	bne _1C1C
	ldr r0, _1D88 @=gUnknown_03000064
	movs r3, #1
	ldr r0, [r0, #0x24]
	cmn r0, r3
	beq _1C1C
	ldr r0, _1D8C @=REG_KEYINPUT
	ldrb r0, [r0]
	cmp r0, #0xf3
	bne _1C1C
	ldr r1, _1D90 @=gUnknown_389C
	ldr r0, _1D50 @=gUnknown_0300390C
	bl swi_MusicPlayerStart
	movs r0, #1
	str r0, [sp, #0x20]
_1C1C:
	cmp r7, #0x38
	ble _1C3C
	ldr r0, [sp, #0x20]
	cmp r0, #0
	beq _1C3C
	ldr r1, [sp]
	cmp r1, #0x20
	bge _1C32
	ldr r1, [sp]
	adds r1, #2
	str r1, [sp]
_1C32:
	movs r2, #0x1f
	movs r0, #6
	ldr r1, [sp]
	bl sub_07BC
_1C3C:
	bl sub_2B34
	ldr r1, _1D30 @=REG_IE
	movs r0, #1
	strh r0, [r1, #8]
	bl swi_VBlankIntrWait_t
	cmp r7, #0x10
	bge _1C62
	ldr r1, [sp, #0x10]
	ldr r0, [sp, #0xc]
	adds r1, #1
	subs r0, #1
	str r0, [sp, #0xc]
	lsls r0, r0, #8
	orrs r0, r1
	str r1, [sp, #0x10]
	ldr r1, _1D38 @=REG_WIN0H
	strh r0, [r1, #0x12]
_1C62:
	adds r7, #1
	cmp r7, #0xd2
	bgt _1C6A
	b _19B4
_1C6A:
	ldr r0, _1D94 @=gUnknown_03000064 + 0x24
	bl ValidateROMHeader
	movs r6, #0
	adds r7, r0, #0
	cmp r0, #0
	ldr r5, _1D98 @=0x03FFFFF0
	bne _1C80
	ldr r0, [sp, #0x20]
	cmp r0, #0
	beq _1CD8
_1C80:
	movs r0, #1
	strb r0, [r5, #0xb]
	strb r6, [r5, #7]
_1C86:
	bl sub_2B34
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	strb r0, [r5, #0xa]
	bne _1CD8
	bl swi_SoundDriverMain
	bl swi_VBlankIntrWait_t
	cmp r7, #0
	bne _1C86
	ldrb r0, [r5, #7]
	cmp r0, #0
	bne _1C86
	ldrb r0, [r5, #0xb]
	cmp r0, #0
	beq _1CC2
	ldr r0, _1D8C @=REG_KEYINPUT
	ldrb r0, [r0]
	mvns r0, r0
	movs r3, #0xf3
	ands r0, r3
	beq _1C86
	ldr r1, _1D9C @=gUnknown_3818
	ldr r0, _1D50 @=gUnknown_0300390C
	bl swi_MusicPlayerStart
	strb r6, [r5, #0xb]
	b _1C86
_1CC2:
	ldr r1, [sp]
	cmp r1, #0
	ble _1CD8
	ldr r1, [sp]
	movs r2, #0x1f
	subs r1, #1
	str r1, [sp]
	movs r0, #6
	bl sub_07BC
	b _1C86
_1CD8:
	ldr r1, _1DA0 @=0x00103FBF
	ldr r0, _1D38 @=REG_WIN0H
	str r1, [r0, #0x10]
	str r6, [r0, #0x14]
	movs r1, #0
_1CE2:
	lsls r2, r1, #3
	ldr r7, [r4, r2]
	movs r3, #3
	lsls r3, r3, #0xa
	bics r7, r3
	adds r1, #1
	cmp r1, #9
	str r7, [r4, r2]
	blt _1CE2
	movs r7, #0
	mvns r7, r7
	adds r4, r0, #0
	b _1D16
_1CFC:
	bl swi_SoundDriverMain
	bl swi_VBlankIntrWait_t
	lsrs r0, r7, #1
	bhs _1D16
	ldr r0, [sp, #0x14]
	cmp r0, #0x10
	beq _1D16
	ldr r0, [sp, #0x14]
	adds r0, #1
	str r0, [sp, #0x14]
	str r0, [r4, #0x14]
_1D16:
	adds r7, #1
	cmp r7, #0x32
	ble _1CFC
	bl swi_SoundDriverVSyncOff
	ldrb r0, [r5, #0xa]
	cmp r0, #0
	beq _1DA4
	movs r0, #0xde
	b _1DA6

	UNALIGNED_THUMB_FUNC_START _1D2A
_1D2A: @ 0x00001D2A
	b _1DA4
	.align 2, 0
_1D2C: .4byte REG_POSTFLG
_1D30: .4byte REG_IE
_1D34: .4byte 0x10003F5F
_1D38: .4byte REG_WIN0H
_1D3C: .4byte gSoundDriver
_1D40: .4byte 0x00940A00
_1D44: .4byte gUnknown_0300372C
_1D48: .4byte gUnknown_030036EC
_1D4C: .4byte gUnknown_0300394C
_1D50: .4byte gUnknown_0300390C
_1D54: .4byte gUnknown_03003564
_1D58: .4byte gUnknown_03003580
_1D5C: .4byte gUnknown_030035F0
_1D60: .4byte OAM + 0x26
_1D64: .4byte gUnknown_369C
_1D68: .4byte 0xFE00FFFF
_1D6C: .4byte gUnknown_36EC
_1D70: .4byte 0x10001F5F
_1D74: .4byte 0x00003F27
_1D78: .4byte 0x00009802
_1D7C: .4byte 0x00001002
_1D80: .4byte gUnknown_3908
_1D84: .4byte gUnknown_39C0
_1D88: .4byte gUnknown_03000064
_1D8C: .4byte REG_KEYINPUT
_1D90: .4byte gUnknown_389C
_1D94: .4byte gUnknown_03000064 + 0x24
_1D98: .4byte 0x03FFFFF0
_1D9C: .4byte gUnknown_3818
_1DA0: .4byte 0x00103FBF
_1DA4:
	movs r0, #0xff
_1DA6:
	bl swi_RegisterRamReset
	add sp, #0x34
	pop {r4, r5, r6, r7}
	pop {r3}
	bx r3
	.align 2, 0 @ don't pad with nop

	.section .text.after_m4a

	THUMB_FUNC_START sub_2864
sub_2864: @ 0x00002864
	movs r6, #0x20
_2866:
	adds r1, r5, #0
	eors r1, r2
	lsrs r5, r5, #1
	lsrs r1, r1, #1
	bcc _2872
	eors r5, r0
_2872:
	lsrs r2, r2, #1
	.2byte 0x1E76 @ subs r6, r6, #1
	bne _2866
	bx lr

	UNALIGNED_THUMB_FUNC_START sub_287A
sub_287A: @ 0x0000287A
	push {r2, r4, r6, lr}
	mov r12, r1
	str r3, [r7, #0x54]
	ldr r3, [r7, #0x44]
	ldr r1, [r7, #0x38]
	subs r1, r1, r3
	asrs r1, r1, #2
	ble _28BA
	cmp r1, #0x89
	ble _2890
	movs r1, #0x89
_2890:
	ldr r4, [r7, #4]
	ldrh r5, [r7, #0x20]
_2894:
	str r1, [r7, #0x50]
	mov r1, r12
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
	bl sub_2864
	ldr r1, [r7, #0x50]
	.2byte 0x1E49 @ subs r1, r1, #1
	bne _2894
	strh r5, [r7, #0x20]
	str r4, [r7, #4]
_28BA:
	pop {r2, r4, r6, pc}

	THUMB_FUNC_START sub_28BC
sub_28BC: @ 0x000028BC
	push {lr}
	bl sub_2AA6
	pop {r1}
	mov lr, r1
_28C6:
	ldrh r1, [r6, #8]
	lsrs r1, r1, #8
	bhs _28C6
	bx lr

	UNALIGNED_THUMB_FUNC_START swi_MultiBoot
swi_MultiBoot: @ 0x000028CE
	push {r1, r3, r4, r5, r6, r7, lr}
	movs r3, #0xdf
	adr r2, sub_2C00
	bl sub_2AA4
	adds r7, r0, #0
	movs r4, #0xff
	bl CheckDestInWritableRange_t
	beq _296E
	lsrs r4, r7, #0x14
	movs r3, #0xe8
	ands r3, r4
	cmp r3, #0x20
	bne _296E
	movs r4, #0
	cmp r1, #1
	beq _28FA
	cmp r1, #2
	bgt _296E
	ldr r4, _2C18 @=0xC3871089
	orrs r4, r1
_28FA:
	strh r4, [r7, #0x3a]
	ldr r0, [r7, #0x20]
	str r0, [r7, #0x10]
	ldr r4, [r7, #0x24]
	subs r4, r4, r0
	ldr r3, _2C08 @=0x0003FFF8
	ands r4, r3
	str r4, [r7, #0xc]
	bl CheckDestInWritableRange_t
	beq _296E
	ldr r4, _2C0C @=REG_DMA0
	ldrh r0, [r4, #0xa]
	ldrh r2, [r4, #0x16]
	orrs r0, r2
	ldrh r2, [r4, #0x22]
	orrs r0, r2
	ldrh r2, [r4, #0x2e]
	orrs r0, r2
	lsrs r0, r0, #0x10
	bhs _296E
	ldr r6, _2C10 @=REG_SIOMULTI0
	ldrb r0, [r7, #0x1e]
	lsls r0, r0, #0x1c
	lsrs r0, r0, #0x1d
	ldrh r1, [r6]
	ldrh r2, [r7, #0x3a]
	cmp r2, #0
	beq _293A
	lsls r0, r0, #0x1f
	lsrs r0, r0, #0x1f
	ldrb r1, [r7, #0x14]
_293A:
	strb r0, [r7, #8]
	strb r1, [r7, #4]
	ldr r3, _2C18 @=0xC3871089
	lsrs r3, r3, #0x10
	ldr r1, _2D2C @=0x0000C37B
	cmp r2, #0
	ldr r4, _2D34 @=0x43202F2F
	bne _2950
	ldr r1, _2D30 @=0x0000A517
	ldr r3, _2C08 @=0x0003FFF8
	ldr r4, _2D34+4 @=0x6465646F
_2950:
	strh r1, [r7, #0x3e]
	strh r3, [r7, #0x38]
	str r4, [r7, #0x40]
	ldr r1, [r7, #0x18]
	str r1, [r7]
	ldrb r1, [r7, #0x1c]
	strb r1, [r7]
	adds r4, r6, #0
_2960:
	lsrs r0, r0, #1
	bcc _2970
	ldrb r1, [r4, #3]
	cmp r1, #0x73
	bne _296E
_296A:
	.2byte 0x1CA4 @ adds r4, r4, #2
	b _2960
_296E:
	b _2A8E
_2970:
	bne _296A
	ldr r5, [r7, #0xc]
	lsrs r0, r5, #2
	subs r0, #0x34
	ldr r1, [r7, #0x10]
	adds r1, r1, r5
	str r1, [r7, #0xc]
	ldr r1, _2C08 @=0x0003FFF8
_2980:
	.2byte 0x1E49 @ subs r1, r1, #1
	bne _2980
	bl sub_28BC
	ldrh r1, [r6, #2]
	strb r1, [r7, #5]
	ldrh r1, [r6, #4]
	ldrh r2, [r6, #6]
	ldrh r3, [r7, #0x3a]
	cmp r3, #0
	beq _299A
	movs r1, #0xff
	movs r2, #0xff
_299A:
	strb r1, [r7, #6]
	strb r2, [r7, #7]
	movs r4, #2
	mov r12, r4
	ldr r3, [r7, #0x10]
_29A4:
	ldr r1, [r7, #0x20]
	subs r1, r1, r3
	lsrs r1, r1, #2
	ldrh r0, [r7, #0x3c]
	bhs _29DE
	ldr r2, [r3]
	ldrh r0, [r7, #0x3e]
	ldrh r5, [r7, #0x38]
	bl sub_2864
	strh r5, [r7, #0x38]
	ldr r1, [r7]
	ldr r0, _2D34+16 @=0x6F646573
	muls r1, r0, r1
	.2byte 0x1C49 @ adds r1, r1, #1
	str r1, [r7]
	ldr r0, [r3]
	eors r0, r1
	ldr r1, [r7, #0x20]
	subs r2, r3, r1
	ldr r1, _2D94 @=gUnknown_020000C0
	adds r2, r2, r1
	negs r1, r2
	ldr r2, [r7, #0x40]
	eors r1, r2
	eors r0, r1
	lsrs r2, r0, #0x10
	strh r2, [r7, #0x3c]
	ldr r6, _2C10 @=REG_SIOMULTI0
_29DE:
	bl _28C6
	ldr r1, [r7, #0x20]
	cmp r1, r3
	beq _2A1A
	mov lr, r4
	subs r4, r3, r1
	.2byte 0x1EA4 @ subs r4, r4, #2
	ldrh r1, [r7, #0x3a]
	cmp r1, #0
	beq _29F6
	.2byte 0x1EA4 @ subs r4, r4, #2
_29F6:
	ldr r1, _2D94 @=gUnknown_020000C0
	adds r4, r4, r1
_29FA:
	ldrb r2, [r7, #8]
	adds r5, r6, #0
_29FE:
	lsrs r2, r2, #1
	bcc _2A0E
	ldrh r1, [r5, #2]
	eors r1, r4
	lsls r1, r1, #0x10
	bne _2A8E
_2A0A:
	.2byte 0x1CAD @ adds r5, r5, #2
	b _29FE
_2A0E:
	bne _2A0A
	mov r4, lr
	cmp r2, r12
	bne _2A1A
	movs r0, #0
	b _2A90
_2A1A:
	bl sub_2AA6
	cmp r4, #0
	beq _2A3C
	.2byte 0x1C9B @ adds r3, r3, #2
	ldrh r1, [r7, #0x3a]
	cmp r1, #0
	beq _2A2C
	.2byte 0x1C9B @ adds r3, r3, #2
_2A2C:
	cmp r4, #2
	bne _2A36
	ldr r1, [r7, #0xc]
	cmp r1, r3
	bne _29A4
_2A36:
	movs r0, #0x65
	.2byte 0x1E64 @ subs r4, r4, #1
	b _29DE
_2A3C:
	movs r4, #1
	bl _28C6
	ldrb r2, [r7, #8]
	adds r3, r6, #0
_2A46:
	lsrs r2, r2, #1
	bcc _2A5E
	ldrh r1, [r3, #2]
	cmp r1, #0x75
	beq _2A5A
	cmp r0, #0x65
	bne _2A8E
	cmp r1, #0x74
	bne _2A8E
	movs r4, #0
_2A5A:
	.2byte 0x1C9B @ adds r3, r3, #2
	b _2A46
_2A5E:
	bne _2A5A
	cmp r0, #0x66
	beq _2A70
	cmp r4, #0
	beq _2A6A
	movs r0, #0x66
_2A6A:
	bl sub_2AA6
	b _2A3C
_2A70:
	cmp r4, #0
	beq _2A8E
	ldrh r0, [r7, #0x3e]
	ldrh r5, [r7, #0x38]
	ldr r2, [r7, #4]
	bl sub_2864
	ldr r6, _2C10 @=REG_SIOMULTI0
	adds r0, r5, #0
	bl sub_28BC
	movs r1, #0
	mov r12, r1
	adds r4, r0, #0
	b _29FA
_2A8E:
	movs r0, #1
_2A90:
	str r0, [r7, #0x38]
	str r0, [r7, #0x3c]
	str r0, [r7, #0x40]
	adds r1, r7, #0
	adds r1, #0x14
_2A9A:
	stm r7!, {r0}
	cmp r1, r7
	bne _2A9A
	pop {r1, r3, r4, r5, r6, r7}
	pop {r2}

	THUMB_FUNC_START sub_2AA4
sub_2AA4: @ 0x00002AA4
	bx r2

	UNALIGNED_THUMB_FUNC_START sub_2AA6
sub_2AA6: @ 0x00002AA6
	movs r1, #0x96
_2AA8:
	.2byte 0x1E49 @ subs r1, r1, #1
	bne _2AA8
	str r0, [r6]
	strh r0, [r6, #0xa]
	ldrh r1, [r7, #0x3a]
	cmp r1, #0
	bne _2AB8
	ldr r1, _2D98 @=0xA1C12083
_2AB8:
	strh r1, [r6, #8]
	bx lr

	THUMB_FUNC_START sub_2ABC
sub_2ABC: @ 0x00002ABC
	push {lr}
	ldr r0, _2D9C @=gUnknown_03007FF0 + 0xB
	ldrb r1, [r0]
	cmp r1, #1
	bne _2AE4
	ldrb r0, [r7, #0xa]
	lsls r0, r0, #0x19
	bcc _2AE4
	ldrb r0, [r7, #0x12]
	ldrb r1, [r7, #0x13]
	orrs r0, r1
	bne _2AE8
	ldr r0, [r7, #0x38]
	ldr r1, _2D94 @=gUnknown_020000C0
	subs r1, r1, r0
	bge _2AE4
	movs r0, #0x78
	strb r0, [r7, #0x12]
	ldr r0, _2D48 @=gUnknown_02000000
	b _3038
_2AE4:
	movs r0, #0
	pop {pc}
_2AE8:
	ldr r2, [r7, #8]
	lsls r1, r2, #0xd
	lsrs r1, r1, #0x1e
	ldrb r0, [r7, #0x14]
_2AF0:
	.2byte 0x1CC0 @ adds r0, r0, #3
	.2byte 0x1E49 @ subs r1, r1, #1
	bpl _2AF0
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
	blt _2B1E
	movs r1, #0
	lsls r0, r2, #0xc
	lsrs r0, r0, #0x1d
	cmp r0, #7
	blt _2B1E
	movs r0, #0
_2B1E:
	movs r2, #0x1f
	bl sub_07BC
	ldrb r0, [r7, #0x12]
	.2byte 0x1E40 @ subs r0, r0, #1
	blt _2B2E
	strb r0, [r7, #0x12]
	bne _2AE4
_2B2E:
	movs r0, #5
	strb r0, [r7, #0x13]
	pop {pc}

	THUMB_FUNC_START sub_2B34
sub_2B34: @ 0x00002B34
	push {r4, r5, r6, r7}
	push {lr}
	ldr r7, _2DA0 @=gUnknown_0300000C
	ldr r4, _2C10 @=REG_SIOMULTI0
	ldr r0, [r7, #0x4c]
	ldr r1, _2D34+12 @=0x6177614B
	muls r0, r1, r0
	.2byte 0x1C40 @ adds r0, r0, #1
	str r0, [r7, #0x4c]
	b _304A
_2B48:
	ldr r0, [r7, #0x4c]
	movs r1, #0xe0
	bics r0, r1
	movs r1, #0xa0
	eors r0, r1
	movs r3, #0x80
	lsls r3, r3, #8
	bics r0, r3
	ldr r1, _2D9C @=gUnknown_03007FF0 + 0xB
	ldrb r2, [r1]
	cmp r2, #1
	beq _2B68
	ldr r1, _2C1C @=gUnknown_03000064
	ldr r2, [r1, #0x24]
	.2byte 0x1C52 @ adds r2, r2, #1
	bne _2B6A
_2B68:
	orrs r0, r3
_2B6A:
	str r0, [r7]
	ldrb r5, [r7, #0xf]
	ldrb r6, [r7, #0xe]
	ldrb r0, [r7, #0xd]
	cmp r0, #0
	bne _2BAE
	bl sub_2D5C
	ldrb r3, [r7, #0xc]
	ldrh r0, [r4, #0x10]
	cmp r6, #2
	bne _2B8C
	.2byte 0x1E5B @ subs r3, r3, #1
	bpl _2BA8
_2B86:
	movs r6, #0
	movs r3, #6
	b _2BA2
_2B8C:
	cmp r6, #1
	bne _2B9A
	.2byte 0x1E5B @ subs r3, r3, #1
	bpl _2BA8
_2B94:
	movs r6, #2
	movs r3, #6
	b _2BA2
_2B9A:
	.2byte 0x1E5B @ subs r3, r3, #1
	bpl _2BA8
_2B9E:
	movs r6, #1
	movs r3, #0x1e
_2BA2:
	ldr r1, _2C14 @=_301C
	str r1, [r7, #0x34]
	movs r5, #0
_2BA8:
	strb r3, [r7, #0xc]
	bl sub_2D64
_2BAE:
	cmp r5, #0
	bne sub_2C20
	str r5, [r7, #0x10]
	strb r5, [r7, #0xa]
	ldr r2, _2D48 @=gUnknown_02000000
	str r2, [r7, #0x38]
	ldr r2, _2D94 @=gUnknown_020000C0
	str r2, [r7, #0x3c]
	str r2, [r7, #0x44]
	movs r2, #1
	strb r2, [r7, #0xf]
	strb r6, [r7, #0xe]
	cmp r6, #0
	bne _2BE2
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
_2BDE:
	strh r1, [r7, #0x20]
	b _2D56
_2BE2:
	cmp r6, #1
	bne _2BF4
	strh r5, [r4, #0x14]
	ldr r2, _2D4C @=0x60032003
	ldr r1, _2C08 @=0x0003FFF8
_2BEC:
	strh r2, [r4, #8]
	strh r5, [r4, #0xa]
	str r5, [r4]
	b _2BDE
_2BF4:
	strh r5, [r4, #0x14]
	ldr r2, _2F60 @=0x10085088
	lsrs r2, r2, #0x10
	ldr r1, _2C18 @=0xC3871089
	lsrs r1, r1, #0x10
	b _2BEC

	ARM_FUNC_START sub_2C00
sub_2C00: @ 0x00002C00
	msr cpsr_fc, r3
	bx lr
	.align 2, 0
_2C08: .4byte 0x0003FFF8
_2C0C: .4byte REG_DMA0
_2C10: .4byte REG_SIOMULTI0
_2C14: .4byte _301C + 1
_2C18: .4byte 0xC3871089
_2C1C: .4byte gUnknown_03000064

	THUMB_FUNC_START sub_2C20
sub_2C20:
	cmp r5, #1
	bne _2C58
	bl sub_2D5C
	movs r1, #0x80
	strh r1, [r3, #2]
	ldrh r2, [r3]
	orrs r2, r1
	strh r2, [r3]
	strh r5, [r3, #8]
	cmp r6, #0
	bne _2C44
	movs r1, #0x47
	strh r1, [r4, #0x20]
	adr r2, _2F64
	b _2C50
_2C40:
	ldr r1, _2F60 @=0x10085088
	b _2C4C
_2C44:
	cmp r6, #1
	bne _2C40
	ldr r1, _2D4C @=0x60032003
	lsrs r1, r1, #0x10
_2C4C:
	strh r1, [r4, #8]
	adr r2, _2DA4
_2C50:
	movs r1, #2
	strb r1, [r7, #0xf]
	str r2, [r7, #0x34]
	b _2D56
_2C58:
	cmp r5, #2
	bne _2C5E
	b _2D56
_2C5E:
	bl sub_2ABC
	cmp r5, #3
	beq _2C6C
	cmp r0, #0
	beq _2D56
	b _2D58
_2C6C:
	bl sub_2D5C
	ldr r0, [r7, #0x30]
	.2byte 0x1E40 @ subs r0, r0, #1
	bpl _2C8A
	cmp r6, #0
	bne _2C84
	ldrh r1, [r4, #0x38]
	movs r2, #0x30
	ands r1, r2
	beq _2C8C
	b _2B86
_2C84:
	cmp r6, #1
	bne _2B94
	b _2B9E
_2C8A:
	str r0, [r7, #0x30]
_2C8C:
	movs r0, #1
	strh r0, [r3, #8]
	ldrb r0, [r7, #0x11]
	cmp r0, #0
	bne _2D50
	cmp r6, #0
	bne _2CEE
	ldr r0, _2D98 @=0xA1C12083
	lsrs r0, r0, #0x10
	ldr r1, _3080 @=0x6177614B
	ldr r3, _2D34+8 @=0x20796220
	bl sub_287A
	str r3, [r7, #0x44]
	ldr r1, [r7, #0x3c]
	cmp r3, r1
	bne _2D56
	ldr r0, [r7, #0x38]
	eors r0, r3
	bne _2D56
	.2byte 0x1F09 @ subs r1, r1, #4
	ldrh r2, [r1]
	ldrh r3, [r7, #0x22]
	cmp r3, r2
	bne _2CE8
	str r0, [r1]
	ldr r1, [r7, #8]
	ldr r2, _309C @=0x80808080
	ands r1, r2
	cmp r1, r2
	bne _2CE8
	ldrb r1, [r7, #0xa]
	ldrb r2, [r7, #8]
	adds r1, r1, r2
	ldrb r2, [r7, #9]
	adds r1, r1, r2
	ldrb r2, [r7, #0xb]
	subs r1, r1, r2
	lsls r1, r1, #0x19
	bne _2CE8
	ldr r0, _30A0 @=0xEA000036
	movs r1, #1
	bl sub_301E
	cmp r0, #0
	beq _2D50
_2CE8:
	movs r0, #0
	strb r0, [r7, #0xf]
	b _2D56
_2CEE:
	ldr r2, [r7, #0x3c]
	ldr r3, [r7, #0x44]
	cmp r3, r2
	beq _2D56
	ldr r0, _2D30 @=0x0000A517
	ldr r3, _2D34+4 @=0x6465646F
	cmp r6, #2
	bne _2D02
	ldr r0, _2D2C @=0x0000C37B
	ldr r3, _2D34 @=0x43202F2F
_2D02:
	ldr r1, _2D34+16 @=0x6F646573
	bl sub_287A
	cmp r2, r3
	bne _2D26
	ldr r2, [r7, #0x1c]
	bl sub_2864
	strh r5, [r7, #0x20]
	ldr r0, _30A4 @=0xEA00002E
	movs r1, #4
	ldrb r6, [r7, #0xe]
	subs r1, r1, r6
	bl sub_301E
	cmp r0, #0
	bne _2CE8
	ldr r3, [r7, #0x3c]
_2D26:
	str r3, [r7, #0x44]
	b _2D56
	.align 2, 0
_2D2C: .2byte 0x0000C37B
	.align 2, 0
_2D30: .2byte 0x0000A517
	.align 2, 0
_2D34: .ascii "// Coded by Kawasedo"
_2D48: .4byte gUnknown_02000000
_2D4C: .2byte 0x2003, 0x6003
_2D50:
	movs r0, #4
	strb r0, [r7, #0x11]
	strb r0, [r7, #0xf]
_2D56:
	movs r0, #0
_2D58:
	pop {r3, r4, r5, r6, r7}
	bx r3

	THUMB_FUNC_START sub_2D5C
sub_2D5C: @ 0x00002D5C
	movs r0, #0
_2D5E:
	ldr r3, _3088 @=REG_IE
	strh r0, [r3, #8]
	bx lr

	THUMB_FUNC_START sub_2D64
sub_2D64: @ 0x00002D64
	movs r0, #1
	b _2D5E

	THUMB_FUNC_START sub_2D68
sub_2D68: @ 0x00002D68
	ldr r3, _3098 @=gUnknown_0300000C
	movs r1, #0
	strb r1, [r3, #0xf]
	bx lr

	THUMB_FUNC_START sub_2D70
sub_2D70: @ 0x00002D70
	ldr r2, _3078 @=REG_SIOMULTI0
	ldrh r1, [r2]
	ldr r3, _3098 @=gUnknown_0300000C
	ldrb r0, [r3, #0xe]
	cmp r0, #1
	bne _2D86
	ldrh r0, [r2, #8]
	lsrs r0, r0, #7
	bhs _2E62
_2D82:
	ldr r0, [r3, #0x34]
	mov pc, r0
	@ noreturn
_2D86:
	cmp r0, #2
	beq _2D82
	ldrh r1, [r2, #0x20]
	strh r1, [r2, #0x20]
	movs r0, #7
	ands r1, r0
	b _2D82
	.align 2, 0
_2D94: .4byte gUnknown_020000C0
_2D98: .4byte 0xA1C12083
_2D9C: .4byte gUnknown_03007FF0 + 0xB
_2DA0: .4byte gUnknown_0300000C
_2DA4: @ 0x00002DA4
	lsrs r0, r1, #8
	cmp r0, #0x62
	bne _2E84
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	bne _2DB4
	movs r0, #1
	b _2DBA
_2DB4:
	ldrh r0, [r2, #8]
	lsls r0, r0, #0x1a
	lsrs r0, r0, #0x1e
_2DBA:
	strb r0, [r3, #0x16]
	beq _2E62
	movs r1, #1
	lsls r1, r0
	strb r1, [r3, #0x15]
	ldrh r1, [r2]
	adr r0, _2DF0
	str r0, [r3, #0x34]
_2DCA:
	strb r1, [r3, #0x10]
	movs r0, #0xb
	strb r0, [r3, #0xc]
	movs r0, #0x11
	ands r0, r1
	bne _2E62
	lsrs r0, r1, #4
	orrs r0, r1
	lsrs r2, r1, #4
	eors r2, r1
	eors r2, r0
	lsls r2, r2, #0x1c
	bne _2E62
	movs r0, #0x72
	lsls r0, r0, #8
	ldrb r1, [r3, #0x15]
	orrs r1, r0
	b _2F3E
	.align 2, 0
_2DF0: @ 0x00002DF0
	lsrs r0, r1, #8
_2DF2:
	cmp r0, #0x62
	beq _2DCA
	cmp r0, #0x61
	bne _2E62
	movs r0, #3
	strb r0, [r3, #0xf]
	strb r0, [r3, #0xd]
	ldr r2, _3094 @=gUnknown_02000000
	str r2, [r3, #0x38]
	movs r2, #0x60
	adr r0, _2E0C
	b _2E1C
	.align 2, 0
_2E0C: @ 0x00002E0C
	ldr r2, [r3, #0x38]
	strh r1, [r2]
	.2byte 0x1C92 @ adds r2, r2, #2
	str r2, [r3, #0x38]
	ldr r2, [r3, #0x48]
	.2byte 0x1E52 @ subs r2, r2, #1
	bne _2E1C
	adr r0, _2E28
_2E1C:
	str r2, [r3, #0x48]
	lsls r2, r2, #8
	ldrb r1, [r3, #0x15]
	orrs r1, r2
	b _2F3C
	.align 2, 0
_2E28: @ 0x00002E28
	lsrs r0, r1, #8
	cmp r0, #0x63
	bne _2DF2
	movs r0, #0xff
	strb r0, [r3, #0x1a]
	strb r0, [r3, #0x1b]
_2E34:
	strb r1, [r3, #0xa]
	strb r1, [r3, #0x18]
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	bne _2E44
	ldrb r0, [r3, #0x17]
	strb r0, [r3, #0x19]
	b _2E50
_2E44:
	ldrh r0, [r2, #2]
	strb r0, [r3, #0x19]
	ldrh r0, [r2, #4]
	strb r0, [r3, #0x1a]
	ldrh r0, [r2, #6]
	strb r0, [r3, #0x1b]
_2E50:
	ldr r0, [r3, #0x18]
	str r0, [r3, #4]
	ldrb r2, [r3, #1]
	strb r2, [r3, #0x17]
	adr r0, _2E64
_2E5A:
	movs r1, #0x73
	lsls r1, r1, #8
	orrs r1, r2
	b _2F3C
_2E62:
	b _2F56
	.align 2, 0
_2E64: @ 0x00002E64
	lsrs r0, r1, #8
	cmp r0, #0x63
	beq _2E34
	cmp r0, #0x64
	bne _2F56
	strb r1, [r3, #0x1c]
	ldrb r2, [r3, #2]
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	bne _2E80
	strb r2, [r3, #0x1d]
	movs r0, #0xff
	strb r0, [r3, #0x1e]
	strb r0, [r3, #0x1f]
_2E80:
	adr r0, _2E88
	b _2E5A
_2E84:
	b _2F44
	.align 2, 0
_2E88: @ 0x00002E88
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	beq _2E9A
	ldrh r0, [r2, #2]
	strb r0, [r3, #0x1d]
	ldrh r0, [r2, #4]
	strb r0, [r3, #0x1e]
	ldrh r0, [r2, #6]
	strb r0, [r3, #0x1f]
_2E9A:
	lsls r1, r1, #2
	adds r1, #0xc8
	ldr r0, _307C @=0x0003FFF8
	ands r0, r1
	eors r1, r0
	bne _2F56
	ldr r1, _308C @=gUnknown_020000C0
	adds r2, r1, r0
	adds r2, #8
	str r2, [r3, #0x3c]
	adr r0, _2EB4
	b _2F3C
	.align 2, 0
_2EB4: @ 0x00002EB4
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	ldr r0, [r3, #0x38]
	strh r1, [r0]
	bne _2EC4
	ldr r1, [r2]
	str r1, [r0]
	@ adds r0, r0, #2
	.2byte 0x1C80
_2EC4:
	adds r1, r0, #2
	str r1, [r3, #0x38]
	ldr r0, [r3, #0x3c]
	cmp r0, r1
	bne _2F3E
	adr r0, _2ED4
	b _2F3C
	.align 2, 0
_2ED4: @ 0x00002ED4
	cmp r1, #0x65
	bne _2F56
	ldr r1, [r3, #0x44]
	ldr r2, [r3, #0x3c]
	cmp r1, r2
	beq _2EE4
	movs r1, #0x74
	b _2F3E
_2EE4:
	movs r1, #0x75
	adr r0, _2EEC
	b _2F3C
	.align 2, 0
_2EEC: @ 0x00002EEC
	cmp r1, #0x65
	beq _2EE4
	cmp r1, #0x66
	bne _2F56
	ldrh r1, [r3, #0x20]
	adr r0, _2EFC
	b _2F3C
	.align 2, 0
_2EFC: @ 0x00002EFC
	ldrh r0, [r3, #0x20]
	cmp r0, r1
	bne _2F56
	ldrb r1, [r3, #0xe]
	cmp r1, #1
	bne _2F22
	ldrb r3, [r3, #0x10]
	lsls r3, r3, #0x1c
	lsrs r3, r3, #0x1d
_2F0E:
	lsrs r3, r3, #1
	bcc _2F1C
	ldrh r1, [r2, #2]
	cmp r0, r1
	bne _2F1E
_2F18:
	@ adds r2, r2, #2
	.2byte 0x1C92
	b _2F0E
_2F1C:
	bne _2F18
_2F1E:
	ldr r3, _3098 @=gUnknown_0300000C
	bne _2F56
_2F22:
	ldr r0, [r3, #0x1c]
	ldrb r1, [r3, #0x19]
	subs r0, r0, r1
	ldrb r1, [r3, #0x1a]
	subs r0, r0, r1
	ldrb r1, [r3, #0x1b]
	subs r0, r0, r1
	subs r0, #0x11
	lsls r0, r0, #0x18
	bne _2F56
	movs r1, #0xff
	strb r1, [r3, #0x11]
	adr r0, _301C
_2F3C:
	str r0, [r3, #0x34]
_2F3E:
	ldr r2, _3078 @=REG_SIOMULTI0
	strh r1, [r2, #0xa]
	strh r1, [r2, #2]
_2F44:
	ldrb r0, [r3, #0xe]
	cmp r0, #2
	bne _2F50
	ldr r2, _3078 @=REG_SIOMULTI0
	ldr r0, _2F60 @=0x10085088
	strh r0, [r2, #8]
_2F50:
	movs r0, #0xb
	str r0, [r3, #0x30]
	bx lr
_2F56:
	movs r1, #0
	strb r1, [r3, #0xf]
	adr r0, _301C
	b _2F3C
	.align 2, 0
_2F60: .4byte 0x10085088
_2F64: @ 0x00002F64
	cmp r1, #1
	bne _2F56
	ldr r0, [r3]
	str r0, [r3, #4]
	ldr r1, _3084 @=0x6F646573
	eors r0, r1
	str r0, [r2, #0x34]
	movs r0, #0xb
	strb r0, [r3, #0xc]
	movs r1, #0x10
	adr r0, _2F7C
	b _3014
	.align 2, 0
_2F7C: @ 0x00002F7C
	cmp r1, #4
	bne _2F56
	movs r0, #3
	strb r0, [r3, #0xf]
	strb r0, [r3, #0xd]
	adr r0, _2F8C
	b _3018
	.align 2, 0
_2F8C: @ 0x00002F8C
	cmp r1, #2
	bne _2F56
	ldr r0, [r2, #0x30]
	movs r1, #2
	lsls r1, r1, #8
	ands r1, r0
	lsrs r1, r1, #7
	adr r2, _3080
	adds r2, r2, r1
	ldr r1, [r2]
	eors r0, r1
	str r0, [r3, #8]
	lsrs r1, r0, #8
	movs r2, #0x7f
	ands r1, r2
	lsls r0, r0, #0x10
	bcc _2FB0
	adds r1, #0x80
_2FB0:
	lsrs r0, r0, #0x10
	ands r0, r2
	lsls r1, r1, #7
	orrs r1, r0
	adds r1, #0x3f
	lsls r1, r1, #3
	ldr r0, _307C @=0x0003FFF8
	ands r0, r1
	cmp r0, r1
	beq _2FD0
	ldrb r0, [r3, #0xa]
	lsls r0, r0, #0x19
	lsrs r0, r0, #0x19
	strb r0, [r3, #0xa]
	movs r0, #0x89
	lsls r0, r0, #7
_2FD0:
	adds r0, #0xc
	ldr r1, _3094 @=gUnknown_02000000
	adds r1, r1, r0
	str r1, [r3, #0x40]
	movs r1, #0x20
	adr r0, _2FE0
	b _3014
	.align 2, 0
_2FE0: @ 0x00002FE0
	cmp r1, #2
	bne _2F56
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
	bne _2F44
	ldr r1, _308C @=gUnknown_020000C0
	cmp r0, r1
	bne _3006
	ldr r0, [r3, #0x40]
	str r0, [r3, #0x3c]
	b _2F44
_3006:
	ldr r0, _3090 @=gUnknown_020001F8
	ldr r1, [r0, #4]
	ldr r0, [r0]
	muls r0, r1, r0
	str r0, [r2, #0x34]
	movs r1, #0
	adr r0, _301C
_3014:
	ldr r2, _3078 @=REG_SIOMULTI0
	strh r1, [r2, #0x38]
_3018:
	str r0, [r3, #0x34]
	b _2F44
_301C: @ 0x0000301C
	bx lr

	UNALIGNED_THUMB_FUNC_START sub_301E
sub_301E: @ 0x0000301E
	push {lr}
	ldr r2, _3094 @=gUnknown_02000000
	str r0, [r2]
	ldr r3, _308C @=gUnknown_020000C0
	strb r1, [r3, #4]
	cmp r1, #1
	beq _3030
	ldrb r0, [r7, #0x16]
	strb r0, [r3, #5]
_3030:
	adds r0, r2, #HEADER_OFFSET_LOGO
	bl ValidateROMHeader
	pop {pc}

_3038:
	@ adds r0, r0, #4
	.2byte 0x1D00
	bl sub_094A
	ldrh r0, [r7, #0x24]
	cmp r0, #0
	bne _3048
	movs r0, #0x3c
	strh r0, [r7, #0x24]
_3048:
	b _2AE8
_304A:
	ldrb r0, [r7, #0x12]
	cmp r0, #0x77
	bne _3056
	bl sub_0974
	b _305E
_3056:
	cmp r0, #0x76
	bne _305E
	bl sub_0982
_305E:
	ldrh r0, [r7, #0x24]
	cmp r0, #0
	beq _3074
	@ subs r0, r0, #1
	.2byte 0x1E40
	strh r0, [r7, #0x24]
	cmp r0, #0x39
	bne _3074
	ldr r0, _30A8 @=gUnknown_0300390C
	ldr r1, _30AC @=gUnknown_3980
	bl swi_MusicPlayerStart
_3074:
	b _2B48
	.align 2, 0
_3078: .4byte REG_SIOMULTI0
_307C: .4byte 0x0003FFF8
_3080: .4byte 0x6177614B
_3084: .4byte 0x6F646573
_3088: .4byte REG_IE
_308C: .4byte gUnknown_020000C0
_3090: .4byte gUnknown_020001F8
_3094: .4byte gUnknown_02000000
_3098: .4byte gUnknown_0300000C
_309C: .4byte 0x80808080
_30A0: .4byte 0xEA000036
_30A4: .4byte 0xEA00002E
_30A8: .4byte gUnknown_0300390C
_30AC: .4byte gUnknown_3980

	.global gUnknown_30B0
gUnknown_30B0:
	.2byte 0x0022, 0x0028, 0x0082, 0x0088, 0x00E2, 0x00E8, 0x0142, 0x0148

	.global gUnknown_30C0
gUnknown_30C0:
	.2byte 0x0200 @ size
	.byte 2 @ source bit depth
	.byte 8 @ target bit depth
	.4byte 0 @ offset value

	.global gUnknown_30C8
gUnknown_30C8:
	.2byte 0x01C0 @ size
	.byte 1 @ source bit depth
	.byte 8 @ target bit depth
	.4byte 0x1E @ offset value

	.global gUnknown_30D0
gUnknown_30D0:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
	.byte 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x1C, 0x1E, 0x20, 0x24, 0x28, 0x2A, 0x2C
	.byte 0x30, 0x34, 0x36, 0x38, 0x3C, 0x40, 0x42, 0x44, 0x48, 0x4C, 0x4E, 0x50, 0x54, 0x58, 0x5A, 0x5C
	.byte 0x60, 0x00, 0x00, 0x00

	.global gUnknown_3104
gUnknown_3104:
	.byte 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB
	.byte 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xDB
	.byte 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB
	.byte 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB
	.byte 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB
	.byte 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B
	.byte 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B
	.byte 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B
	.byte 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B
	.byte 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B
	.byte 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B
	.byte 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B
	.byte 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B
	.byte 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B

gUnknown_31B4:
	.byte 0x00, 0x00, 0x00, 0x80, 0x97, 0x7C, 0x9C, 0x87, 0x1E, 0xD6, 0xAC, 0x8F
	.byte 0x52, 0xF0, 0x37, 0x98, 0xCC, 0x17, 0x45, 0xA1, 0x48, 0x08, 0xDC, 0xAA
	.byte 0x34, 0xF3, 0x04, 0xB5, 0xBB, 0x86, 0xC8, 0xBF, 0x2A, 0xF5, 0x2F, 0xCB
	.byte 0xCB, 0xFC, 0x44, 0xD7, 0x3A, 0xF0, 0x11, 0xE4, 0x39, 0xBF, 0xA1, 0xF1

	.global gUnknown_31E8
gUnknown_31E8:
	.2byte 0x0060
	.2byte 0x0084
	.2byte 0x00B0
	.2byte 0x00E0
	.2byte 0x0108
	.2byte 0x0130
	.2byte 0x0160
	.2byte 0x01C0
	.2byte 0x0210
	.2byte 0x0260
	.2byte 0x02A0
	.2byte 0x02C0

	.global gUnknown_3200
gUnknown_3200:
	.4byte 0xFFFFFFFF
	.4byte 0x01F0001F, 0x01F0281F, 0x01F0581F
	.4byte 0x01F00000, 0x01F0280A, 0x01F05816
	.4byte 0x01F07C00, 0x01F07C0A, 0x01F07C16
	.4byte 0x00007C00, 0x00A07C0A, 0x01607C16
	.4byte 0x00007C1F, 0x00A07C1F, 0x01607C1F
	.4byte 0x0000001F, 0x00A0281F, 0x0160581F
	.4byte 0x01F0001F, 0x01F0281F, 0x01F0581F
	.4byte 0x01F07C1F, 0x01F07C1F, 0x01F07C1F

	.global gUnknown_3264
gUnknown_3264:
	@ palettes
	.2byte 0x7C00
	.2byte 0xFF1F
	.2byte 0xFD5F
	.2byte 0x7C1F

	.global gNintendoLogo
gNintendoLogo:
	@ Header
	.byte 0x24, 0xD4, 0x00, 0x00
	@ Binary Tree
	.byte 0x0F, 0x40, 0x00, 0x00, 0x00, 0x01, 0x81, 0x82, 0x82, 0x83, 0x0F, 0x83, 0x0C, 0xC3, 0x03, 0x83
	.byte 0x01, 0x83, 0x04, 0xC3, 0x08, 0x0E, 0x02, 0xC2, 0x0D, 0xC2, 0x07, 0x0B, 0x06, 0x0A, 0x05, 0x09
	@ Data
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
gUnknown_332C: @ size: 0x370
	.incbin "data/unk_332C.bin.lz.huff"

	.global gUnknown_369C
gUnknown_369C:
	@ oam data
	.4byte 0xC2AD2620, 0x01000A40
	.4byte 0xC4962620, 0x0040098C
	.4byte 0xC67F2620, 0x00000980
	.4byte 0xC8682620, 0x000008CC
	.4byte 0xCA502620, 0x000008C0
	.4byte 0xCC392620, 0x0000080C
	.4byte 0xCE222620, 0x00000800
	.4byte 0xC0376466, 0x00005B40
	.4byte 0xC0776466, 0x00005B50
	.4byte 0x81742268, 0x00000290

	.global gUnknown_36EC
gUnknown_36EC:
	.byte -2, -2
	.byte -2, -1
	.byte -1, -1
	.byte  0, -1
	.byte  0,  0
	.byte  1,  0
	.byte  1,  1
	.byte  1,  2
	.byte  2,  2
	.byte -1, -1
	.byte  0, -1
	.byte  0,  0
	.byte  1,  0
	.byte  1,  1
	.byte  0, -1
	.byte  0,  0
	.byte  1,  0
	.byte  0,  0

	THUMB_INTERWORK_VENEER swi_Halt
	THUMB_INTERWORK_VENEER DoSwitchToCGBMode
	THUMB_INTERWORK_VENEER swi_DivArm
	THUMB_INTERWORK_VENEER swi_VBlankIntrWait
	THUMB_INTERWORK_VENEER swi_ObjAffineSet

	.section .rodata
	.global gJumpList
	.global gJumpListEnd
gJumpList: @ 0x374C
	.4byte ply_fine
	.4byte ply_goto
	.4byte ply_patt
	.4byte ply_pend
	.4byte ply_rept
	.4byte ply_fine
	.4byte ply_fine
	.4byte ply_fine
	.4byte ply_fine
	.4byte ply_prio
	.4byte ply_tempo
	.4byte ply_keysh
	.4byte ply_voice
	.4byte ply_vol
	.4byte ply_pan
	.4byte ply_bend
	.4byte ply_bendr
	.4byte ply_lfos
	.4byte ply_lfodl
	.4byte ply_mod
	.4byte ply_modt
	.4byte ply_fine
	.4byte ply_fine
	.4byte ply_tune
	.4byte ply_fine
	.4byte ply_fine
	.4byte ply_fine
	.4byte ply_port
	.4byte ply_fine
	.4byte ply_endtie
	.4byte SampleFreqSet
	.4byte TrackStop
	.4byte FadeOutBody
	.4byte TrkVolPitSet
	.4byte RealClearChain
	.4byte SoundMainBTM
gJumpListEnd:
	.global gUnknown_37C8
gUnknown_37C8:
	.4byte gUnknown_3C00
	.4byte gUnknown_382C
	.byte 0xFF, 0x00, 0x4D, 0xBC

	.4byte gUnknown_3C00
	.4byte gUnknown_39D0
	.byte 0xFF, 0xA5, 0x9A, 0xF9

	.4byte gUnknown_3C00
	.4byte gUnknown_382C
	.byte 0xFF, 0xA5, 0x80, 0xF6

	.global gUnknown_37EC
gUnknown_37EC:
	.byte 0xBC, 0x00, 0xBB, 0x5F, 0xBD, 0x00, 0xBE, 0x4B, 0xBF, 0x40, 0x8F, 0xD5, 0x5B, 0x70, 0x86, 0xB1
	
	.global gUnknown37FC
gUnknown_37FC:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x4B, 0xBF, 0x40, 0x8A, 0xD5, 0x56, 0x70, 0x86, 0xB1
	
	.global gUnknown_380A
gUnknown_380A:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x4B, 0xBF, 0x40, 0x85, 0xD5, 0x53, 0x70, 0x86, 0xB1

	.global gUnknown_3818
gUnknown_3818:
	.byte 0x03, 0x00, 0x00, 0xBC
	.4byte gUnknown_37C8
	.4byte gUnknown_37EC
	.4byte gUnknown_37FC
	.4byte gUnknown_380A

	.global gUnknown_382C
gUnknown_382C:
	.byte 0x00, 0x00, 0x00, 0x40, 0x95, 0xB4, 0x82, 0x00, 0x01, 0x00, 0x00, 0x00, 0x21, 0x00, 0x00, 0x00
	.byte 0x00, 0x19, 0x31, 0x47, 0x5A, 0x6A, 0x75, 0x7D, 0x7F, 0x7D, 0x75, 0x6A, 0x5A, 0x47, 0x31, 0x19
	.byte 0x00, 0xE7, 0xCF, 0xB9, 0xA6, 0x96, 0x8B, 0x83, 0x81, 0x83, 0x8B, 0x96, 0xA6, 0xB9, 0xCF, 0xE7
	.byte 0x00, 0x19, 0x00, 0x00

	.global gUnknown_3860
gUnknown_3860:
	.byte 0xBC, 0x00, 0xBB, 0x54, 0xBD, 0x00, 0xBE, 0x55, 0xBF, 0x40, 0x8F, 0xD5, 0x56, 0x70, 0x86, 0xB1
	
	.global gUnknown_3870
gUnknown_3870:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x55, 0xBF, 0x40, 0x8A, 0xD5, 0x5B, 0x70, 0x86, 0xB1

	.global gUnknown_387E
gUnknown_387E:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x55, 0xBF, 0x40, 0x85, 0xD5, 0x56, 0x70, 0x86, 0xB1

	.global gUnknown_388C
gUnknown_388C:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x55, 0xBF, 0x40, 0xD5, 0x5B, 0x70, 0x86, 0xB1, 0x00, 0x00, 0x00

	.global gUnknown_389C
gUnknown_389C:
	.byte 0x04, 0x00, 0x00, 0xB7
	.4byte gUnknown_37C8
	.4byte gUnknown_3860
	.4byte gUnknown_3870
	.4byte gUnknown_387E
	.4byte gUnknown_388C

	.global gUnknown_38B4
gUnknown_38B4:
	.byte 0xBC, 0x00, 0xBB, 0x4A, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0xE7, 0x41, 0x60, 0x98, 0xB1
	
	.global gUnknown_38C3
gUnknown_38C3:
	.byte 0xBC, 0x00, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0xE7, 0x48, 0x70, 0x98, 0xB1
	
	.global gUnknown_38D0
gUnknown_38D0:
	.byte 0xBC, 0x00, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0x82, 0xE7, 0x4C, 0x6C, 0x98, 0xB1
	
	.global gUnknown_38DE
gUnknown_38DE:
	.byte 0xBC, 0x00, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0x84, 0xE7, 0x4F, 0x6C, 0x98, 0xB1
	
	.global gUnknown_38EC
gUnknown_38EC:	
	.byte 0xBC, 0x00, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0x86, 0xE7, 0x53, 0x6C, 0x98, 0xB1
	
	.global gUnknown_38FA
gUnknown_38FA:	
	.byte 0xBC, 0x00, 0xBD, 0x01, 0xBE, 0x78, 0xBF, 0x40, 0x8A, 0xE7, 0x56, 0x60, 0x98, 0xB1

	.global gUnknown_3908
gUnknown_3908:
	.byte 0x06, 0x00, 0x00, 0xD0
	.4byte gUnknown_37C8
	.4byte gUnknown_38B4
	.4byte gUnknown_38C3
	.4byte gUnknown_38D0
	.4byte gUnknown_38DE
	.4byte gUnknown_38EC
	.4byte gUnknown_38FA

	.global gUnknown_3928
gUnknown_3928:
	.byte 0xBC, 0x00, 0xBB, 0x63, 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0x8F, 0xD5, 0x64, 0x78, 0x86, 0xB1
	
	.global gUnknown_3938
gUnknown_3938:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0x8A, 0xD5, 0x62, 0x78, 0x86, 0xB1

	.global gUnknown_3946
gUnknown_3946:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0x85, 0xD5, 0x60, 0x78, 0x86, 0xB1

	.global gUnknown_3954
gUnknown_3954:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0xD5, 0x5F, 0x50, 0x86, 0xB1

	.global gUnknown_3961
gUnknown_3961:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0x94, 0xD5, 0x66, 0x78, 0x86, 0xB1

	.global gUnknown_396F
gUnknown_396F:
	.byte 0xBC, 0x00, 0xBD, 0x00, 0xBE, 0x5E, 0xBF, 0x40, 0x98, 0x81, 0xDB, 0x67, 0x78, 0x8C, 0xB1, 0x00, 0x00

	.global gUnknown_3980
gUnknown_3980:
	.byte 0x06, 0x00, 0x00, 0xB2
	.4byte gUnknown_37C8
	.4byte gUnknown_3928
	.4byte gUnknown_3938
	.4byte gUnknown_3946
	.4byte gUnknown_3954
	.4byte gUnknown_3961
	.4byte gUnknown_396F

.global gUnknown_39A0
gUnknown_39A0:
	.byte 0xBC, 0x00, 0xBB, 0x4A, 0xBD, 0x02, 0xBE, 0x55, 0xBF, 0x40, 0x84, 0xD3, 0x6C, 0x78, 0x85, 0xB1
	
	.global gUnknown_39B0
gUnknown_39B0:
	.byte 0xBC, 0x00, 0xBD, 0x02, 0xBE, 0x55, 0xBF, 0x40, 0xD3, 0x60, 0x70, 0x84, 0xB1, 0x00, 0x00, 0x00

	.global gUnknown_39C0
gUnknown_39C0:
	.byte 0x02, 0x00, 0x00, 0xD0
	.4byte gUnknown_37C8
	.4byte gUnknown_39A0
	.4byte gUnknown_39B0

	.global gUnknown_39D0
gUnknown_39D0:
	.byte 0x00, 0x00, 0x00, 0x40, 0x58, 0x56, 0x2F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x05, 0x00, 0x00
	.byte 0x0B, 0x3B, 0x48, 0x3E, 0x24, 0xEB, 0xC3, 0xC6, 0xDF, 0x0F, 0x35, 0x37, 0x2A, 0xFF, 0xC0, 0xAD
	.byte 0xBD, 0xE2, 0x1A, 0x32, 0x27, 0x10, 0xD6, 0xB0, 0xBD, 0xD9, 0x0D, 0x44, 0x46, 0x33, 0x0D, 0xD1
	.byte 0xBE, 0xD1, 0xF4, 0x32, 0x58, 0x52, 0x3E, 0x05, 0xC4, 0xB5, 0xC9, 0xF6, 0x31, 0x44, 0x3B, 0x1B
	.byte 0xD4, 0xA5, 0xAC, 0xC9, 0x03, 0x35, 0x35, 0x23, 0xF3, 0xB3, 0xAE, 0xC7, 0xF1, 0x34, 0x51, 0x41
	.byte 0x27, 0xE9, 0xBA, 0xC4, 0xDF, 0x15, 0x51, 0x5C, 0x4D, 0x26, 0xDB, 0xB0, 0xBB, 0xDD, 0x19, 0x46
	.byte 0x45, 0x30, 0xF6, 0xB1, 0xA2, 0xB8, 0xE5, 0x26, 0x3D, 0x2F, 0x0E, 0xCB, 0xA6, 0xB8, 0xD8, 0x15
	.byte 0x4E, 0x4D, 0x37, 0x08, 0xC6, 0xB7, 0xCF, 0xF8, 0x3A, 0x60, 0x58, 0x3D, 0xFF, 0xBB, 0xAF, 0xCA
	.byte 0xFC, 0x39, 0x4E, 0x3E, 0x15, 0xCE, 0xA0, 0xA9, 0xCD, 0x09, 0x3C, 0x3C, 0x22, 0xEC, 0xAE, 0xA9
	.byte 0xC7, 0xF6, 0x39, 0x56, 0x44, 0x22, 0xE3, 0xB4, 0xBE, 0xE2, 0x1A, 0x56, 0x64, 0x4C, 0x1E, 0xD6
	.byte 0xAA, 0xB8, 0xE2, 0x1D, 0x4D, 0x4C, 0x2A, 0xF0, 0xAF, 0x9D, 0xBA, 0xEC, 0x29, 0x45, 0x31, 0x06
	.byte 0xC9, 0xA3, 0xB5, 0xDF, 0x19, 0x50, 0x53, 0x32, 0x01, 0xC5, 0xB1, 0xCF, 0xFF, 0x3B, 0x66, 0x5B
	.byte 0x34, 0xFA, 0xB7, 0xA9, 0xCE, 0x00, 0x3A, 0x56, 0x3C, 0x0C, 0xCE, 0x9D, 0xA8, 0xD5, 0x0C, 0x40
	.byte 0x41, 0x1A, 0xE7, 0xB0, 0xA4, 0xCA, 0xFE, 0x38, 0x5B, 0x43, 0x17, 0xE2, 0xB2, 0xBA, 0xE9, 0x1D
	.byte 0x57, 0x6A, 0x46, 0x15, 0xD7, 0xA6, 0xBA, 0xEB, 0x1C, 0x52, 0x4F, 0x1F, 0xEE, 0xB2, 0x9A, 0xC1
	.byte 0xF2, 0x28, 0x4B, 0x2D, 0xFD, 0xCD, 0xA2, 0xB3, 0xE9, 0x19, 0x4F, 0x56, 0x29, 0xFD, 0xC8, 0xAC
	.byte 0xD3, 0x05, 0x38, 0x6A, 0x5B, 0x27, 0xF9, 0xB9, 0xA7, 0xD7, 0x02, 0x39, 0x5C, 0x34, 0x03, 0xD4
	.byte 0x9C, 0xAA, 0xDF, 0x09, 0x41, 0x43, 0x0D, 0xE7, 0xB7, 0xA1, 0xD2, 0x03, 0x33, 0x5C, 0x3E, 0x0C
	.byte 0xE7, 0xB3, 0xBA, 0xF3, 0x1C, 0x54, 0x6B, 0x3A, 0x0E, 0xDB, 0xA5, 0xBF, 0xF2, 0x19, 0x53, 0x4D
	.byte 0x13, 0xF1, 0xB7, 0x9A, 0xCA, 0xF5, 0x24, 0x4D, 0x25, 0xF6, 0xD6, 0xA4, 0xB6, 0xF2, 0x17, 0x4B
	.byte 0x53, 0x1D, 0xFB, 0xCD, 0xAB, 0xDA, 0x0A, 0x34, 0x69, 0x53, 0x1C, 0xFB, 0xBB, 0xAB, 0xE0, 0x03
	.byte 0x37, 0x5B, 0x29, 0x00, 0xDB, 0x9F, 0xB1, 0xE6, 0x06, 0x3E, 0x3E, 0x03, 0xEB, 0xBE, 0xA3, 0xDA
	.byte 0x05, 0x2D, 0x58, 0x35, 0x06, 0xEC, 0xB6, 0xBF, 0xFA, 0x1A, 0x50, 0x66, 0x2F, 0x0B, 0xE0, 0xAA
	.byte 0xC7, 0xF5, 0x17, 0x51, 0x44, 0x0B, 0xF5, 0xBD, 0xA0, 0xD2, 0xF5, 0x20, 0x47, 0x1B, 0xF5, 0xDE
	.byte 0xAA, 0xBC, 0xF8, 0x14, 0x44, 0x4B, 0x15, 0xFD, 0xD4, 0xB1, 0xE1, 0x0B, 0x2F, 0x62, 0x49, 0x16
	.byte 0xFC, 0xC3, 0xB4, 0xE4, 0x02, 0x33, 0x51, 0x20, 0x00, 0xE1, 0xA9, 0xBA, 0xE9, 0x04, 0x37, 0x33
	.byte 0x00, 0xF0, 0xC6, 0xAC, 0xE0, 0x05, 0x27, 0x4C, 0x2C, 0x05, 0xF0, 0xBE, 0xC7, 0xFD, 0x19, 0x49
	.byte 0x58, 0x28, 0x0A, 0xE4, 0xB6, 0xCF, 0xF5, 0x15, 0x47, 0x38, 0x0A, 0xF8, 0xC6, 0xAD, 0xD7, 0xF6
	.byte 0x1B, 0x39, 0x14, 0xF9, 0xE4, 0xB5, 0xC5, 0xF8, 0x11, 0x39, 0x3D, 0x12, 0xFF, 0xDB, 0xBE, 0xE5
	.byte 0x0A, 0x2C, 0x52, 0x3D, 0x15, 0xFD, 0xCF, 0xC1, 0xE4, 0x02, 0x2C, 0x41, 0x1D, 0x02, 0xE7, 0xB8
	.byte 0xC2, 0xE8, 0x04, 0x2A, 0x27, 0x02, 0xF5, 0xD1, 0xBA, 0xE1, 0x04, 0x20, 0x3A, 0x25, 0x08, 0xF3
	.byte 0xCD, 0xD1, 0xFA, 0x18, 0x3C, 0x48, 0x27, 0x09, 0xEB, 0xC9, 0xD3, 0xF4, 0x14, 0x35, 0x2E, 0x0E
	.byte 0xFA, 0xD5, 0xBD, 0xD6, 0xF6, 0x12, 0x26, 0x13, 0xFF, 0xEA, 0xC7, 0xCC, 0xF5, 0x0F, 0x28, 0x2F
	.byte 0x16, 0x00, 0xE5, 0xCE, 0xE6, 0x09, 0x26, 0x3E, 0x36, 0x17, 0xFE, 0xDF, 0xCE, 0xE2, 0x02, 0x20
	.byte 0x2F, 0x1F, 0x05, 0xEE, 0xCD, 0xC7, 0xE6, 0x01, 0x16, 0x1C, 0x0B, 0xF9, 0xDF, 0xCA, 0xDF, 0x02

	.global gUnknown_3C00
gUnknown_3C00:
	.byte 0x15, 0x25, 0x24, 0x0C, 0xF7, 0xDE, 0xD9, 0xF7, 0x16, 0x2B, 0x37, 0x28, 0x0A, 0xF5, 0xDB, 0xD5
	.byte 0xF2, 0x0F, 0x21, 0x27, 0x15, 0xFD, 0xE5, 0xCB, 0xD3, 0xF5, 0x05, 0x14, 0x17, 0x04, 0xF1, 0xDA
	.byte 0xD2, 0xF1, 0x09, 0x13, 0x23, 0x1B, 0x02, 0xF1, 0xDE, 0xE4, 0x06, 0x1B, 0x29, 0x32, 0x1A, 0x01
	.byte 0xF1, 0xD9, 0xE0, 0x00, 0x10, 0x1F, 0x23, 0x09, 0xF8, 0xE0, 0xCC, 0xE3, 0xFB, 0x03, 0x16, 0x13
	.byte 0xFE, 0xEF, 0xD8, 0xDD, 0xFD, 0x06, 0x13, 0x24, 0x11, 0xFE, 0xF0, 0xE0, 0xF3, 0x0F, 0x18, 0x2B
	.byte 0x2A, 0x0D, 0x00, 0xEC, 0xD9, 0xEF, 0x04, 0x0F, 0x24, 0x1A, 0x02, 0xF7, 0xD8, 0xD2, 0xEF, 0xF7
	.byte 0x06, 0x1B, 0x0B, 0xFC, 0xEB, 0xD6, 0xEB, 0xFF, 0x01, 0x1B, 0x20, 0x08, 0xFE, 0xEB, 0xE5, 0x00
	.byte 0x0C, 0x18, 0x2D, 0x1E, 0x0A, 0x00, 0xE3, 0xDF, 0xF8, 0x00, 0x15, 0x25, 0x10, 0x03, 0xEF, 0xD0
	.byte 0xDE, 0xEE, 0xF4, 0x13, 0x1A, 0x06, 0xFC, 0xE3, 0xDC, 0xF2, 0xF6, 0x07, 0x23, 0x18, 0x07, 0xFC
	.byte 0xE6, 0xEF, 0x02, 0x08, 0x21, 0x2A, 0x16, 0x0B, 0xF7, 0xDD, 0xE8, 0xF7, 0x02, 0x20, 0x20, 0x0D
	.byte 0x02, 0xE1, 0xD2, 0xE3, 0xE8, 0xFF, 0x1E, 0x15, 0x07, 0xF6, 0xDD, 0xE3, 0xED, 0xF6, 0x15, 0x23
	.byte 0x14, 0x08, 0xF3, 0xE7, 0xF4, 0xFE, 0x0E, 0x27, 0x24, 0x16, 0x07, 0xEB, 0xDE, 0xEA, 0xF5, 0x0E
	.byte 0x26, 0x1C, 0x0E, 0xF8, 0xD7, 0xD5, 0xDE, 0xED, 0x10, 0x21, 0x14, 0x05, 0xEC, 0xDC, 0xE1, 0xE9
	.byte 0x01, 0x20, 0x22, 0x13, 0x01, 0xEE, 0xE9, 0xF1, 0x00, 0x18, 0x2A, 0x24, 0x13, 0xFD, 0xE3, 0xDD
	.byte 0xE8, 0xFE, 0x1B, 0x29, 0x1C, 0x08, 0xEB, 0xD2, 0xD1, 0xDF, 0xFD, 0x1E, 0x23, 0x11, 0xFC, 0xE4
	.byte 0xD6, 0xDB, 0xF0, 0x10, 0x27, 0x23, 0x0D, 0xFA, 0xE9, 0xE3, 0xF1, 0x08, 0x21, 0x2F, 0x22, 0x0A
	.byte 0xF4, 0xDB, 0xD9, 0xF0, 0x0A, 0x27, 0x2C, 0x16, 0xFE, 0xDF, 0xC7, 0xD0, 0xEC, 0x0E, 0x2A, 0x23
	.byte 0x08, 0xF4, 0xD9, 0xCC, 0xE1, 0xFF, 0x1D, 0x30, 0x1D, 0x03, 0xF5, 0xDD, 0xDF, 0xFB, 0x11, 0x2D
	.byte 0x34, 0x17, 0x01, 0xE8, 0xCE, 0xDE, 0xFD, 0x18, 0x35, 0x2A, 0x0A, 0xF4, 0xCD, 0xBF, 0xDC, 0xFC
	.byte 0x1F, 0x34, 0x19, 0xFF, 0xEA, 0xC6, 0xCC, 0xF1, 0x0B, 0x2E, 0x32, 0x0E, 0xFF, 0xE8, 0xD0, 0xE9
	.byte 0x04, 0x1D, 0x3E, 0x2C, 0x0A, 0xFB, 0xD4, 0xCA, 0xEE, 0x08, 0x2A, 0x3D, 0x1A, 0x00, 0xE3, 0xB9
	.byte 0xC7, 0xEF, 0x0C, 0x34, 0x30, 0x09, 0xF9, 0xD3, 0xB9, 0xDF, 0xFE, 0x1D, 0x3F, 0x23, 0x04, 0xF8
	.byte 0xD0, 0xD2, 0xF9, 0x0C, 0x33, 0x41, 0x18, 0x04, 0xE8, 0xC0, 0xD8, 0xFD, 0x16, 0x41, 0x33, 0x0A
	.byte 0xF8, 0xC6, 0xB2, 0xDE, 0xFE, 0x24, 0x42, 0x1D, 0x00, 0xEA, 0xB6, 0xC4, 0xF2, 0x09, 0x38, 0x3D
	.byte 0x0F, 0x00, 0xE1, 0xC1, 0xE5, 0x0B, 0x3B, 0x49, 0x19, 0x03, 0xE3, 0xB9, 0xD6, 0xFF, 0x1B, 0x4B
	.byte 0x39, 0x0B, 0xF7, 0xBE, 0xAC, 0xE0, 0x00, 0x2B, 0x4A, 0x20, 0x00, 0xE3, 0xAB, 0xC0, 0xF2, 0x0D
	.byte 0x3F, 0x42, 0x10, 0xFC, 0xD7, 0xBB, 0xE1, 0x00, 0x24, 0x4F, 0x33, 0x09, 0xF5, 0xC6, 0xC0, 0xEF
	.byte 0x0B, 0x39, 0x4E, 0x1F, 0x00, 0xDA, 0xA8, 0xC4, 0xF6, 0x15, 0x46, 0x3C, 0x0A, 0xF3, 0xBF, 0xAA
	.byte 0xDC, 0x00, 0x29, 0x4D, 0x29, 0x00, 0xE9, 0xBF, 0xC8, 0xF4, 0x11, 0x41, 0x4A, 0x1A, 0xFD, 0xDB
	.byte 0xBA, 0xD7, 0x00, 0x24, 0x4E, 0x3B, 0x0A, 0xED, 0xB9, 0xAE, 0xE2, 0x08, 0x33, 0x4C, 0x22, 0xFB
	.byte 0xD6, 0xA9, 0xC0, 0xF4, 0x16, 0x43, 0x42, 0x10, 0xF1, 0xCE, 0xBB, 0xDD, 0x05, 0x2D, 0x4F, 0x35
	.byte 0x04, 0xE9, 0xC5, 0xC3, 0xEF, 0x15, 0x3F, 0x4E, 0x20, 0xF8, 0xD1, 0xAB, 0xC8, 0xFC, 0x21, 0x48
	.byte 0x3D, 0x09, 0xE4, 0xB8, 0xAD, 0xDC, 0x09, 0x31, 0x4B, 0x2A, 0xF9, 0xDA, 0xBF, 0xC7, 0xF4, 0x1D
	.byte 0x44, 0x49, 0x19, 0xF0, 0xD4, 0xC0, 0xD7, 0x07, 0x2F, 0x4E, 0x3C, 0x06, 0xDF, 0xBA, 0xB4, 0xE5
	.byte 0x14, 0x39, 0x4A, 0x24, 0xF0, 0xC8, 0xAD, 0xC1, 0xF8, 0x22, 0x43, 0x40, 0x0D, 0xE0, 0xC9, 0xBF
	.byte 0xDB, 0x0E, 0x35, 0x4C, 0x34, 0xFC, 0xDB, 0xCA, 0xC9, 0xF2, 0x22, 0x43, 0x4B, 0x20, 0xEA, 0xC9
	.byte 0xB4, 0xCC, 0x03, 0x2D, 0x47, 0x3C, 0x04, 0xD3, 0xB7, 0xB3, 0xDD, 0x14, 0x36, 0x46, 0x29, 0xED
	.byte 0xCD, 0xC3, 0xC8, 0xF8, 0x29, 0x42, 0x45, 0x15, 0xE0, 0xD1, 0xC9, 0xDC, 0x11, 0x38, 0x4A, 0x3A
	.byte 0xFE, 0xD2, 0xBF, 0xBD, 0xEC, 0x21, 0x3D, 0x46, 0x21, 0xE1, 0xBF, 0xB4, 0xC5, 0x00, 0x2C, 0x40
	.byte 0x3E, 0x05, 0xD0, 0xC7, 0xC3, 0xDE, 0x19, 0x39, 0x47, 0x30, 0xEF, 0xD1, 0xD0, 0xD0, 0xFB, 0x2D
	.byte 0x43, 0x47, 0x1A, 0xDC, 0xC6, 0xBF, 0xD5, 0x0F, 0x35, 0x44, 0x38, 0xFA, 0xC5, 0xBA, 0xBA, 0xE4
	.byte 0x1F, 0x38, 0x42, 0x22, 0xDE, 0xC6, 0xC6, 0xCD, 0x01, 0x31, 0x40, 0x40, 0x0A, 0xD4, 0xD1, 0xD2
	.byte 0xE6, 0x1D, 0x3C, 0x47, 0x33, 0xF1, 0xC9, 0xC5, 0xC9, 0xF8, 0x2B, 0x3E, 0x41, 0x17, 0xD2, 0xBB
	.byte 0xBA, 0xCE, 0x0A, 0x32, 0x3D, 0x36, 0xF8, 0xC6, 0xC7, 0xC9, 0xE9, 0x22, 0x39, 0x40, 0x23, 0xE3
	.byte 0xCF, 0xD7, 0xDE, 0x07, 0x31, 0x3E, 0x3C, 0x0C, 0xD6, 0xCC, 0xCE, 0xE6, 0x18, 0x33, 0x3A, 0x29
	.byte 0xED, 0xC5, 0xC5, 0xCB, 0xF2, 0x21, 0x31, 0x33, 0x10, 0xD8, 0xCB, 0xD1, 0xDE, 0x0B, 0x2B, 0x33
	.byte 0x2C, 0xFC, 0xD7, 0xDB, 0xE1, 0xF8, 0x1E, 0x30, 0x35, 0x1E, 0xEB, 0xD5, 0xD7, 0xE1, 0x04, 0x25
	.byte 0x2F, 0x2C, 0x05, 0xD7, 0xCE, 0xD2, 0xE6, 0x0D, 0x24, 0x2A, 0x1C, 0xEF, 0xD4, 0xD7, 0xDE, 0xFA
	.byte 0x0B
