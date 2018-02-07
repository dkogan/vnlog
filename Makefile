PROJECT_NAME := vanillog

ABI_VERSION  := 4
TAIL_VERSION := 1.9

LIB_SOURCES := *.c*
BIN_SOURCES := test/test1.c

TOOLS :=					\
  vnl-filter					\
  vnl-gen-header				\
  vnl-tail					\
  vnl-make-matrix				\
  vnl-align					\
  vnl-join					\
  vnl-sort



b64_cencode.o: CFLAGS += -Wno-implicit-fallthrough

# Make can't deal with ':' in filenames, so I hack it
coloncolon := __colon____colon__
doc: $(addprefix man1/,$(addsuffix .1,$(TOOLS)))  $(patsubst lib/Vanillog/%.pm,man3/Vanillog$(coloncolon)%.3pm,$(wildcard lib/Vanillog/*.pm))
.PHONY: doc

%/:
	mkdir -p $@

man1/%.1: % | man1/
	pod2man -r '' --section 1 --center "vanillog" $< $@
man3/Vanillog$(coloncolon)%.3pm: lib/Vanillog/%.pm | man3/
	pod2man -r '' --section 3pm --center "vanillog" $< $@
EXTRA_CLEAN += man1 man3

CCXXFLAGS := -I. -std=gnu99 -Wno-missing-field-initializers

test/test1: test/test2.o
test/test1.o: test/vanillog_fields_generated1.h
test/test2.o: test/vanillog_fields_generated2.h
test/vanillog_fields_generated%.h: test/vanillog%.defs vnl-gen-header
	./vnl-gen-header < $< | perl -pe 's{vanillog/vanillog.h}{vanillog.h}' > $@
EXTRA_CLEAN += test/vanillog_fields_generated*.h test/*.got

test check: all
	test/test_vnl-filter.pl
	test/test_vnl-sort.pl
	test/test_vnl-join.pl
	test/test_c_api.sh
	@echo "All tests passed!"
.PHONY: test check

DIST_INCLUDE      := *.h
DIST_BIN          := $(TOOLS)
DIST_PERL_MODULES := lib/Vanillog

install: doc
DIST_MAN     := man1/ man3/

include /usr/include/mrbuild/Makefile.common
