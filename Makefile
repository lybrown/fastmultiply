# $Id: Makefile 36 2008-06-29 23:46:07Z lybrown $

SHELL=bash

verif: exhaust.obx
	make -C lib6502-1.3
	load=$$(perl -ne 'print $$1 if /(\S+) LOAD/' exhaust.lab); \
	main=$$(perl -ne 'print $$1 if /(\S+) MAIN/' exhaust.lab); \
	echo LOAD: $$load MAIN: $$main; \
	time ./lib6502-1.3/verif.exe -l $$load exhaust.obx -R $$main -X 0 -d $$main +20

test.run:
test.obx: table.asm mult8x8.asm mult16x8.asm mult8x16.asm mult16x16.asm
exhaust.obx: table.asm mult8x8.asm mult16x8.asm mult8x16.asm mult16x16.asm


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
