@ This file was created from a .asm file
@  using the ads2gas.pl script.
	.equ DO1STROUNDING, 0
@ created by newstarchen

    .global xx_sad_16x16_neon 
	.type xx_sad_16x16_neon, function
    .global xx_image_sharpen_neon 
	.type xx_image_sharpen_neon, function
    .global xx_pst_filter_plane_neon 
	.type xx_pst_filter_plane_neon, function
   @ ARM
   @ 
   @ PRESERVE8

.text
.p2align 2

.macro SAD_16x2_NEON
    vld1.8 {q0}, [r0], r1
    vld1.8 {q1}, [r4], r1
    vld1.8 {q2}, [r2], r3
    vld1.8 {q3}, [r5], r3

    vabal.u8 q4, d0, d4
    vabal.u8 q5, d1, d5
    vabal.u8 q6, d2, d6
    vabal.u8 q7, d3, d7
.endm

@ void xx_sad_16x16_neon( uint8_t * cur, int cur_stride, uint8_t * ref, int ref_stride )

@ r0 cur
@ r1 cur_stride
@ r2 ref
@ r3 ref_stride

_xx_sad_16x16_neon:
	xx_sad_16x16_neon: @ PROC
    push            {r4 - r5, lr}

	@ r0 = cur_line0
	@ r2 = ref_line0
	add r4, r0, r1  @ r4 = cur_line1
	add r5, r2, r3  @ r5 = ref_line1

	add r1, r1  @ r1 = 2 * cur_stride
	add r3, r3  @ r3 = 2 * ref_stride

	veor q4, q4
	veor q5, q5
	veor q6, q6
	veor q7, q7

    SAD_16x2_NEON
    SAD_16x2_NEON
    SAD_16x2_NEON
    SAD_16x2_NEON

    SAD_16x2_NEON
    SAD_16x2_NEON
    SAD_16x2_NEON
    SAD_16x2_NEON

    vadd.u16 q4, q5
    vadd.u16 q6, q7
    vadd.u16 q4, q6

    vadd.u16    d8, d8, d9
    vpadd.u16   d0, d8, d8
    vpaddl.u16  d0, d0
    vmov.u32    r0, d0[0]

    pop             {r4 - r5, pc}

	.size xx_sad_16x16_neon, .-xx_sad_16x16_neon    @ ENDP


@void xx_image_sharpen_c( uint8_t *dst, uint8_t *src, int width, int height )

@ r0 dst
@ r1 src
@ r2 width
@ r3 height

_xx_image_sharpen_neon:
	xx_image_sharpen_neon: @ PROC
    push            {r4 - r12, lr}

