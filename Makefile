# $Id: Makefile 36 2008-06-29 23:46:07Z lybrown $

test.run:
test.obx: table.asm fastmultiply.asm

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
