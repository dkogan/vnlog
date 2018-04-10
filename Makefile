PROJECT_NAME := vnlog

ABI_VERSION  := 0
TAIL_VERSION := 1

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


# I construct the README.org from the template. The only thing I do is to insert
# the manpages
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

README.org: README.template.org vnl-filter vnl-align vnl-sort vnl-join vnl-tail
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
EXTRA_CLEAN += man1 man3 README.org

CFLAGS := -I. -std=gnu99 -Wno-missing-field-initializers

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
   test/test_c_api.sh.RUN			\
   test/test_perl_parser.pl.RUN			\
   test/test_python2_parser.sh.RUN              \
   test/test_python3_parser.sh.RUN
	@echo "All tests in the test suite passed!"
.PHONY: test check
%.RUN: %
	$<
test/test_c_api.sh.RUN: test/test1

DIST_INCLUDE      := vnlog.h
DIST_BIN          := $(TOOLS)
DIST_PERL_MODULES := lib/Vnlog
DIST_PY2_MODULES  := lib/vnlog.py
DIST_PY3_MODULES  := lib/vnlog.py

install: doc
DIST_MAN     := man1/ man3/







# This is the chunks of the Makefile.common from mrbuild that we need. I don't
# want to introduce a dependency in this public project, so I simply copy the
# build boilerplate. It's unlikely to change.



# The default VERSION string that appears as a #define to each source file, and
# to any generated documentation (gengetopt and so on). The user can set this to
# whatever they like
VERSION ?= $(ABI_VERSION).$(TAIL_VERSION)

# Default compilers. By default, we use g++ as a linker
CC        ?= gcc
CC_LINKER ?= $(CC)

# used to make gcc output header dependency information. All source
# files generated .d dependency definitions that are included at the
# bottom of this file
CCXXFLAGS += -MMD -MP

# always building with debug information. This is stripped into the
# -dbg/-debuginfo packages by debhelper/rpm later
CCXXFLAGS += -g

# I want the frame pointer. Makes walking the stack WAY easier
CCXXFLAGS += -fno-omit-frame-pointer

# all warnings by default
CCXXFLAGS += -Wall -Wextra


# I look through my LIB_SOURCES and BIN_SOURCES. Anything that isn't a wildcard
# (has * or ?) should exist. If it doesn't, the user messed up and I flag it
get_no_wildcards          = $(foreach v,$1,$(if $(findstring ?,$v)$(findstring *,$v),,$v))
complain_if_nonempty      = $(if $(strip $1),$(error $2: $1))
complain_unless_all_exist = $(call complain_if_nonempty,$(call get_no_wildcards,$(filter-out $(wildcard $1),$1)),File not found: )
$(call complain_unless_all_exist,$(LIB_SOURCES) $(BIN_SOURCES))


LIB_SOURCES := $(wildcard $(LIB_SOURCES))
BIN_SOURCES := $(wildcard $(BIN_SOURCES))

LIB_OBJECTS := $(addsuffix .o,$(basename $(LIB_SOURCES)))
BIN_OBJECTS := $(addsuffix .o,$(basename $(BIN_SOURCES)))

SOURCE_DIRS := $(sort ./ $(dir $(LIB_SOURCES) $(BIN_SOURCES)))

# if the PROJECT_NAME is libxxx then LIB_NAME is libxxx
# if the PROJECT_NAME is xxx    then LIB_NAME is libxxx
LIB_NAME           := $(or $(filter lib%,$(PROJECT_NAME)),lib$(PROJECT_NAME))
LIB_TARGET_SO_BARE := $(LIB_NAME).so
LIB_TARGET_SO_ABI  := $(LIB_TARGET_SO_BARE).$(ABI_VERSION)
LIB_TARGET_SO_FULL := $(LIB_TARGET_SO_ABI).$(TAIL_VERSION)
LIB_TARGET_SO_ALL  := $(LIB_TARGET_SO_BARE) $(LIB_TARGET_SO_ABI) $(LIB_TARGET_SO_FULL)

BIN_TARGETS := $(basename $(BIN_SOURCES))


# all objects built for inclusion in shared libraries get -fPIC. We don't build
# static libraries, so this is 100% correct
$(LIB_OBJECTS): CCXXFLAGS += -fPIC

CCXXFLAGS += -DVERSION='"$(VERSION)"'




# These are here to process the options separately for each file being built.
# This allows per-target options to be set
#
# if no explicit optimization flags are given, optimize
define massageopts
$1 $(if $(filter -O%,$1),,-O3)
endef

# If no C++ standard requested, I default to c++0x
define massageopts_cxx
$(call massageopts,$1 $(if $(filter -std=%,$1),,-std=c++0x))
endef

