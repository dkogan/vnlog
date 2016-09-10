PROJECT_NAME := asciilog

ABI_VERSION  := 1
TAIL_VERSION := 2

LIB_SOURCES := *.c*
BIN_SOURCES := test/test.c

TOOLS := asciilog-filter asciilog-gen-header asciilog-tailf
doc: $(addprefix man1/,$(addsuffix .1,$(TOOLS)))
.PHONY: doc

%/:
	mkdir -p $@

man1/%.1: % | man1/
	pod2man -r '' --section 1 --center "asciilog" $< $@
EXTRA_CLEAN += man1

CCXXFLAGS := -I. -std=gnu99

test/test.o: test/asciilog_fields_generated.h
test/asciilog_fields_generated.h: Makefile asciilog-gen-header
	./asciilog-gen-header 'int w' 'uint8_t x' 'char* y' 'double z' | perl -pe 's{asciilog/asciilog.h}{asciilog.h}' > $@
EXTRA_CLEAN += test/asciilog_fields_generated.h test/test.got


check: all
	test/test_asciilog-filter.pl
	test/test > test/test.got
	diff test/test.want test/test.got

DIST_INCLUDE := *.h
DIST_BIN     := $(TOOLS)

install: doc
DIST_MAN     := man1/

include /usr/include/mrbuild/Makefile.common
