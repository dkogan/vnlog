PROJECT_NAME := asciilog

ABI_VERSION  := 0
TAIL_VERSION := 1

LIB_SOURCES := *.c*
BIN_SOURCES := test/test.c

TOOLS := asciilog-filter asciilog-gen-header
doc: $(addprefix man1/,$(addsuffix .1,$(TOOLS)))
.PHONY: doc

%/:
	mkdir -p $@

man1/%.1: % | man1/
	pod2man -r '' --section 1 --center "asciilog" $< $@
EXTRA_CLEAN += man1

CCXXFLAGS := -I.

DIST_INCLUDE := *.h
DIST_BIN     := $(TOOLS)

install: doc
DIST_MAN     := man1/

include /usr/include/mrbuild/Makefile.common