define massageopts_c
$(call massageopts,$1)
endef



# define the compile rules. I need to redefine the rules here because my
# C..FLAGS variables are simple (immediately evaluated), but the user
# could have specified per-target flags that ALWAYS evaluate deferred-ly
c_build_rule  = $(strip $(CC)   $(call massageopts_c,  $(CFLAGS)   $(CCXXFLAGS) $(CPPFLAGS))) -c -o $@ $<


%.o:%.c
	$(c_build_rule)


# by default I build shared libraries only. We known how to build static
# libraries too, but I don't do it unless asked
all: $(if $(strip $(LIB_SOURCES)),$(LIB_TARGET_SO_ALL)) $(if $(strip $(BIN_SOURCES)),$(BIN_TARGETS))
.PHONY: all
.DEFAULT_GOAL := all

$(LIB_TARGET_SO_FULL): LDFLAGS += -shared -Wl,--default-symver -fPIC -Wl,-soname,$(notdir $(LIB_TARGET_SO_BARE)).$(ABI_VERSION)

$(LIB_TARGET_SO_BARE) $(LIB_TARGET_SO_ABI): $(LIB_TARGET_SO_FULL)
	ln -fs $(notdir $(LIB_TARGET_SO_FULL)) $@

# Here instead of specifying $^, I do just the %.o parts and then the
# others. This is required to make the linker happy to see the dependent
# objects first and the dependency objects last. Same as for BIN_TARGETS
$(LIB_TARGET_SO_FULL): $(LIB_OBJECTS)
	$(CC_LINKER) $(LDFLAGS) $(filter %.o, $^) $(filter-out %.o, $^) $(LDLIBS) -o $@

# I make sure to give the .o to the linker before the .so and everything else.
# The .o may depend on the other stuff. The binaries get an rpath (removed at
# install time)
$(BIN_TARGETS): %: %.o
	$(CC_LINKER) -Wl,-rpath=$(abspath .) $(LDFLAGS) $(filter %.o, $^) $(filter-out %.o, $^) $(LDLIBS) -o $@

# The binaries link with the DSO, if there is one. I need the libxxx.so to build
# the binary, and I need the libxxx.so.abi to run it.
$(BIN_TARGETS): $(if $(strip $(LIB_SOURCES)),$(LIB_TARGET_SO_BARE) $(LIB_TARGET_SO_ABI))




clean:
	rm -rf $(foreach d,$(SOURCE_DIRS),$(addprefix $d,*.a *.o *.so *.so.* *.d moc_* ui_*.h*)) $(BIN_TARGETS) $(foreach s,.c .h,$(addsuffix $s,$(basename $(shell find . -name '*.ggo')))) $(EXTRA_CLEAN)
distclean: clean

.PHONY: distclean clean



########################### installation business
# The distro will 'DESTDIR=debian/tmp make install'. I then set PREFIX=/usr to
# install everything into debian/tmp/usr
#
# A user might do 'PREFIX=/usr/local make install' to write to /usr/local/lib,
# /usr/local/bin, ...

ifneq (,$(filter install,$(MAKECMDGOALS)))
  ifeq  ($(strip $(DESTDIR)$(PREFIX)),)
    $(error 'make install' MUST be called with EITHER DESTDIR or PREFIX defined. \
"DESTDIR=xxx make install" is for package building; \
"PREFIX=/usr/local make install" is for local installs; \
What are you trying to do?)
  endif

  ifneq ($(and $(DESTDIR),$(PREFIX)),)
    $(error 'make install' MUST be called with EITHER DESTDIR or PREFIX defined. \
"DESTDIR=xxx make install" is for package building; \
"PREFIX=/usr/local make install" is for local installs; \
What are you trying to do?)
  endif

  ifneq ($(DESTDIR),)
PREFIX := /usr
  endif

  ifneq ($(PREFIX),)
# DESTDIR should be empty, and is already empty
  endif
endif


# I process the simple wildcard exceptions on DIST_BIN and DIST_INCLUDE in a
# deferred fashion. The reason is that I wand $(wildcard) to run at install
# time, i.e. after stuff is built, and the files $(wildcard) is looking at
# already exist
DIST_BIN_ORIG     := $(DIST_BIN)
DIST_INCLUDE_ORIG := $(DIST_INCLUDE)

DIST_BIN     = $(filter-out $(wildcard $(DIST_BIN_EXCEPT)),		\
                  $(wildcard $(or $(DIST_BIN_ORIG),    $(BIN_TARGETS))))
DIST_INCLUDE = $(filter-out $(wildcard $(DIST_INCLUDE_EXCEPT)),		\
		  $(wildcard $(DIST_INCLUDE_ORIG)))

