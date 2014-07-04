    org $80
T1 org *+2
T2 org *+2
PRODUCT org *+4
    org *+8
result1 org *+4
result2 org *+4
result3 org *+4
result4 org *+4
result5 org *+4

    org $2000
    icl 'table.asm'
    icl 'fastmultiply.asm'
main
    jsr generate_square_tables
exhaust1
    sec
    jsr multiply_16x8bit_signed
    jsr $8000 ; call verification callback in lib6502
    bcs exhaust1
exhaust2
    sec
    jsr multiply_8x16bit_signed
    jsr $8001 ; call verification callback in lib6502
    bcs exhaust2
    brk
    run main
