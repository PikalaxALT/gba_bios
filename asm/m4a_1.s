	.include "asm/macro.inc"
	.include "asm/gba_constants.inc"
	.text
	.align 2, 0

	THUMB_FUNC_START umull_t
umull_t: @ 0x00001DB4
	adr r2, _umull3232H32
	bx r2
	.ARM
_umull3232H32:
	umull r2, r3, r0, r1
	add r0, r3, #0
	bx lr

	THUMB_FUNC_START swi_SoundDriverMain
swi_SoundDriverMain: @ 0x00001DC4
	ldr r0, _2140 @=gUnknown_03007FF0
	ldr r0, [r0]
	ldr r2, _2144 @=0x68736D53 "Smsh"
	ldr r3, [r0]
	cmp r2, r3
	beq _1DD2
	bx lr
_1DD2:
	.2byte 0x1C5B @ adds r3, r3, #1
	str r3, [r0]
	push {r4, r5, r6, r7, lr}
	mov r1, r8
	mov r2, r9
	mov r3, r10
	mov r4, r11
	push {r0, r1, r2, r3, r4}
	sub sp, #0x14
	ldr r3, [r0, #0x20]
	cmp r3, #0
	beq _1DF2
	ldr r0, [r0, #0x24]
	bl sub_2102
	ldr r0, [sp, #0x14]
_1DF2:
	ldr r3, [r0, #0x28]
	bl sub_2102
	ldr r0, [sp, #0x14]
	ldr r3, [r0, #0x10]
	mov r8, r3
	ldr r5, _2104 @=0x00000350
	adds r5, r5, r0
	ldrb r4, [r0, #4]
	subs r7, r4, #1
	bls _1E12
	ldrb r1, [r0, #0xb]
	subs r1, r1, r7
	mov r2, r8
	muls r2, r1, r2
	adds r5, r5, r2
_1E12:
	str r5, [sp, #8]
	ldr r6, _2108 @=0x00000630
	ldrb r3, [r0, #5]
	cmp r3, #0
	beq _1E74
	add r1, pc, #0x0
	bx r1
	.ARM
	cmp r4, #2
	addeq r7, r0, #0x350
	addne r7, r5, r8
	mov r4, r8
_1E30:
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
	bgt _1E30
	adr r0, _1E9C+1
	bx r0
	.THUMB
_1E74:
	movs r0, #0
	mov r1, r8
	adds r6, r6, r5
	lsrs r1, r1, #3
	bcc _1E82
	stm r5!, {r0}
	stm r6!, {r0}
_1E82:
	lsrs r1, r1, #1
	bcc _1E8E
	stm r5!, {r0}
	stm r6!, {r0}
	stm r5!, {r0}
	stm r6!, {r0}
_1E8E:
	stm r5!, {r0}
	stm r6!, {r0}
	stm r5!, {r0}
	stm r6!, {r0}
	stm r5!, {r0}
	stm r6!, {r0}
	stm r5!, {r0}
	stm r6!, {r0}
	.2byte 0x1E49 @ subs r1, r1, #1
	bgt _1E8E
_1E9C:
	ldr r4, [sp, #0x14]
	ldr r0, [r4, #0x14]
	mov r9, r0
	ldr r0, [r4, #0x18]
	mov r12, r0
	ldrb r0, [r4, #6]
	adds r4, #0x50
_1EB0:
	str r0, [sp, #4]
	ldr r3, [r4, #0x24]
	ldrb r6, [r4]
	movs r0, #0xc7
	tst r0, r6
	bne _1EBE
	b _20E4
_1EBE:
	movs r0, #0x80
	tst r0, r6
	beq _1EEE
_1EC4:
	movs r0, #0x40
	tst r0, r6
	bne _1EFE
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
	beq _1F46
	movs r0, #0x10
	orrs r6, r0
	strb r6, [r4]
	b _1F46
_1EEE:
	ldrb r5, [r4, #9]
	movs r0, #4
	tst r0, r6
	beq _1F04
	ldrb r0, [r4, #0xd]
	.2byte 0x1E40 @ subs r0, r0, #1
	strb r0, [r4, #0xd]
	bhi _1F54
_1EFE:
	movs r0, #0
	strb r0, [r4]
	b _20E4
_1F04:
	movs r0, #0x40
	tst r0, r6
	beq _1F24
	ldrb r0, [r4, #7]
	muls r5, r0, r5
	lsrs r5, r5, #8
	ldrb r0, [r4, #0xc]
	cmp r5, r0
	bhi _1F54
_1F16:
	ldrb r5, [r4, #0xc]
	cmp r5, #0
	beq _1EFE
	movs r0, #4
	orrs r6, r0
	strb r6, [r4]
	b _1F54
_1F24:
	movs r2, #3
	ands r2, r6
	cmp r2, #2
	bne _1F42
	ldrb r0, [r4, #5]
	muls r5, r0, r5
	lsrs r5, r5, #8
	ldrb r0, [r4, #6]
	cmp r5, r0
	bhi _1F54
	adds r5, r0, #0
	beq _1F16
	.2byte 0x1E76 @ subs r6, r6, #1
	strb r6, [r4]
	b _1F54
_1F42:
	cmp r2, #3
	bne _1F54
_1F46:
	ldrb r0, [r4, #4]
	adds r5, r5, r0
	cmp r5, #0xff
	bcc _1F54
	movs r5, #0xff
	.2byte 0x1E76 @ subs r6, r6, #1
	strb r6, [r4]
_1F54:
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
	beq _1F88
	adds r0, r3, #0
	adds r0, #0x10
	ldr r1, [r3, #8]
	adds r0, r0, r1
	str r0, [sp, #0xc]
	ldr r0, [r3, #0xc]
	subs r0, r0, r1
	str r0, [sp, #0x10]
_1F88:
	ldr r5, [sp, #8]
	ldr r2, [r4, #0x18]
	ldr r3, [r4, #0x28]
	adr r0, _1F94
	bx r0
	.ARM
_1F94:
	str r8, [sp]
	ldrb r10, [r4, #0xa]
	ldrb r11, [r4, #0xb]
	ldrb r0, [r4, #1]
	tst r0, #8
	beq _1FFC
_1FAC:
	ldrsb r6, [r3], #1
	mul r1, r6, r11
	ldrb r0, [r5, #0x630]
	add r0, r0, r1, asr #8
	strb r0, [r5, #0x630]
	mul r1, r6, r10
	ldrb r0, [r5]
	add r0, r0, r1, asr #8
	strb r0, [r5], #1
	subs r2, r2, #1
	bne _1FF0
	ldr r2, [sp, #0x10]
	cmp r2, #0
	ldrne r3, [sp, #0xc]
	bne _1FF0
	strb r2, [r4]
	b _20D8
_1FF0:
	subs r8, r8, #1
	bgt _1FAC
	b _20D0
_1FFC:
	ldr r7, [r4, #0x1c]
	ldr lr, [r4, #0x20]
_2004:
	cmp r7, r9, lsl #2
	bcc _2028
_200C:
	cmp r2, #4
	ble _204C
	sub r2, r2, #4
	add r3, r3, #4
	sub r7, r7, r9, lsl #2
	cmp r7, r9, lsl #2
	bhs _200C
_2028:
	cmp r7, r9, lsl #1
	bcc _2044
	cmp r2, #2
	ble _204C
	sub r2, r2, #2
	add r3, r3, #2
	sub r7, r7, r9, lsl #1
_2044:
	cmp r7, r9
	bcc _207C
_204C:
	subs r2, r2, #1
	bne _206C
	ldr r2, [sp, #0x10]
	cmp r2, #0
	ldrne r3, [sp, #0xc]
	bne _2070
	strb r2, [r4]
	b _20D8
_206C:
	add r3, r3, #1
_2070:
	sub r7, r7, r9
	cmp r7, r9
	bhs _204C
_207C:
	ldrsb r0, [r3]
	ldrsb r1, [r3, #1]
	sub r1, r1, r0
	mul r6, r1, r7
	mul r1, r6, r12
	add r6, r0, r1, asr #23
	mul r1, r6, r11
	ldrb r0, [r5, #0x630]
	add r0, r0, r1, asr #8
	strb r0, [r5, #0x630]
	mul r1, r6, r10
	ldrb r0, [r5]
	add r0, r0, r1, asr #8
	strb r0, [r5], #1
	add r7, r7, lr
	subs r8, r8, #1
	beq _20CC
	cmp r7, r9
	bcc _207C
	b _2004
_20CC:
	str r7, [r4, #0x1c]
_20D0:
	str r2, [r4, #0x18]
	str r3, [r4, #0x28]
_20D8:
	ldr r8, [sp]
	adr r0, _20E4+1
	bx r0
	.THUMB
_20E4:
	ldr r0, [sp, #4]
	.2byte 0x1E40 @ subs r0, r0, #1
	ble _20EE
	adds r4, #0x40
	b _1EB0
_20EE:
	ldr r0, [sp, #0x14]
	ldr r3, _2144 @=0x68736D53 "Smsh"
	str r3, [r0]
	add sp, #0x18
	pop {r0, r1, r2, r3, r4, r5, r6, r7}
	mov r8, r0
	mov r9, r1
	mov r10, r2
	mov r11, r3
	pop {r3}

	UNALIGNED_THUMB_FUNC_START sub_2102
sub_2102: @ 0x00002102
	bx r3
	.align 2, 0
_2104: .4byte 0x00000350
_2108: .4byte 0x00000630

	THUMB_FUNC_START swi_SoundDriverVSync
swi_SoundDriverVSync: @ 0x0000210C
	ldr r0, _2140 @=gUnknown_03007FF0
	ldr r0, [r0]
	ldr r2, _2144 @=0x68736D53 "Smsh"
	ldr r3, [r0]
	cmp r2, r3
	bne _2136
	ldrb r1, [r0, #4]
	.2byte 0x1E49 @ subs r1, r1, #1
	strb r1, [r0, #4]
	bgt _2136
	ldrb r1, [r0, #0xb]
	strb r1, [r0, #4]
	movs r0, #0
	movs r1, #0xb6
	lsls r1, r1, #8
	ldr r2, _2138 @=REG_DMA1CNT_H
	ldr r3, _213C @=REG_DMA2CNT_H
	strh r0, [r2]
	strh r0, [r3]
	strh r1, [r2]
	strh r1, [r3]
_2136:
	bx lr
	.align 2, 0
_2138: .4byte REG_DMA1CNT_H
_213C: .4byte REG_DMA2CNT_H
_2140: .4byte gUnknown_03007FF0
_2144: .4byte 0x68736D53

	THUMB_FUNC_START sub_2148
sub_2148: @ 0x00002148
	ldr r2, _23AC @=0x68736D53 "Smsh"
	ldr r3, [r0, #0x34]
	cmp r2, r3
	beq _2152
	bx lr
_2152:
	.2byte 0x1C5B @ adds r3, r3, #1
	str r3, [r0, #0x34]
	push {r4, r5, r6, r7, lr}
	mov r4, r8
	mov r5, r9
	mov r6, r10
	mov r7, r11
	push {r4, r5, r6, r7}
	adds r7, r0, #0
	ldr r3, [r7, #0x38]
	cmp r3, #0
	beq _2170
	ldr r0, [r7, #0x3c]
	bl sub_2102
_2170:
	ldr r0, [r7, #4]
	cmp r0, #0
	bge _2178
	b _2392
_2178:
	ldr r0, _23A8 @=gUnknown_03007FF0
	ldr r0, [r0]
	mov r8, r0
	adds r0, r7, #0
	bl FadeOutBody
	ldrh r0, [r7, #0x22]
	ldrh r1, [r7, #0x20]
	adds r0, r0, r1
	b _22D6
_218C:
	ldrb r2, [r7, #8]
	ldr r5, [r7, #0x2c]
	movs r3, #1
	movs r4, #0
_2194:
	ldrb r0, [r5]
	movs r1, #0x80
	tst r1, r0
	bne _219E
	b _22B6
_219E:
	mov r9, r2
	mov r10, r3
	orrs r4, r3
	mov r11, r4
	ldr r4, [r5, #0x20]
	cmp r4, #0
	beq _21D4
_21AC:
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	beq _21C8
	ldrb r0, [r4, #0x10]
	cmp r0, #0
	beq _21CE
	.2byte 0x1E40 @ subs r0, r0, #1
	strb r0, [r4, #0x10]
	bne _21CE
	movs r0, #0x40
	orrs r1, r0
	strb r1, [r4]
	b _21CE
_21C8:
	adds r0, r4, #0
	bl RealClearChain
_21CE:
	ldr r4, [r4, #0x34]
	cmp r4, #0
	bne _21AC
_21D4:
	ldrb r3, [r5]
	movs r0, #0x40
	tst r0, r3
	beq _2254
	adds r0, r5, #0
	bl SoundMainBTM
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
	b _2254
_21FA:
	ldr r2, [r5, #0x40]
	ldrb r1, [r2]
	cmp r1, #0x80
	bhs _2206
	ldrb r1, [r5, #7]
	b _2210
_2206:
	.2byte 0x1C52 @ adds r2, r2, #1
	str r2, [r5, #0x40]
	cmp r1, #0xbd
	bcc _2210
	strb r1, [r5, #7]
_2210:
	cmp r1, #0xcf
	bcc _2226
	mov r0, r8
	ldr r3, [r0, #0x38]
	adds r0, r1, #0
	subs r0, #0xcf
	adds r1, r7, #0
	adds r2, r5, #0
	bl sub_2102
	b _2254
_2226:
	cmp r1, #0xb0
	bls _224A
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
	bl sub_2102
	ldrb r0, [r5]
	cmp r0, #0
	beq _22B0
	b _2254
_224A:
	ldr r0, _23A4 @=gUnknown_30D0
	subs r1, #0x80
	adds r1, r1, r0
	ldrb r0, [r1]
	strb r0, [r5, #1]
_2254:
	ldrb r0, [r5, #1]
	cmp r0, #0
	beq _21FA
	.2byte 0x1E40 @ subs r0, r0, #1
	strb r0, [r5, #1]
	ldrb r1, [r5, #0x19]
	cmp r1, #0
	beq _22B0
	ldrb r0, [r5, #0x17]
	cmp r0, #0
	beq _22B0
	ldrb r0, [r5, #0x1c]
	cmp r0, #0
	beq _2276
	.2byte 0x1E40 @ subs r0, r0, #1
	strb r0, [r5, #0x1c]
	b _22B0
_2276:
	ldrb r0, [r5, #0x1a]
	adds r0, r0, r1
	strb r0, [r5, #0x1a]
	adds r1, r0, #0
	subs r0, #0x40
	lsls r0, r0, #0x18
	bpl _228A
	lsls r2, r1, #0x18
	asrs r2, r2, #0x18
	b _228E
_228A:
	movs r0, #0x80
	subs r2, r0, r1
_228E:
	ldrb r0, [r5, #0x17]
	muls r0, r2, r0
	asrs r2, r0, #6
	ldrb r0, [r5, #0x16]
	eors r0, r2
	lsls r0, r0, #0x18
	beq _22B0
	strb r2, [r5, #0x16]
	ldrb r0, [r5]
	ldrb r1, [r5, #0x18]
	cmp r1, #0
	bne _22AA
	movs r1, #0xc
	b _22AC
_22AA:
	movs r1, #3
_22AC:
	orrs r0, r1
	strb r0, [r5]
_22B0:
	mov r2, r9
	mov r3, r10
	mov r4, r11
_22B6:
	.2byte 0x1E52 @ subs r2, r2, #1
	ble _22C2
	movs r0, #0x50
	adds r5, r5, r0
	lsls r3, r3, #1
	b _2194
_22C2:
	mov r6, r11
	cmp r6, #0
	bne _22D0
	movs r0, #0x80
	lsls r0, r0, #0x18
	str r0, [r7, #4]
	b _2392
_22D0:
	str r6, [r7, #4]
	ldrh r0, [r7, #0x22]
	subs r0, #0x96
_22D6:
	strh r0, [r7, #0x22]
	cmp r0, #0x96
	bcc _22DE
	b _218C
_22DE:
	ldrb r2, [r7, #8]
	ldr r5, [r7, #0x2c]
_22E2:
	ldrb r0, [r5]
	movs r1, #0x80
	tst r1, r0
	beq _2388
	movs r1, #0xf
	tst r1, r0
	beq _2388
	mov r9, r2
	adds r0, r7, #0
	adds r1, r5, #0
	bl TrkVolPitSet
	ldr r4, [r5, #0x20]
	cmp r4, #0
	beq _237E
_2300:
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	bne _2310
	adds r0, r4, #0
	bl RealClearChain
	b _2378
_2310:
	ldrb r0, [r4, #1]
	movs r6, #7
	ands r6, r0
	ldrb r3, [r5]
	movs r0, #3
	tst r0, r3
	beq _233C
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
	beq _233C
	ldrb r0, [r4, #0x1d]
	movs r1, #1
	orrs r0, r1
	strb r0, [r4, #0x1d]
_233C:
	movs r0, #0xc
	tst r0, r3
	beq _2378
	ldrb r1, [r4, #8]
	movs r0, #8
	ldrsb r0, [r5, r0]
	adds r2, r1, r0
	bpl _234E
	movs r2, #0
_234E:
	cmp r6, #0
	beq _236C
	mov r0, r8
	ldr r3, [r0, #0x30]
	adds r1, r2, #0
	ldrb r2, [r5, #9]
	adds r0, r6, #0
	bl sub_2102
	str r0, [r4, #0x20]
	ldrb r0, [r4, #0x1d]
	movs r1, #2
	orrs r0, r1
	strb r0, [r4, #0x1d]
	b _2378
_236C:
	adds r1, r2, #0
	ldrb r2, [r5, #9]
	ldr r0, [r4, #0x24]
	bl swi_MIDIKey2Freq
	str r0, [r4, #0x20]
_2378:
	ldr r4, [r4, #0x34]
	cmp r4, #0
	bne _2300
_237E:
	ldrb r0, [r5]
	movs r1, #0xf0
	ands r0, r1
	strb r0, [r5]
	mov r2, r9
_2388:
	.2byte 0x1E52 @ subs r2, r2, #1
	ble _2392
	movs r0, #0x50
	adds r5, r5, r0
	bgt _22E2
_2392:
	ldr r0, _23AC @=0x68736D53 "Smsh"
	str r0, [r7, #0x34]
	pop {r0, r1, r2, r3, r4, r5, r6, r7}
	mov r8, r0
	mov r9, r1
	mov r10, r2
	mov r11, r3
	pop {r0}
	bx r0
	.align 2, 0
_23A4: .4byte gUnknown_30D0
_23A8: .4byte gUnknown_03007FF0
_23AC: .4byte 0x68736D53

	THUMB_FUNC_START SoundMainBTM
SoundMainBTM: @ 0x000023B0
	mov r12, r4
	movs r1, #0
	movs r2, #0
	movs r3, #0
	movs r4, #0
	stm r0!, {r1, r2, r3, r4}
	stm r0!, {r1, r2, r3, r4}
	stm r0!, {r1, r2, r3, r4}
	stm r0!, {r1, r2, r3, r4}
	mov r4, r12
	bx lr

	UNALIGNED_THUMB_FUNC_START RealClearChain
RealClearChain: @ 0x000023C6
	ldr r3, [r0, #0x2c]
	cmp r3, #0
	beq _23E4
	ldr r1, [r0, #0x34]
	ldr r2, [r0, #0x30]
	cmp r2, #0
	beq _23D8
	str r1, [r2, #0x34]
	b _23DA
_23D8:
	str r1, [r3, #0x20]
_23DA:
	cmp r1, #0
	beq _23E0
	str r2, [r1, #0x30]
_23E0:
	movs r1, #0
	str r1, [r0, #0x2c]
_23E4:
	bx lr

	UNALIGNED_THUMB_FUNC_START TrackStop
TrackStop: @ 0x000023E6
	push {r4, r5, r6, lr}
	adds r5, r1, #0
	ldrb r1, [r5]
	movs r0, #0x80
	tst r0, r1
	beq _241E
	ldr r4, [r5, #0x20]
	cmp r4, #0
	beq _241C
	movs r6, #0
_23FA:
	ldrb r0, [r4]
	cmp r0, #0
	beq _2416
	ldrb r0, [r4, #1]
	movs r3, #7
	ands r0, r3
	beq _2412
	ldr r3, _2620 @=gUnknown_03007FF0
	ldr r3, [r3]
	ldr r3, [r3, #0x2c]
	bl sub_2102
_2412:
	strb r6, [r4]
	str r6, [r4, #0x2c]
_2416:
	ldr r4, [r4, #0x34]
	cmp r4, #0
	bne _23FA
_241C:
	str r4, [r5, #0x20]
_241E:
	pop {r4, r5, r6}
	pop {r0}
	bx r0

	THUMB_FUNC_START sub_2424
sub_2424: @ 0x00002424
	push {r4, r5, r6, r7, lr}
	mov r4, r8
	mov r5, r9
	mov r6, r10
	mov r7, r11
	push {r4, r5, r6, r7}
	sub sp, #0x14
	str r1, [sp]
	adds r5, r2, #0
	ldr r1, _2620 @=gUnknown_03007FF0
	ldr r1, [r1]
	str r1, [sp, #4]
	ldr r1, _2624 @=gUnknown_30D0
	adds r0, r0, r1
	ldrb r0, [r0]
	strb r0, [r5, #4]
	ldr r3, [r5, #0x40]
	ldrb r0, [r3]
	cmp r0, #0x80
	bhs _246A
	strb r0, [r5, #5]
	.2byte 0x1C5B @ adds r3, r3, #1
	ldrb r0, [r3]
	cmp r0, #0x80
	bhs _2468
	strb r0, [r5, #6]
	.2byte 0x1C5B @ adds r3, r3, #1
	ldrb r0, [r3]
	cmp r0, #0x80
	bhs _2468
	ldrb r1, [r5, #4]
	adds r1, r1, r0
	strb r1, [r5, #4]
	.2byte 0x1C5B @ adds r3, r3, #1
_2468:
	str r3, [r5, #0x40]
_246A:
	adds r4, r5, #0
	adds r4, #0x24
	ldrb r2, [r4]
	movs r0, #0xc0
	tst r0, r2
	beq _24C0
	ldrb r3, [r5, #5]
	movs r0, #0x40
	tst r0, r2
	beq _2486
	ldr r1, [r5, #0x2c]
	adds r1, r1, r3
	ldrb r0, [r1]
	b _2488
_2486:
	adds r0, r3, #0
_2488:
	lsls r1, r0, #1
	adds r1, r1, r0
	lsls r1, r1, #2
	ldr r0, [r5, #0x28]
	adds r1, r1, r0
	mov r9, r1
	mov r6, r9
	ldrb r1, [r6]
	movs r0, #0xc0
	tst r0, r1
	beq _24A0
	b _260E
_24A0:
	movs r0, #0x80
	tst r0, r2
	beq _24C4
	ldrb r1, [r6, #3]
	movs r0, #0x80
	tst r0, r1
	beq _24BC
	subs r1, #0xc0
	lsls r1, r1, #1
	strb r1, [r5, #0x15]
	ldrb r0, [r5]
	movs r1, #3
	orrs r0, r1
	strb r0, [r5]
_24BC:
	ldrb r3, [r6, #1]
	b _24C4
_24C0:
	mov r9, r4
	ldrb r3, [r5, #5]
_24C4:
	str r3, [sp, #8]
	ldr r6, [sp]
	ldrb r1, [r6, #9]
	ldrb r0, [r5, #0x1d]
	adds r0, r0, r1
	cmp r0, #0xff
	bls _24D4
	movs r0, #0xff
_24D4:
	str r0, [sp, #0x10]
	mov r6, r9
	ldrb r0, [r6]
	movs r6, #7
	ands r6, r0
	str r6, [sp, #0xc]
	beq _2514
	ldr r0, [sp, #4]
	ldr r4, [r0, #0x1c]
	cmp r4, #0
	bne _24EC
	b _260E
_24EC:
	.2byte 0x1E76 @ subs r6, r6, #1
	lsls r0, r6, #6
	adds r4, r4, r0
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	beq _2568
	movs r0, #0x40
	tst r0, r1
	bne _2568
	ldrb r1, [r4, #0x13]
	ldr r0, [sp, #0x10]
	cmp r1, r0
	bcc _2568
	beq _250C
	b _260E
_250C:
	ldr r0, [r4, #0x2c]
	cmp r0, r5
	bhs _2568
	b _260E
_2514:
	ldr r6, [sp, #0x10]
	adds r7, r5, #0
	movs r2, #0
	mov r8, r2
	ldr r4, [sp, #4]
	ldrb r3, [r4, #6]
	adds r4, #0x50
_2522:
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	beq _2568
	movs r0, #0x40
	tst r0, r1
	beq _253C
	cmp r2, #0
	bne _2540
	.2byte 0x1C52 @ adds r2, r2, #1
	ldrb r6, [r4, #0x13]
	ldr r7, [r4, #0x2c]
	b _255A
_253C:
	cmp r2, #0
	bne _255C
_2540:
	ldrb r0, [r4, #0x13]
	cmp r0, r6
	bhs _254C
	adds r6, r0, #0
	ldr r7, [r4, #0x2c]
	b _255A
_254C:
	bhi _255C
	ldr r0, [r4, #0x2c]
	cmp r0, r7
	bls _2558
	adds r7, r0, #0
	b _255A
_2558:
	bcc _255C
_255A:
	mov r8, r4
_255C:
	adds r4, #0x40
	.2byte 0x1E5B @ subs r3, r3, #1
	bgt _2522
	mov r4, r8
	cmp r4, #0
	beq _260E
_2568:
	adds r0, r4, #0
	bl RealClearChain
	movs r1, #0
	str r1, [r4, #0x30]
	ldr r3, [r5, #0x20]
	str r3, [r4, #0x34]
	cmp r3, #0
	beq _257C
	str r4, [r3, #0x30]
_257C:
	str r4, [r5, #0x20]
	str r5, [r4, #0x2c]
	ldrb r0, [r5, #0x1b]
	strb r0, [r5, #0x1c]
	cmp r0, r1
	beq _258C
	strb r1, [r5, #0x1a]
	strb r1, [r5, #0x16]
_258C:
	ldr r0, [sp]
	adds r1, r5, #0
	bl TrkVolPitSet
	ldr r0, [r5, #4]
	str r0, [r4, #0x10]
	ldr r0, [sp, #0x10]
	strb r0, [r4, #0x13]
	ldr r0, [sp, #8]
	strb r0, [r4, #8]
	mov r6, r9
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
	bpl _25D0
	movs r3, #0
_25D0:
	ldr r6, [sp, #0xc]
	cmp r6, #0
	beq _25F6
	mov r6, r9
	ldrb r0, [r6, #2]
	strb r0, [r4, #0x1e]
	ldrb r1, [r6, #3]
	movs r0, #0x80
	tst r0, r1
	bne _25E6
	strb r1, [r4, #0x1f]
_25E6:
	ldrb r2, [r5, #9]
	adds r1, r3, #0
	ldr r0, [sp, #0xc]
	ldr r3, [sp, #4]
	ldr r3, [r3, #0x30]
	bl sub_2102
	b _2600
_25F6:
	ldrb r2, [r5, #9]
	adds r1, r3, #0
	adds r0, r7, #0
	bl swi_MIDIKey2Freq
_2600:
	str r0, [r4, #0x20]
	movs r0, #0x80
	strb r0, [r4]
	ldrb r1, [r5]
	movs r0, #0xf0
	ands r0, r1
	strb r0, [r5]
_260E:
	add sp, #0x14
	pop {r0, r1, r2, r3, r4, r5, r6, r7}
	mov r8, r0
	mov r9, r1
	mov r10, r2
	mov r11, r3
	pop {r0}
	bx r0
	.align 2, 0
_2620: .4byte gUnknown_03007FF0
_2624: .4byte gUnknown_30D0

	THUMB_FUNC_START ply_endtie
ply_endtie: @ 0x00002628
	push {r4, lr}
	ldr r2, [r1, #0x40]
	ldrb r3, [r2]
	cmp r3, #0x80
	bhs _263A
	strb r3, [r1, #5]
	.2byte 0x1C52 @ adds r2, r2, #1
	str r2, [r1, #0x40]
	b _263C
_263A:
	ldrb r3, [r1, #5]
_263C:
	ldr r1, [r1, #0x20]
	cmp r1, #0
	beq _265E
	movs r4, #0x83
_2644:
	ldrb r2, [r1]
	tst r2, r4
	beq _2658
	ldrb r0, [r1, #0x11]
	cmp r0, r3
	bne _2658
	movs r0, #0x40
	orrs r2, r0
	strb r2, [r1]
	b _265E
_2658:
	ldr r1, [r1, #0x34]
	cmp r1, #0
	bne _2644
_265E:
	pop {r4}
	pop {r0}
	bx r0

	THUMB_FUNC_START ply_fine
ply_fine:
	push {r4, r5, lr}
	adds r5, r1, #0
	ldr r4, [r5, #0x20]
	cmp r4, #0
	beq _2688
_266E:
	ldrb r1, [r4]
	movs r0, #0xc7
	tst r0, r1
	beq _267C
	movs r0, #0x40
	orrs r1, r0
	strb r1, [r4]
_267C:
	adds r0, r4, #0
	bl RealClearChain
	ldr r4, [r4, #0x34]
	cmp r4, #0
	bne _266E
_2688:
	movs r0, #0
	strb r0, [r5]
	pop {r4, r5}
	pop {r0}
	bx r0

	UNALIGNED_THUMB_FUNC_START swi_GetJumpList
swi_GetJumpList: @ 0x00002692
	mov r12, lr
	movs r1, #0x24 @ (gJumpListEnd - gJumpList) / 4
	ldr r2, _26C0 @=gJumpList
_2698:
	ldr r3, [r2]
	bl sub_26AA
	stm r0!, {r3}
	.2byte 0x1D12 @ adds r2, r2, #4
	.2byte 0x1E49 @ subs r1, r1, #1
	bgt _2698
	bx r12

	THUMB_FUNC_START sub_26A8
sub_26A8: @ 0x000026A8
	ldrb r3, [r2]
sub_26AA:
	push {r0}
	lsrs r0, r2, #0x19
	bne _26BC
	ldr r0, _26C0 @=gJumpList
	cmp r2, r0
	bcc _26BA
	lsrs r0, r2, #0xe
	beq _26BC
_26BA:
	movs r3, #0
_26BC:
	pop {r0}
	bx lr
	.align 2, 0
_26C0: .4byte gJumpList

	THUMB_FUNC_START sub_26C4
sub_26C4: @ 0x000026C4
	ldr r2, [r1, #0x40]

	UNALIGNED_THUMB_FUNC_START sub_26C6
sub_26C6: @ 0x000026C6
	adds r3, r2, #1
	str r3, [r1, #0x40]
	ldrb r3, [r2]
	b sub_26AA

	UNALIGNED_THUMB_FUNC_START ply_goto
ply_goto:
	push {lr}
_26D0:
	ldr r2, [r1, #0x40]
	ldrb r0, [r2, #3]
	lsls r0, r0, #8
	ldrb r3, [r2, #2]
	orrs r0, r3
	lsls r0, r0, #8
	ldrb r3, [r2, #1]
	orrs r0, r3
	lsls r0, r0, #8
	bl sub_26A8
	orrs r0, r3
	str r0, [r1, #0x40]
	pop {r0}
	bx r0

	UNALIGNED_THUMB_FUNC_START ply_patt
ply_patt: @ 0x000026EE
	ldrb r2, [r1, #2]
	cmp r2, #3
	bhs _2706
	lsls r2, r2, #2
	adds r3, r1, r2
	ldr r2, [r1, #0x40]
	.2byte 0x1D12 @ adds r2, r2, #4
	str r2, [r3, #0x44]
	ldrb r2, [r1, #2]
	.2byte 0x1C52 @ adds r2, r2, #1
	strb r2, [r1, #2]
	b ply_goto
_2706:
	b ply_fine

	THUMB_FUNC_START ply_pend
ply_pend: @ 0x00002708
	ldrb r2, [r1, #2]
	cmp r2, #0
	beq _271A
	.2byte 0x1E52 @ subs r2, r2, #1
	strb r2, [r1, #2]
	lsls r2, r2, #2
	adds r3, r1, r2
	ldr r2, [r3, #0x44]
	str r2, [r1, #0x40]
_271A:
	bx lr

	THUMB_FUNC_START ply_rept
ply_rept: @ 0x0000271C
	push {lr}
	ldr r2, [r1, #0x40]
	ldrb r3, [r2]
	cmp r3, #0
	bne _272C
	.2byte 0x1C52 @ adds r2, r2, #1
	str r2, [r1, #0x40]
	b _26D0
_272C:
	ldrb r3, [r1, #3]
	.2byte 0x1C5B @ adds r3, r3, #1
	strb r3, [r1, #3]
	mov r12, r3
	bl sub_26C4
	cmp r12, r3
	bhs _273E
	b _26D0
_273E:
	movs r3, #0
	strb r3, [r1, #3]
	.2byte 0x1D52 @ adds r2, r2, #5
	str r2, [r1, #0x40]
	pop {r0}
	bx r0

	UNALIGNED_THUMB_FUNC_START ply_prio
ply_prio: @ 0x0000274A
	mov r12, lr
	bl sub_26C4
	strb r3, [r1, #0x1d]
	bx r12

	THUMB_FUNC_START ply_tempo
ply_tempo: @ 0x00002754
	mov r12, lr
	bl sub_26C4
	lsls r3, r3, #1
	strh r3, [r0, #0x1c]
	ldrh r2, [r0, #0x1e]
	muls r3, r2, r3
	lsrs r3, r3, #8
	strh r3, [r0, #0x20]
	bx r12

	THUMB_FUNC_START ply_keysh
ply_keysh: @ 0x00002768
	mov r12, lr
	bl sub_26C4
	strb r3, [r1, #0xa]
	ldrb r3, [r1]
	movs r2, #0xc
	orrs r3, r2
	strb r3, [r1]
	bx r12

	UNALIGNED_THUMB_FUNC_START ply_voice
ply_voice: @ 0x0000277A
	mov r12, lr
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
	bl sub_26AA
	str r3, [r1, #0x24]
	ldr r3, [r2, #4]
	bl sub_26AA
	str r3, [r1, #0x28]
	ldr r3, [r2, #8]
	bl sub_26AA
	str r3, [r1, #0x2c]
	bx r12

	THUMB_FUNC_START ply_vol
ply_vol: @ 0x000027A8
	mov r12, lr
	bl sub_26C4
	strb r3, [r1, #0x12]
	ldrb r3, [r1]
	movs r2, #3
	orrs r3, r2
	strb r3, [r1]
	bx r12

	UNALIGNED_THUMB_FUNC_START ply_pan
ply_pan: @ 0x000027BA
	mov r12, lr
	bl sub_26C4
	subs r3, #0x40
	strb r3, [r1, #0x14]
	ldrb r3, [r1]
	movs r2, #3
	orrs r3, r2
	strb r3, [r1]
	bx r12

	UNALIGNED_THUMB_FUNC_START ply_bend
ply_bend: @ 0x000027CE
	mov r12, lr
	bl sub_26C4
	subs r3, #0x40
	strb r3, [r1, #0xe]
	ldrb r3, [r1]
	movs r2, #0xc
	orrs r3, r2
	strb r3, [r1]
	bx r12

	UNALIGNED_THUMB_FUNC_START ply_bendr
ply_bendr: @ 0x000027E2
	mov r12, lr
	bl sub_26C4
	strb r3, [r1, #0xf]
	ldrb r3, [r1]
	movs r2, #0xc
	orrs r3, r2
	strb r3, [r1]
	bx r12

	THUMB_FUNC_START ply_lfos
ply_lfos: @ 0x000027F4
	mov r12, lr
	bl sub_26C4
	strb r3, [r1, #0x19]
	cmp r3, #0
	bne _2802
	strb r3, [r1, #0x16]
_2802:
	bx r12

	THUMB_FUNC_START ply_lfodl
ply_lfodl: @ 0x00002804
	mov r12, lr
	bl sub_26C4
	strb r3, [r1, #0x1b]
	bx r12

	UNALIGNED_THUMB_FUNC_START ply_mod
ply_mod: @ 0x0000280E
	mov r12, lr
	bl sub_26C4
	strb r3, [r1, #0x17]
	cmp r3, #0
	bne _281C
	strb r3, [r1, #0x16]
_281C:
	bx r12

	UNALIGNED_THUMB_FUNC_START ply_modt
ply_modt: @ 0x0000281E
	mov r12, lr
	bl sub_26C4
	ldrb r0, [r1, #0x18]
	cmp r0, r3
	beq _2834
	strb r3, [r1, #0x18]
	ldrb r3, [r1]
	movs r2, #0xf
	orrs r3, r2
	strb r3, [r1]
_2834:
	bx r12

	UNALIGNED_THUMB_FUNC_START ply_tune
ply_tune: @ 0x00002836
	mov r12, lr
	bl sub_26C4
	subs r3, #0x40
	strb r3, [r1, #0xc]
	ldrb r3, [r1]
	movs r2, #0xc
	orrs r3, r2
	strb r3, [r1]
	bx r12

	UNALIGNED_THUMB_FUNC_START ply_port
ply_port: @ 0x0000284A
	mov r12, lr
	ldr r2, [r1, #0x40]
	ldrb r3, [r2]
	.2byte 0x1C52 @ adds r2, r2, #1
	ldr r0, _2860 @=REG_SOUND1CNT
	adds r0, r0, r3
	bl sub_26C6
	strb r3, [r0]
	bx r12
	.align 2, 0
_2860: .4byte REG_SOUND1CNT
