; Description: Unsigned 8-bit multiplication with unsigned 16-bit result.
;
; Input: 8-bit unsigned value in T1
;        8-bit unsigned value in T2
;        Carry=0: Re-use T1 from previous multiplication (faster)
;        Carry=1: Set T1 (slower)
;
; Output: 16-bit unsigned value in PRODUCT
;
; Clobbered: PRODUCT, X, A, C
;
; Allocation setup: T1,T2 and PRODUCT preferably on Zero-page.
;                   square1_lo, square1_hi, square2_lo, square2_hi must be
;                   page aligned. Each table are 512 bytes. Total 2kb.
;
; Table generation: I:0..511
;                   square1_lo = <((I*I)/4)
;                   square1_hi = >((I*I)/4)
;                   square2_lo = <(((I-255)*(I-255))/4)
;                   square2_hi = >(((I-255)*(I-255))/4)
multiply_8bit_unsigned
                bcc m8u_setup_done
                    lda T1
                    sta sm1+1
                    sta sm3+1
                    eor #$ff
                    sta sm2+1
                    sta sm4+1
m8u_setup_done

                ldx T2
                sec
sm1             lda square1_lo,x
sm2             sbc square2_lo,x
                sta PRODUCT+0
sm3             lda square1_hi,x
sm4             sbc square2_hi,x
                sta PRODUCT+1

                rts

; Description: Signed 8-bit multiplication with signed 16-bit result.
;
; Input: 8-bit signed value in T1
;        8-bit signed value in T2
;        Carry=0: Re-use T1 from previous multiplication (faster)
;        Carry=1: Set T1 (slower)
;
; Output: 16-bit signed value in PRODUCT
;
; Clobbered: PRODUCT, X, A, C
multiply_8bit_signed
                jsr multiply_8bit_unsigned

                ; Apply sign (See C=Hacking16 for details).
                lda T1
                bpl m8s_signfix1_done
                    sec
                    lda PRODUCT+1
                    sbc T2
                    sta PRODUCT+1
m8s_signfix1_done
                lda T2
                bpl m8s_signfix2_done
                    sec
                    lda PRODUCT+1
                    sbc T1
                    sta PRODUCT+1
m8s_signfix2_done

                rts
