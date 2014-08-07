; Description: Unsigned 8-bit by 16-bit multiplication with unsigned 24-bit result.
;
; Input: 8-bit unsigned value in T1
;        16-bit unsigned value in T2
;        Carry=0: Re-use T1 from previous multiplication (faster)
;        Carry=1: Set T1 (slower)
;
; Output: 24-bit unsigned value in PRODUCT
;
; Clobbered: PRODUCT, X, A, C
multiply_8x16bit_unsigned
                ; <T1 * <T2 = AAaa
                ; <T1 * >T2 = BBbb
                ;
                ;       AAaa
                ; +   BBbb
                ; ----------
                ;   PRODUCT!

                ; Setup T1 if changed
                bcc m8x16u_setup_done
                    lda T1+0
                    sta sm1a8x16+1
                    sta sm3a8x16+1
                    sta sm5a8x16+1
                    sta sm7a8x16+1
                    eor #$ff
                    sta sm2a8x16+1
                    sta sm4a8x16+1
                    sta sm6a8x16+1
                    sta sm8a8x16+1
m8x16u_setup_done

                ; Perform <T1 * <T2 = AAaa
                ldx T2+0
                sec
sm1a8x16        lda square1_lo,x
sm2a8x16        sbc square2_lo,x
                sta PRODUCT+0
sm3a8x16        lda square1_hi,x
sm4a8x16        sbc square2_hi,x
                sta _AA8x16+1

                ; Perform <T1 * >T2 = BBbb
                ldx T2+1
                sec
sm5a8x16        lda square1_lo,x
sm6a8x16        sbc square2_lo,x
                sta _bb8x16+1
sm7a8x16        lda square1_hi,x
sm8a8x16        sbc square2_hi,x
                sta PRODUCT+2

                ; Add the separate multiplications together
                clc
_AA8x16         lda #0
_bb8x16         adc #0
                sta PRODUCT+1
                scc:inc PRODUCT+2

                rts
size_u8x16 equ *-multiply_8x16bit_unsigned

; Description: Signed 8-bit by 16-bit multiplication with signed 24-bit result.
;
; Input: 8-bit signed value in T1
;        16-bit signed value in T2
;        Carry=0: Re-use T1 from previous multiplication (faster)
;        Carry=1: Set T1 (slower)
;
; Output: 24-bit signed value in PRODUCT
;
; Clobbered: PRODUCT, X, A, C
multiply_8x16bit_signed
                jsr multiply_8x16bit_unsigned

                ; Apply sign (See C=Hacking16 for details).
                lda T1
                bpl m8x16s_signfix1_done
                    sec
                    lda PRODUCT+1
                    sbc T2+0
                    sta PRODUCT+1
                    lda PRODUCT+2
                    sbc T2+1
                    sta PRODUCT+2
m8x16s_signfix1_done
                lda T2+1
                bpl m8x16s_signfix2_done
                    sec
                    lda PRODUCT+2
                    sbc T1+0
                    sta PRODUCT+2
m8x16s_signfix2_done

                rts

size_s8x16 equ *-multiply_8x16bit_unsigned
