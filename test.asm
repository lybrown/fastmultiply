    org $80
T1 org *+2
T2 org *+2
PRODUCT org *+4
    org *+8
result1 org *+4
result2 org *+4
result3 org *+4
result4 org *+4

    org $2000
    icl 'table.asm'
    icl 'fastmultiply.asm'
main
    jsr generate_square_tables
    mwa #$1234 T1
    mwa #$ABCD T2
    sec
    jsr multiply_16bit_unsigned
    mwa PRODUCT result1
    mwa PRODUCT+2 result1+2
    ; result1 should be $0C374FA4
    mwa #$1234 T1
    mwa #$ABCD T2
    sec
    jsr multiply_16bit_signed
    mwa PRODUCT result2
    mwa PRODUCT+2 result2+2
    ; result2 should be $FA034FA4
    mwa #$1234 T1
    mwa #$ABCD T2
    sec
    jsr multiply_16x8bit_signed
    mwa PRODUCT result3
    mwa PRODUCT+2 result3+2
    ; result3 should be $FFFC5FA4
    mwa #$1234 T1
    mwa #$ABCD T2
    sec
    jsr multiply_8x16bit_signed
    mwa PRODUCT result4
    mwa PRODUCT+2 result4+2
    ; result4 should be $FFEEE5A4
    brk
    run main
