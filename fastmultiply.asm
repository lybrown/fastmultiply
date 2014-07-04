; Translated to XASM by Xuel
; 16x8 and 8x16 versions by Xuel

;====== Seriously fast multiplication (8-bit and 16-bit) ======
;
;By Jackasser
;
;Without further explanation here's the code for really fast multiplications.
;They require 2k of tables which can be generated using
;[[table_generator_routine_for_fast_8_bit_mul_table]]. The article from
;C=Hacking 16 which is mentioned in the source is available
;[[magazines:chacking16#d_graphics_for_the_masseslib3d_and_cool_world|here]].
;
;Here are four routines, signed/unsigned 8/16-bit multiplication with 16/32-bit result:
;
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




; Description: Unsigned 16-bit multiplication with unsigned 32-bit result.
;
; Input: 16-bit unsigned value in T1
;        16-bit unsigned value in T2
;        Carry=0: Re-use T1 from previous multiplication (faster)
;        Carry=1: Set T1 (slower)
;
; Output: 32-bit unsigned value in PRODUCT
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
multiply_16bit_unsigned
                ; <T1 * <T2 = AAaa
                ; <T1 * >T2 = BBbb
                ; >T1 * <T2 = CCcc
                ; >T1 * >T2 = DDdd
                ;
                ;       AAaa
                ;     BBbb
                ;     CCcc
                ; + DDdd
                ; ----------
                ;   PRODUCT!

                ; Setup T1 if changed
                bcc m16u_setup_done
                    lda T1+0
                    sta sm1a+1
                    sta sm3a+1
                    sta sm5a+1
                    sta sm7a+1
                    eor #$ff
                    sta sm2a+1
                    sta sm4a+1
                    sta sm6a+1
                    sta sm8a+1
                    lda T1+1
                    sta sm1b+1
                    sta sm3b+1
                    sta sm5b+1
                    sta sm7b+1
                    eor #$ff
                    sta sm2b+1
                    sta sm4b+1
                    sta sm6b+1
                    sta sm8b+1
m16u_setup_done

                ; Perform <T1 * <T2 = AAaa
                ldx T2+0
                sec
sm1a            lda square1_lo,x
sm2a            sbc square2_lo,x
                sta PRODUCT+0
sm3a            lda square1_hi,x
sm4a            sbc square2_hi,x
                sta _AA+1

                ; Perform >T1_hi * <T2 = CCcc
                sec
sm1b            lda square1_lo,x
sm2b            sbc square2_lo,x
                sta _cc+1
sm3b            lda square1_hi,x
sm4b            sbc square2_hi,x
                sta _CCC+1

                ; Perform <T1 * >T2 = BBbb
                ldx T2+1
                sec
sm5a            lda square1_lo,x
sm6a            sbc square2_lo,x
                sta _bb+1
sm7a            lda square1_hi,x
sm8a            sbc square2_hi,x
                sta _BBB+1

                ; Perform >T1 * >T2 = DDdd
                sec
sm5b            lda square1_lo,x
sm6b            sbc square2_lo,x
                sta _dd+1
sm7b            lda square1_hi,x
sm8b            sbc square2_hi,x
                sta PRODUCT+3

                ; Add the separate multiplications together
                clc
_AA             lda #0
_bb             adc #0
                sta PRODUCT+1
_BBB            lda #0
_CCC            adc #0
                sta PRODUCT+2
                bcc m16u_carry1_done
                    inc PRODUCT+3
                    clc
m16u_carry1_done
_cc             lda #0
                adc PRODUCT+1
                sta PRODUCT+1
_dd             lda #0
                adc PRODUCT+2
                sta PRODUCT+2
                bcc m16u_carry2_done
                    inc PRODUCT+3
m16u_carry2_done

                rts

size_u16 equ *-multiply_16bit_unsigned



; Description: Signed 16-bit multiplication with signed 32-bit result.
;
; Input: 16-bit signed value in T1
;        16-bit signed value in T2
;        Carry=0: Re-use T1 from previous multiplication (faster)
;        Carry=1: Set T1 (slower)
;
; Output: 32-bit signed value in PRODUCT
;
; Clobbered: PRODUCT, X, A, C
multiply_16bit_signed
                jsr multiply_16bit_unsigned

                ; Apply sign (See C=Hacking16 for details).
                lda T1+1
                bpl m16s_signfix1_done
                    sec
                    lda PRODUCT+2
                    sbc T2+0
                    sta PRODUCT+2
                    lda PRODUCT+3
                    sbc T2+1
                    sta PRODUCT+3
m16s_signfix1_done
                lda T2+1
                bpl m16s_signfix2_done
                    sec
                    lda PRODUCT+2
                    sbc T1+0
                    sta PRODUCT+2
                    lda PRODUCT+3
                    sbc T1+1
                    sta PRODUCT+3
m16s_signfix2_done

                rts

size_s16 equ *-multiply_16bit_unsigned

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