@    ldr             r4, [sp, #40]           @load parameters from stack
@    ldr             r5, [sp, #44]           @load parameters from stack


	//  0 -1  0
	// -1  5 -1
	//  0 -1  0

@	int t = src0[i] * 5 - (src1[i] + src2[i] + src0[i-1] + src0[i+1])@

	vmov.u8 d5, #5

	mov r8, r3
LABEL_SHARPEN_Y:

	mov r4, r0      @ r4 = dst_line+0
	sub r5, r1, r2  @ r5 = src_line-1
	mov r6, r1      @ r6 = src_line+0
	add r7, r1, r2  @ r7 = src_line+1

	mov r9, r2
LABEL_SHARPEN_X:
    vld1.8 {d0}, [r5]!      @ line-1[i+0]
    vld1.8 {d1}, [r6, #-1]  @ line-0[i-1]
    vld1.8 {d2}, [r6, #+1]  @ line-0[i+1]
    vld1.8 {d3}, [r7]!      @ line+1[i+0]

    vld1.8 {d4}, [r6]!      @ line0[i+0]

    vaddl.u8 q0, d0, d1
    vaddl.u8 q1, d2, d3

    vmull.u8 q3, d4, d5

    vsub.s16 q3, q0
    vsub.s16 q3, q1

    vqmovun.s16 d4, q3
    vst1.8 {d4}, [r4]!

    subs r9, #8
    bgt LABEL_SHARPEN_X

    @vpop            {d8 - d15}
    pop             {r4 - r12, pc}

    bgt LABEL_SHARPEN_Y

	mov r0, r10

    @vpop            {d8 - d15}
    pop             {r4 - r12, pc}

	.size xx_image_sharpen_neon, .-xx_image_sharpen_neon    @ ENDP




@static int xx_pst_filter_plane_c(uint8_t * dst, int dst_stride, uint8_t * src, int src_stride, int width, int height)
_xx_pst_filter_plane_neon:
	xx_pst_filter_plane_neon: @ PROC
    push  {r4 - r12, lr}@ push r4 r5

	@ r0 = dst
	@ r1 = dst_stride
	@ r2 = src
	@ r3 = src_stride
	@ r4 = width stack
	@ r5 = height stack

    ldr             r4, [sp, #40]           @load parameters from stack width
    ldr             r5, [sp, #44]           @load parameters from stack height

LABEL_FILTER_YY:
	sub r6, r2, r3
	sub r5, r6, #1
	add r7, r6, #1

	sub r8, r2, #1
	add r9, r2, #1

	add r11, r2, r3
	sub r10, r11, #1
	add r12, r11, #1

LABEL_FILTER_XX:

	vld1.8 {d0}, [r5]!
	vld1.8 {d1}, [r7]!
	vld1.8 {d2}, [r10]!
	vld1.8 {d3}, [r12]!

	vld1.8 {d4}, [r6]!
	vld1.8 {d5}, [r8]!
	vld1.8 {d6}, [r9]!
	vld1.8 {d7}, [r11]!

	vld1.8 {d8}, [r2]!

	vaddl.u8 q0, d0, d1
	vaddl.u8 q1, d2, d3
	vaddl.u8 q2, d4, d5
	vaddl.u8 q3, d6, d7

	vadd.s16 q0, q0, q1
	vadd.s16 q2, q2, q3
	vshl.s16 q2, q2, #2

	vshll.u8 q5, d8, #2
	vshll.u8 q4, d8, #1

	vadd.s16 q0, q0, q2
	vsub.s16 q0, q0, q5
	vmov.s16 q2, #8
	vadd.s16 q0, q0, q2
	vshr.s16 q0, q0, #4

	@vqsubun.s16 d8, q4, q0
	vsub.s16 q4, q4, q0
	vqmovun.s16 d8, q4

    vst1.u8 {d8}, [r0]!      @ dst

    @vmov.u32    r0, d0[0]

    subs r4, #8
    bgt LABEL_FILTER_XX

    ldr             r4, [sp, #40]           @load parameters from stack width
    ldr             r5, [sp, #44]           @load parameters from stack height

	sub r0, r0, r4
	sub r2, r2, r4
	add r0, r0, r1
	add r2, r2, r3

    subs r5, #1
    str  r5, [sp, #44]
    bgt LABEL_FILTER_YY

    pop  {r4 - r12, pc}

	.size xx_pst_filter_plane_neon, .-xx_pst_filter_plane_neon    @ ENDP




@static int xx_pst_filter_plane_c(uint8_t * dst, int dst_stride, uint8_t * src, int src_stride, int width, int height)
_xx_pst_filter_plane_neon00:
	xx_pst_filter_plane_neon00: @ PROC
    push            {r4 - r11, lr}@ push r4 r5

	@ r0 = dst
	@ r1 = dst_stride
	@ r2 = src
	@ r3 = src_stride
	@ r4 = width stack
	@ r5 = height stack

    ldr             r4, [sp, #36]           @load parameters from stack width
    ldr             r5, [sp, #40]           @load parameters from stack height


LABEL_FILTER_YYY:
	mov r8, r4
	mov r6, r2
	mov r7, r0


	sub r10, r2, r3  @ r10 = src_line-1
	add r11, r2, r3  @ r11 = src_line+1

LABEL_FILTER_XXX:

	vld1.8 {d0}, [r10, #-1]
	vld1.8 {d1}, [r10, #1]
	vld1.8 {d2}, [r11, #-1]
	vld1.8 {d3}, [r11, #1]

	vld1.8 {d4}, [r10]!
	vld1.8 {d5}, [r6, #-1]
	vld1.8 {d6}, [r6, #1]
	vld1.8 {d7}, [r11]!

	vld1.8 {d8}, [r6]!

    vst1.8 {d5}, [r7]!      @ dst
    vst1.8 {d8}, [r7]!      @ dst
    vst1.8 {d6}, [r7]!      @ dst
    pop             {r4 - r11, pc}

	vaddl.u8 q0, d0, d1
	vaddl.u8 q1, d2, d3
	vaddl.u8 q2, d4, d5
	vaddl.u8 q3, d6, d7

	vadd.s16 q0, q0, q1
	vadd.s16 q2, q2, q3
	vshl.s16 q2, q2, #2

	vshll.u8 q5, d8, #2
	vshll.u8 q4, d8, #1

	vadd.s16 q0, q0, q2
	vsub.s16 q0, q0, q5
	@vmov.s16 q2, #8
	@vadd.s16 q0, q0, q2
	vshr.s16 q0, q0, #4

	@vqsubun.s16 d8, q4, q0
	vsub.s16 q4, q4, q0
	vqmovun.s16 d8, q4



    vst1.u8 {d8}, [r7]!      @ dst

    @vmov.u32    r0, d0[0]


    subs r8, #8
    bgt LABEL_FILTER_XXX

	add r2, r2, r3
	add r0, r0, r1
    subs r5, #1
    bgt LABEL_FILTER_YYY

    pop             {r4 - r11, pc}

	.size xx_pst_filter_plane_neon00, .-xx_pst_filter_plane_neon00    @ ENDP




@static int xx_pst_filter_plane_c(uint8_t * dst, int dst_stride, uint8_t * src, int src_stride, int width, int height)
_xx_pst_filter_plane_neon__:
	xx_pst_filter_plane_neon__: @ PROC
    push            {r4 - r10, lr}@ push r4 r5

	@ r0 = dst
	@ r1 = dst_stride
	@ r2 = src
	@ r3 = src_stride
	@ r4 = width stack
	@ r5 = height stack

    ldr             r4, [sp, #32]           @load parameters from stack width
    ldr             r5, [sp, #36]           @load parameters from stack height

	mov r10, r5

	@mov r6, r2
	@mov r7, r0


LABEL_FILTER_Y:
	mov r9, r4
	@sub r6, r2, r3@ r6 = src - src_stride
	@sub r6, r6, #1@ r6 = src - src_stride - 1
	@sub r7, r2, #1@ r7 = src -1
	@add r8, r2, r3@ r8 = src + src_stride
	@sub r8, r8, #1@ r8 = src + src_stride - 1
	@add r6, r6, r3
	@add r7, r7, r1


	mov r6, r2
	mov r7, r0

LABEL_FILTER_X:

     vld1.8 {d0}, [r6]!      @ src

     vst1.8 {d0}, [r7]!      @ dst

    @vmov.u32    r0, d0[0]


    subs r9, #8
    bgt LABEL_FILTER_X

	add r2, r2, r3
	add r0, r0, r1
    subs r10, #1
    bgt LABEL_FILTER_Y

    pop             {r4 - r10, pc}

	.size xx_pst_filter_plane_neon__, .-xx_pst_filter_plane_neon__    @ ENDP




_xx_pst_filter_plane_neon____:
	xx_pst_filter_plane_neon____: @ PROC
    push            {r4 - r11, lr}@ push r4 r5

	@ r0 = dst
	@ r1 = dst_stride
	@ r2 = src
	@ r3 = src_stride
	@ r4 = width stack
	@ r5 = height stack

    ldr             r4, [sp, #36]           @load parameters from stack width
    ldr             r5, [sp, #40]           @load parameters from stack height

    sub r10, r2, r3  @ r10 = src_line-1
	add r11, r2, r3  @ r11 = src_line+1


	vld1.8 {d0}, [r10, #-1]
	vld1.8 {d1}, [r10, #+1]
	vld1.8 {d2}, [r11, #-1]
	vld1.8 {d3}, [r11, #+1]

	vld1.8 {d4}, [r10]!
	vld1.8 {d5}, [r6, #-1]
	vld1.8 {d6}, [r6, #+1]
	vld1.8 {d7}, [r11]!

	vld1.8 {d8}, [r6]!

	vmov.u32 r0, d1[0]




    @vst1.u8 {d8}, [r7]!      @ dst


    @vmov.u32    r0, d0[0]




    pop             {r4 - r11, pc}

	.size xx_pst_filter_plane_neon____, .-xx_pst_filter_plane_neon____    @ ENDP
	.section	.note.GNU-stack,"",%progbits
