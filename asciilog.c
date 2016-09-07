#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#define ASCIILOG_C
#include "asciilog.h"

#define ERR(fmt, ...) do {                                              \
  fprintf(stderr, "FATAL ERROR! %s: %s(): " fmt "\n", __FILE__, __func__, ## __VA_ARGS__); \
  exit(1);                                                              \
} while(0)

static FILE*             fp                  = NULL;
static bool              legend_finished     = false;
static bool              line_has_any_values = false;
static asciilog_field_t* fields              = NULL;



static void check_fp(void)
{
    if(!fp)
        asciilog_set_output_FILE(stdout);
}
static void _emit(const char* string)
{
    fprintf(fp, "%s", string);
}
static void emit(const char* string)
{
    check_fp();
    _emit(string);
}

void asciilog_printf(const char* fmt, ...)
{
    check_fp();
    va_list ap;
    va_start(ap, fmt);
    vfprintf(fp, fmt, ap);
    va_end(ap);
}

void asciilog_flush(void)
{
    check_fp();
    fflush(fp);
}

void asciilog_set_output_FILE(FILE* _fp)
{
    if(fp)
        ERR("fp is already set");

    if( legend_finished )
        ERR("Can only change the output at the start");

    fp = _fp;
}

static void flush(void)
{
    fflush(fp);
}

static void clear(int Nfields)
{
    line_has_any_values = false;
    for(int i=0; i<Nfields; i++)
    {
        fields[i].c[0] = '-';
        fields[i].c[1] = '\0';
    }
}

void _asciilog_emit_legend(const char* legend, int Nfields)
{
    if( legend_finished )
        ERR("already have a legend");

    emit(legend);
    flush();

    fields = malloc(Nfields * sizeof(fields[0]));
    if(!fields)
        ERR("Couldn't allocate %d fields", Nfields);
    legend_finished = true;

    clear(Nfields);
}

void _asciilog_set_field_value(const char* fieldname, int idx,
                               const char* fmt, ...)
{
    if(!legend_finished)
        ERR("need a legend to do this");
    if(fields[idx].c[0] != '-' || fields[idx].c[1] != '\0')
        ERR("Field '%s' already set. Old value: '%s'",
            fieldname, fields[idx].c);

    line_has_any_values = true;

    va_list ap;
    va_start(ap, fmt);
    if( (int)sizeof(fields[0]) <=
        vsnprintf(fields[idx].c, sizeof(fields[0]), fmt, ap) )
    {
        ERR("Field size exceeded for field '%s'", fieldname);
    }
    va_end(ap);
}

void _asciilog_emit_record(int Nfields)
{
    if(!legend_finished)
        ERR("need a legend to do this");

    if(!line_has_any_values)
        ERR("Tried to emit a log line without any values being set");

    check_fp();

    flockfile(fp);
    for(int i=0; i<Nfields-1; i++)
    {
        _emit(fields[i].c);
        _emit(" ");
    }
    _emit(fields[Nfields-1].c);
    _emit("\n");
    funlockfile(fp);

    // I want to be able to process streaming data, so I flush the buffer now
    flush();

    clear(Nfields);
}

void _asciilog_stash(struct asciilog_context_t* ctx, int Nfields)
{
    ctx->line_has_any_values = line_has_any_values;
    memcpy(ctx->fields, fields, sizeof(fields[0])*Nfields);

    clear(Nfields);
}

void _asciilog_stash_apply(const struct asciilog_context_t* ctx, int Nfields)
{
    if(line_has_any_values)
        ERR("Tried to apply a stash, but I already have a record in progress");

    line_has_any_values = ctx->line_has_any_values;
    memcpy(fields, ctx->fields, sizeof(fields[0])*Nfields);
}
