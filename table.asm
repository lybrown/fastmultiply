      ; 2K of tables - must be aligned to page boundary
      ert <* != 0
square1_lo org *+512
square1_hi org *+512
square2_lo org *+512
square2_hi org *+512
generate_square_tables
      ; generate f(x)=int(x*x/4)
      ldx #$00
      txa
      dta $c9
lb1   tya
      adc #$00
ml1   sta square1_hi,x
      tay
      cmp #$40
      txa
      ror @
ml9   adc #$00
      sta ml9+1
      inx
ml0   sta square1_lo,x
      bne lb1
      inc ml0+2
      inc ml1+2
      clc
      iny
      bne lb1
      ; generate f(x)=int((x-255)*(x-255)/4)
      ldx #$00
      ldy #$ff
ml2   lda square1_hi+1,x
      sta square2_hi+$100,x
      lda square1_hi,x
      sta square2_hi,y
      lda square1_lo+1,x
      sta square2_lo+$100,x
      lda square1_lo,x
      sta square2_lo,y
      dey
      inx
      bne ml2
      rts
