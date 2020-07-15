//+build !noasm !appengine

// chunking_first_pass(buf []byte, separator uint64) (out uint64)
TEXT ·chunking_first_pass(SB), 7, $0

    MOVQ         buf+0(FP), DI
    MOVQ         separator+24(FP), AX // get separator
    MOVQ         AX, X6
    VPBROADCASTB X6, Y6
    MOVQ         $0x0a, AX // get new line
    MOVQ         AX, X7
    VPBROADCASTB X7, Y7

    MOVQ         $-1, R8
    MOVQ         $-1, R9
    XORQ         R10, R10

    VMOVDQU    (DI), Y8          // load low 32-bytes
    VMOVDQU    0x20(DI), Y9      // load high 32-bytes

loop:
    // find separator
    VPCMPEQB  Y8, Y6, Y10
    VPCMPEQB  Y9, Y6, Y11

    // find new line
    VPCMPEQB  Y8, Y7, Y12
    VPCMPEQB  Y9, Y7, Y13

    VPMOVMSKB Y12, AX
    VPMOVMSKB Y13, CX
    SHLQ      $32, CX
    ORQ       CX, AX
    POPCNTQ   AX, BX
    ADDQ      BX, R10

    VPMOVMSKB Y10, AX
    VPMOVMSKB Y11, CX
    SHLQ      $32, CX
    ORQ       CX, AX

    MOVQ      AX, out+32(FP)
    MOVQ      R8, positionDelimiterEven+40(FP)
    MOVQ      R9, positionDelimiterOdd+48(FP)
    MOVQ      R10, quotes+56(FP)
    VZEROUPPER
	RET


TEXT ·handle_masks(SB), 7, $0
	MOVQ    quoteMask+0(FP), AX
	BSFQ    AX, DX
	MOVQ    newlineMask+8(FP), BX
	BSFQ    BX, SI
	BSFQ    AX, DI
	MOVL    $0x40, DI
	CMOVQEQ DI, DX
	BSFQ    BX, R8
	CMOVQEQ DI, SI
	MOVQ    lastCharIsQuote+16(FP), R10
	MOVQ    quotes+24(FP), R11
	MOVQ    even+32(FP), R9
	MOVQ    odd+40(FP), R8

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
