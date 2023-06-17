include choose_mrbuild.mk
include $(MRBUILD_MK)/Makefile.common.header

PROJECT_NAME := vnlog

ABI_VERSION  := 0
TAIL_VERSION := 1

LIB_SOURCES :=					\
  b64_cencode.c					\
  vnlog.c					\
  vnlog-parser.c

BIN_SOURCES := test/test1.c test/test-parser.c

TOOLS :=					\
  vnl-filter					\
  vnl-align					\
  vnl-sort					\
  vnl-join					\
  vnl-tail					\
  vnl-ts					\
  vnl-uniq                                      \
  vnl-gen-header				\
  vnl-make-matrix


# I construct the README.org from the template. The only thing I do is to insert
# the manpages. Note that this is more complicated than it looks:
#
# 1. The tools are written in perl and contain POD documentation
# 2. This documentation is stripped out here with pod2text, and included in the
#    README. This README is an org-mode file, and the README.template.org
#    container included the manpage text inside a #+BEGIN_EXAMPLE/#+END_EXAMPLE.
#    So the manpages are treated as a verbatim, unformatted text blob
# 3. Further down, the same POD is converted to a manpage via pod2man
define MAKE_README =
BEGIN									\
{									\
  for $$a (@ARGV)							\
  {									\
    $$c{$$a} = `pod2text $$a | mawk "/REPOSITORY/{exit} {print}"`;	\
  }									\
}									\
									\
while(<STDIN>)								\
{									\
  print s/xxx-manpage-(.*?)-xxx/$$c{$$1}/gr;				\
}
endef

README.org: README.template.org $(TOOLS)
	< $(filter README%,$^) perl -e '$(MAKE_README)' $(filter-out README%,$^) > $@
all: README.org



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

CFLAGS += -I. -std=gnu99 -Wno-missing-field-initializers

test/test1: test/test2.o
test/test1.o: test/vnlog_fields_generated1.h
test/test2.o: test/vnlog_fields_generated2.h
test/vnlog_fields_generated%.h: test/vnlog%.defs vnl-gen-header
	./vnl-gen-header < $< | perl -pe 's{vnlog/vnlog.h}{vnlog.h}' > $@
EXTRA_CLEAN += test/vnlog_fields_generated*.h test/*.got

# Set up the test suite to be runnable in parallel
test check:					\
   test/test_vnl-filter.pl.RUN			\
   test/test_vnl-sort.pl.RUN			\
   test/test_vnl-join.pl.RUN			\
   test/test_vnl-uniq.pl.RUN			\
   test/test_c_api.sh.RUN			\
   test/test_perl_parser.pl.RUN			\
   test/test_python3_parser.sh.RUN
	@echo "All tests in the test suite passed!"
.PHONY: test check
%.RUN: %
	$<
test/test_c_api.sh.RUN: test/test1 test/test-parser
EXTRA_CLEAN += test/testdata_*


DIST_INCLUDE      := vnlog*.h
DIST_BIN          := $(TOOLS)
DIST_PERL_MODULES := lib/Vnlog
DIST_PY3_MODULES  := lib/vnlog.py

install: doc
DIST_MAN     := man1/ man3/

include $(MRBUILD_MK)/Makefile.common.footer
