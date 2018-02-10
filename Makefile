PROJECT_NAME := vnlog

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
doc: $(addprefix man1/,$(addsuffix .1,$(TOOLS)))  $(patsubst lib/Vnlog/%.pm,man3/Vnlog$(coloncolon)%.3pm,$(wildcard lib/Vnlog/*.pm))
.PHONY: doc

%/:
	mkdir -p $@

man1/%.1: % | man1/
	pod2man -r '' --section 1 --center "vnlog" $< $@
man3/Vnlog$(coloncolon)%.3pm: lib/Vnlog/%.pm | man3/
	pod2man -r '' --section 3pm --center "vnlog" $< $@
EXTRA_CLEAN += man1 man3

CCXXFLAGS := -I. -std=gnu99 -Wno-missing-field-initializers

test/test1: test/test2.o
test/test1.o: test/vnlog_fields_generated1.h
test/test2.o: test/vnlog_fields_generated2.h
test/vnlog_fields_generated%.h: test/vnlog%.defs vnl-gen-header
	./vnl-gen-header < $< | perl -pe 's{vnlog/vnlog.h}{vnlog.h}' > $@
EXTRA_CLEAN += test/vnlog_fields_generated*.h test/*.got

test check: all
	test/test_vnl-filter.pl
	test/test_vnl-sort.pl
	test/test_vnl-join.pl
	test/test_c_api.sh
	@echo "All tests passed!"
.PHONY: test check

DIST_INCLUDE      := *.h
DIST_BIN          := $(TOOLS)
DIST_PERL_MODULES := lib/Vnlog

install: doc
DIST_MAN     := man1/ man3/

include /usr/include/mrbuild/Makefile.common