ifneq (,$(shell grep -qi debian /etc/os-release 2>/dev/null && echo yep))
  # we're a debian box, use the multiarch dir
  DEB_HOST_MULTIARCH := $(shell dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null)
  USRLIB             := $(PREFIX)/lib/$(DEB_HOST_MULTIARCH)
else
  # we're something else. If /usr/lib64 exists, use that. Otherwise /usr/lib
  USRLIB := $(if $(wildcard $(PREFIX)/lib64),$(PREFIX)/lib64,$(PREFIX)/lib)
endif

# Generates the install rules. Arguments:
#   1. variable containing the being installed
#   2. target path they're being installed to
#   3. post-install commands
define install_rule
$(if $(strip $($1)),
	mkdir -p $2 &&									\
	cp -r $($1) $2 &&								\
	$(if $($(1)_EXCEPT_FINDSPEC),find $2 $($(1)_EXCEPT_FINDSPEC) -delete &&)	\
	$(or $3,true) )
endef

ifneq ($(strip $(LIB_SOURCES)),)
install: $(LIB_TARGET_SO_ALL)
endif

install: $(BIN_TARGETS) $(DIST_DOC) $(DIST_MAN) $(DIST_DATA)

# using 'cp -P' instead of 'install' because the latter follows links unconditionally
ifneq ($(strip $(LIB_SOURCES)),)
	mkdir -p $(DESTDIR)/$(USRLIB)
	cp -P $(LIB_TARGET_SO_FULL)  $(DESTDIR)/$(USRLIB)
	ln -fs $(notdir $(LIB_TARGET_SO_FULL)) $(DESTDIR)/$(USRLIB)/$(notdir $(LIB_TARGET_SO_ABI))
	ln -fs $(notdir $(LIB_TARGET_SO_FULL)) $(DESTDIR)/$(USRLIB)/$(notdir $(LIB_TARGET_SO_BARE))
endif
	$(call install_rule,DIST_BIN,         $(DESTDIR)$(PREFIX)/bin,)
	$(call install_rule,DIST_INCLUDE,     $(DESTDIR)$(PREFIX)/include/$(PROJECT_NAME),)
	$(call install_rule,DIST_DOC,         $(DESTDIR)$(PREFIX)/share/doc/$(PROJECT_NAME),)
	$(call install_rule,DIST_MAN,         $(DESTDIR)$(PREFIX)/share/man,)
	$(call install_rule,DIST_DATA,        $(DESTDIR)$(PREFIX)/share/$(PROJECT_NAME),)
	$(call install_rule,DIST_PERL_MODULES,$(DESTDIR)$(PREFIX)/share/perl5,)
	$(call install_rule,DIST_PY2_MODULES, $(DESTDIR)$(PREFIX)/lib/python2.7/dist-packages,)
	$(call install_rule,DIST_PY3_MODULES, $(DESTDIR)$(PREFIX)/lib/python3/dist-packages,)

        # In filenames I rename __colon__ -> :
        # This is required because Make can't deal with : in rules
	for fil in `find $(DESTDIR) -name '*__colon__*'`; do mv $$fil `echo $$fil | sed s/__colon__/:/g`; done

        # Remove rpaths from everything. /usr/bin is allowed to fail because
        # some of those executables aren't ELFs. On the other hand, any .so we
        # find IS en ELF. Those could live in a number of places, since they
        # could be extension modules for the various languages, and I thus look
        # for those EVERYWHERE
ifneq ($(strip $(DIST_BIN)),)
	$(if $(wildcard $(DESTDIR)$(PREFIX)/bin/*),chrpath -d $(DESTDIR)$(PREFIX)/bin/* 2>/dev/null || true)
endif
	find $(DESTDIR) -name '*.so' | xargs chrpath -d

        # Any perl programs need their binary path stuff stripped out. This
        # exists to let these run in-tree, but needs to be removed at
        # install-time (similar to an RPATH)
ifneq ($(strip $(DIST_BIN)),)
	for fil in `find $(DESTDIR)$(PREFIX)/bin -type f`; do head -n1 $$fil | grep -q '^#!.*/perl$$' && perl -n -i -e 'print unless /^\s* use \s+ lib \b/x' $$fil; done
endif
	find $(DESTDIR)$(PREFIX)/share/perl5 -type f | xargs perl -n -i -e 'print unless /^\s* use \s+ lib \b/x'

ifneq ($(strip $(DIST_BIN)),)
        # Everything executable needs specific permission bits
	chmod 0755 $(DESTDIR)$(PREFIX)/bin/*
endif

.PHONY: install



# I want to keep all the intermediate files always
.SECONDARY:

# the header dependencies
-include $(addsuffix *.d,$(SOURCE_DIRS))
