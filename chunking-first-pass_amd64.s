//+build !noasm !appengine

// func chunking_first_pass(buf []byte, quoteChar, delimiterChar uint64, quotes *uint64, even, odd *int)
TEXT ·chunking_first_pass(SB), 7, $0

	MOVQ         buf+0(FP), DI
	MOVQ         quoteChar+24(FP), AX     // get character for quote
	MOVQ         AX, X6
	VPBROADCASTB X6, Y6
	MOVQ         delimiterChar+32(FP), AX // get character for delimiter
	MOVQ         AX, X7
	VPBROADCASTB X7, Y7

	MOVQ quotes+40(FP), R11
	MOVQ even+48(FP), R9
	MOVQ odd+56(FP), R8

	XORQ DX, DX

loop:
	VMOVDQU (DI)(DX*1), Y8     // load low 32-bytes
	VMOVDQU 0x20(DI)(DX*1), Y9 // load high 32-bytes

	// detect quotes
	VPCMPEQB Y8, Y6, Y10
	VPCMPEQB Y9, Y6, Y11

	// find new line delimiter
	VPCMPEQB Y8, Y7, Y12
	VPCMPEQB Y9, Y7, Y13

	VPMOVMSKB Y12, BX
	VPMOVMSKB Y13, CX
	SHLQ      $32, CX
	ORQ       CX, BX

	VPMOVMSKB Y10, AX
	VPMOVMSKB Y11, CX
	SHLQ      $32, CX
	ORQ       CX, AX

	// TODO: Determine status of next char
	MOVQ $0, R10

	// Cache even and odd positions
	MOVQ (R8), R14
	MOVQ (R9), R15

	PUSHQ DI
	PUSHQ DX
	CALL  ·handle_masks(SB)
	POPQ  DX
	POPQ  DI

	// Check if even has changed, add base upon initial change
	CMPQ R15, $-1
	JNZ  skipEven
	CMPQ (R9), R15
	JZ   skipEven
	ADDQ DX, (R9)

skipEven:

	// Check if odd has changed, add base upon initial change
	CMPQ R14, $-1
	JNZ  skipOdd
	CMPQ (R8), R14
	JZ   skipOdd
	ADDQ DX, (R8)

skipOdd:

	ADDQ $0x40, DX
	CMPQ DX, buf_len+8(FP)
	JLT  loop

	VZEROUPPER
	RET

//
TEXT ·handle_masks_test(SB), 7, $0
	MOVQ quoteMask+0(FP), AX
	MOVQ newlineMask+8(FP), BX
	MOVQ lastCharIsQuote+16(FP), R10
	MOVQ quotes+24(FP), R11
	MOVQ even+32(FP), R9
	MOVQ odd+40(FP), R8
	CALL ·handle_masks(SB)
	RET

//
TEXT ·handle_masks(SB), 7, $0
	BSFQ    AX, DX
	BSFQ    BX, SI
	BSFQ    AX, DI
	MOVL    $0x40, DI
	CMOVQEQ DI, DX
	BSFQ    BX, R12
	CMOVQEQ DI, SI

loop:
	CMPQ  DX, SI
	JGE   label1
	CMPQ  DX, $0x3f
	JNE   label2
	TESTQ R10, R10
	JE    label2

label6:
	LEAQ 0x1(DX), CX
	CMPQ CX, $0x40
	SBBQ DX, DX
	MOVQ $-0x2, R12
	SHLQ CL, R12
	ANDQ DX, R12
	ANDQ R12, AX

label3:
	BSFQ    AX, DX
	CMOVQEQ DI, DX
	JMP     loop

label2:
	LEAQ  0x1(DX), CX
	CMPQ  CX, $0x40
	SBBQ  R12, R12
	MOVL  $0x1, R13
	SHLQ  CL, R13
	ANDQ  R12, R13
	TESTQ R13, AX
	JNE   label6
	INCQ  (R11)
	CMPQ  DX, $0x40
	SBBQ  R12, R12
	MOVQ  DX, CX
	MOVQ  $-0x2, R13
	SHLQ  CL, R13
	ANDQ  R12, R13
	ANDQ  R13, AX
	JMP   label3

label1:
	CMPQ SI, $0x40
	JE   done
	MOVQ (R11), R12
	BTL  $0x0, R12
	JB   label4
	CMPQ 0(R9), $-0x1
	JNE  label5
	MOVQ SI, 0(R9)

label5:
	CMPQ    SI, $0x40
	SBBQ    R12, R12
	MOVQ    SI, CX
	MOVQ    $-0x2, R13
	SHLQ    CL, R13
	ANDQ    R12, R13
	ANDQ    R13, BX
	BSFQ    BX, R12
	CMOVQEQ DI, R12
	MOVQ    R12, SI
	JMP     loop

label4:
	CMPQ 0(R8), $-0x1
	JNE  label5
	MOVQ SI, 0(R8)
	JMP  label5

done:
	RET