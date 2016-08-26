PROJECT_NAME := asciilog

ABI_VERSION  := 0
TAIL_VERSION := 1

LIB_SOURCES := *.c*
BIN_SOURCES := test/test.c

CCXXFLAGS := -I.

DIST_INCLUDE := *.h
DIST_BIN     := asciilog-filter

#include /usr/include/mrbuild/Makefile.common
include /tmp/Makefile.common
