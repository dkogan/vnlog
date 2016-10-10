PROJECT_NAME := asciilog

ABI_VERSION  := 1
TAIL_VERSION := 4

LIB_SOURCES := *.c*
BIN_SOURCES := test/test1.c

TOOLS   := asciilog-filter asciilog-gen-header asciilog-tailf asciilog-make-matrix
PERLMOD := Asciilog.pm

MAN1   := $(addprefix man1/,$(addsuffix .1,$(TOOLS)))
MAN3PM := $(addprefix man3/,$(addsuffix .3pm,$(PERLMOD)))

doc: $(MAN1) $(MAN3PM)
.PHONY: doc

%/:
	mkdir -p $@

man1/%.1: % | man1/
	pod2man -r '' --section 1 --center "asciilog" $< $@
man3/%.3pm: % | man3/
	pod2man -r '' --section 3pm --center "asciilog" $< $@
EXTRA_CLEAN += man1 man3

CCXXFLAGS := -I. -std=gnu99 -Wno-missing-field-initializers

test/test1: test/test2.o
test/test1.o: test/asciilog_fields_generated1.h
test/test2.o: test/asciilog_fields_generated2.h
test/asciilog_fields_generated%.h: test/asciilog%.defs asciilog-gen-header
	./asciilog-gen-header < $< | perl -pe 's{asciilog/asciilog.h}{asciilog.h}' > $@
EXTRA_CLEAN += test/asciilog_fields_generated*.h test/*.got


test check: all
	test/test_asciilog-filter.pl
	test/test_c_api.sh
	@echo "All tests passed!"
.PHONY: test check

DIST_INCLUDE := *.h
DIST_BIN     := $(TOOLS)

install: doc
DIST_MAN     := man1/ man3/

include /usr/include/mrbuild/Makefile.common
