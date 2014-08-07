; Description: Unsigned 16-bit by 8-bit multiplication with unsigned 24-bit result.
;
; Input: 16-bit unsigned value in T1
;        8-bit unsigned value in T2
;        Carry=0: Re-use T1 from previous multiplication (faster)
;        Carry=1: Set T1 (slower)
;
; Output: 24-bit unsigned value in PRODUCT
;
; Clobbered: PRODUCT, X, A, C
multiply_16x8bit_unsigned
                ; <T1 * <T2 = AAaa
                ; >T1 * <T2 = CCcc
                ;
                ;       AAaa
                ; +   CCcc
                ; ----------
                ;   PRODUCT!

                ; Setup T1 if changed
                bcc m16x8u_setup_done
                    lda T1+0
                    sta sm1a16x8+1
                    sta sm3a16x8+1
                    eor #$ff
                    sta sm2a16x8+1
                    sta sm4a16x8+1
                    lda T1+1
                    sta sm1b16x8+1
                    sta sm3b16x8+1
                    eor #$ff
                    sta sm2b16x8+1
                    sta sm4b16x8+1
m16x8u_setup_done

                ; Perform <T1 * <T2 = AAaa
                ldx T2+0
                sec
sm1a16x8        lda square1_lo,x
sm2a16x8        sbc square2_lo,x
                sta PRODUCT+0
sm3a16x8        lda square1_hi,x
sm4a16x8        sbc square2_hi,x
                sta _AA16x8+1

                ; Perform >T1_hi * <T2 = CCcc
                sec
sm1b16x8        lda square1_lo,x
sm2b16x8        sbc square2_lo,x
                sta _cc16x8+1
sm3b16x8        lda square1_hi,x
sm4b16x8        sbc square2_hi,x
                sta PRODUCT+2

                ; Add the separate multiplications together
                clc
_AA16x8         lda #0
_cc16x8         adc #0
                sta PRODUCT+1
                scc:inc PRODUCT+2

                rts

size_u16x8 equ *-multiply_16x8bit_unsigned

;http://www.ffd2.com/fridge/chacking/c=hacking16.txt
;---------------------------------------------------
;	Say we multiply two numbers x and y together, and x is negative.
;If we plug it in to a multiplication routine (_any_ multiplication
;routine), we will really be calculating
;
;	(2^N + x)*y = 2^N*y + x*y
;
;assuming that x is represented using 2's complement (N would be 8 or 16
;or whatever).  There are two observations:
;
;	- If the result is _less_ than 2^N, we are done -- 2^N*y is all
;	  in the higher bytes which we don't care about.
;
;	- Otherwise, subtract 2^N*y from the result, i.e. subtract
;	  y from the high bytes.
;
;Now let's say that both x and y are negative.  Then on the computer
;the number we will get is
;
;	(2^N + x)*(2^N + y) = 2^(2N) + 2^N*x + 2^N*y - x*y
;
;Now it is too large by a factor of 2^2N, 2^N*x and 2^N*y.  BUT
;the basic observations haven't changed a bit!  We still need to
;_subtract_ x and y from the high bytes.  And the 2^2N is totally
;irrelevant -- we can't get numbers that large by multiplying numbers
;together which are no larger than 2^N.
;	This leads to the following algorithm for doing signed
;multiplications:
;
;	multiply x and y as normal with some routine
;	if x<0 then subtract y from the high bytes of the result
;	if y<0 then subtract x from the high bytes
;---------------------------------------------------
; For 16x8:
;      (2^16 + T1)*(2^8 + T2) = 2^24 + 2^8*T2 + 2^16*T1 + x*y
; Therefore:
;      Subtract T1 from PRODUCT+1 and PRODUCT+2
;      Subtract T2 from PRODUCT+2
;

; Description: Signed 16-bit by 8-bit multiplication with signed 24-bit result.
;
; Input: 16-bit signed value in T1
;        8-bit signed value in T2
;        Carry=0: Re-use T1 from previous multiplication (faster)
;        Carry=1: Set T1 (slower)
;
; Output: 24-bit signed value in PRODUCT
;
; Clobbered: PRODUCT, X, A, C
multiply_16x8bit_signed
                jsr multiply_16x8bit_unsigned

                ; Apply sign (See C=Hacking16 for details).
                lda T1+1
                bpl m16x8s_signfix1_done
                    sec
                    lda PRODUCT+2
                    sbc T2+0
                    sta PRODUCT+2
m16x8s_signfix1_done
                lda T2
                bpl m16x8s_signfix2_done
                    sec
                    lda PRODUCT+1
                    sbc T1+0
                    sta PRODUCT+1
                    lda PRODUCT+2
                    sbc T1+1
                    sta PRODUCT+2
m16x8s_signfix2_done

                rts
size_s16x8 equ *-multiply_16x8bit_unsigned


multiply_s16u8
                jsr multiply_16x8bit_unsigned

                ; Apply sign (See C=Hacking16 for details).
                lda T1+1
                bpl ms16u8_signfix1_done
                    sec
                    lda PRODUCT+2
                    sbc T2+0
                    sta PRODUCT+2
ms16u8_signfix1_done

                rts
size_s16u8 equ *-multiply_s16u8
