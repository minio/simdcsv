//+build !noasm !appengine

// stages_combined_buffer(buf []byte, separatorChar uint64, input1 *stage1Input, output1 *stage1Output, postProc *[]uint64, offset uint64, input2 *Input, output2 *OutputAsm, lastCharIsDelimiter uint64, rows []uint64, columns []string) (processed uint64)
TEXT ·stages_combined_buffer(SB), 7, $0
    RET
