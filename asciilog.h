#pragma once

#include <stdio.h>
#include <stdbool.h>

#ifndef ASCIILOG_N_FIELDS
#ifndef ASCIILOG_C
#error Please do not include asciilog.h directly. Instead include the header made by asciilog-gen-header
#endif
#endif


/*
This is an interface to produce asciilog output from C programs. Common usage:

  In a shell:

    asciilog-gen-header 'int w' 'uint8_t x' 'char* y' 'double z' > asciilog_fields_generated.h

  In a C program test.c:

    #include "asciilog_fields_generated.h"

    int main()
    {
        asciilog_emit_legend();

        asciilog_set_field_value__w(-10);
        asciilog_set_field_value__x(40);
        asciilog_set_field_value__y("asdf");
        asciilog_emit_record();

        asciilog_set_field_value__z(0.3);
        asciilog_set_field_value__x(50);
        asciilog_set_field_value__w(-20);
        asciilog_emit_record();

        return 0;
    }

  $ cc -o test test.c -lasciilog

  $ ./test

  # w x y z
  -10 40 asdf -
  -20 50 - 0.300000


Note that THIS FILE IS NOT MEANT TO BE #include-ed BY THE USER. IT SHOULD BE
INCLUDED BY THE GENERATED asciilog_fieldss_generated.h
 */


#define ASCIILOG_MAX_FIELD_LEN 32

// If we're building the LIBRARY, we don't know how many fields we'll have, so
// asciilog_context_t will be a non-instantiatable array
#ifndef ASCIILOG_N_FIELDS
    #define ASCIILOG_N_FIELDS
#endif

typedef struct { char c[ASCIILOG_MAX_FIELD_LEN]; } asciilog_field_t;
struct asciilog_context_t
{
    bool                 legend_finished     : 1;
    bool                 line_has_any_values : 1;
    asciilog_field_t     fields[ASCIILOG_N_FIELDS];
};



#ifdef __cplusplus
extern "C" {
#endif

// Directs the output to a given buffer. If this function is never called, the
// output goes to STDOUT. If it IS called, that must happen before anything else
void asciilog_set_output_FILE(FILE* _fp);

// THIS FUNCTION IS NOT A PART OF THE PUBLIC API. The user should call
//
//     asciilog_emit_legend()
//
// The header generated by asciilog-gen-header converts one call to the other.
// This is called once to write out the legend. Must be called before any data
// can be written
void _asciilog_emit_legend(const char* legend, int Nfields);

// THIS FUNCTION IS NOT A PART OF THE PUBLIC API. The user should call
//
//     asciilog_set_field_value__FIELDNAME(value)
//
// The header generated by asciilog-gen-header converts one call to the other.
void _asciilog_set_field_value(const char* fieldname, int idx,
                               const char* fmt, ...);

// THIS FUNCTION IS NOT A PART OF THE PUBLIC API. The user should call
//
//     asciilog_emit_record()
//
// Once all the fields for a record have been set with
// asciilog_set_field_value__FIELDNAME(), this function is called to emit the
// record. Any fields not set get written as -
void _asciilog_emit_record(int Nfields);

// Writes out the given printf-style format to the asciilog. Generally this is a
// comment string, so it should start with a '#' and end in a '\n', but I do not
// check or enforce this.
void asciilog_printf(const char* fmt, ...);

// Flushes the output buffer. Useful in conjunction with asciilog_printf()
void asciilog_flush(void);

// THIS FUNCTION IS NOT A PART OF THE PUBLIC API. The user should call
//
//     asciilog_stash(ctx)
//
// saves the current record-in-progress to the given context structure, and
// clears out the current record with clear()
void _asciilog_stash(             struct asciilog_context_t* ctx, int Nfields);

// THIS FUNCTION IS NOT A PART OF THE PUBLIC API. The user should call
//
//     asciilog_apply_stash(ctx)
//
// applies a stashed record made with asciilog_stash(). Can only be called if
// the current record is empty
void _asciilog_stash_apply (const struct asciilog_context_t* ctx, int Nfields);

#ifdef __cplusplus
}
#endif

