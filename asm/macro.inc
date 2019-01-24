.MACRO ARM_FUNC_START name
	.ALIGN 2, 0
	.GLOBAL \name
	.ARM
	.TYPE \name, function
	.SYNTAX divided
.ENDM

.MACRO ARM_FUNC_END name
	.SIZE \name, .-\name
.ENDM


.MACRO THUMB_FUNC_START name
	.ALIGN 2, 0
	.GLOBAL \name
	.THUMB
	.THUMB_FUNC
	.TYPE \name, function
	.SYNTAX unified
.ENDM


.MACRO THUMB_FUNC_END name
	.SIZE \name, .-\name
.ENDM


.MACRO UNALIGNED_THUMB_FUNC_START name
	.GLOBAL \name
	.THUMB
	.THUMB_FUNC
	.TYPE \name, function
	.SYNTAX unified
.ENDM


@ Generates a glue function to be used when calling
@ the specified ARM function from THUMB code.
.MACRO THUMB_INTERWORK_VENEER name
	.SECTION .glue_7t
	.GLOBAL \name\()_t
	.THUMB
	.ALIGN 2, 0
	\name\()_t:
	bx pc			@ Use a bx instruction to switch into ARM mode. The value of PC is
	.ALIGN 2, 0		@ 4 bytes ahead of the current instruction, so we pad with a nop.
	.ARM
	b \name			@ Now in ARM mode, jump to the actual function
	.SECTION .text
.ENDM
