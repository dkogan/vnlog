#pragma once

#include <inttypes.h>
#include <stdint.h>

/*

Asciilog is a trivially-simple log-file format that is tailored to work well
with standard UNIXy tools with common UNIXy workflows.

The log is composed of ASCII text with one data record per line and each record
composed of whitespace-separated fields, i.e. exactly like awk expects. Each
field has some specific meaning for all rows. Lines beginning with # are
comments. The first line that begins with # (but not ##) is a legend line. Past
the #, each field is a label for that field.

Common workflows include filtering with awk and plotting with feedgnuplot or
analyzing with numpy, but this is extremely simple and standard, so many things
are possible and easy.

This all can be trivially generated with printf and processed with awk, but a
few tools exist for convenience:

asciilog-filter: Filters out specific rows,fields possibly with some very
simple postprocessing.

asciilog.h: a C interface so produce asciilog output. Useful because the fields
can be populated by name one at a time without the user needing to think about
their ordering



realtime

 */

#ifdef __cplusplus
extern "C" {
#endif

// Writes out the given \0-terminated string. Does not look at the string, does
// not append a trailing \n and so on.
void asciilog_emit_string(const char* string);

// Directs the output to a given buffer. If this function is never called, the
// output goes to STDOUT
void asciilog_set_output_FILE(FILE* _fp);

// This is called once all the fields have been registered with
// asciilog_register_field(). After we do this, the data can be
// written
void _asciilog_emit_legend(const char* legend, int Nfields);

// Once all the fields for a record have been set with
// asciilog_set_field_value_xxx(), this function is called to emit the record
void _asciilog_emit_and_finish_record(int Nfields);

void _asciilog_set_field_value(const char* fieldname, int idx,
                               const char* fmt, ...);


#ifdef __cplusplus
}
#endif

