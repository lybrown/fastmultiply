# $Id: Makefile 36 2008-06-29 23:46:07Z lybrown $

SHELL=bash

verif: exhaust.obx
	make -C lib6502-1.3
	time ./lib6502-1.3/verif.exe -l 27fa exhaust.obx -R 2a3c -X 0 -d 2a3c +20

test.run:
test.obx: table.asm fastmultiply.asm
exhaust.obx: table.asm fastmultiply.asm



atari = altirra

%.run: %.xex
	$(atari) $<

%.xex: %.obx
	cp $< $@

%.obx: %.asm
	xasm /t:$*.lab /l:$*.lst $<
	perl -pi -e 's/^n /  /' $*.lab

clean:
	rm -f *.{obx,lab,lst,xex,bak} *~

.PRECIOUS: %.obx %.xex %.asm
