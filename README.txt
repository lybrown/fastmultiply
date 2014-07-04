These are signed and unsigned 16x8 and 8x16 multiplication routines based on
the "Seriously fast multiplication" 16x16 routines by Jackasser/Instict.

  http://codebase64.org/doku.php?id=base:seriously_fast_multiplication

lib6502-1.3/verif.c is a program to verify all 16 millions inputs to each
signed routine. It uses Ian Piumarta's lib6502 library:

  http://www.piumarta.com/software/lib6502/

test.asm just tests a few inputs and puts the results at $90, $94, etc. It ends
with a BRK instruction so that you can break into your emulator's debugger and
look at memory at $90 to verify the results. The code has comments that say
what the results should be.
