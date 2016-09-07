#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#define ASCIILOG_C
#include "asciilog.h"

#define ERR(fmt, ...) do {                                              \
  fprintf(stderr, "FATAL ERROR! %s: %s(): " fmt "\n", __FILE__, __func__, ## __VA_ARGS__); \
  exit(1);                                                              \
} while(0)

static FILE* fp = NULL;
static bool legend_finished;

// ASCIILOG_N_FIELDS is unknown here so the asciilog_context_t structure has 0
// elements. I dynamically allocate it later with the proper size
static struct asciilog_context_t* global_context;

__attribute__((constructor))
static void init(void)
{
    global_context = calloc(1, sizeof(struct asciilog_context_t));
}

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

void _asciilog_clear_ctx(struct asciilog_context_t* ctx, int Nfields)
{
    if( ctx == NULL ) ctx = global_context;

    ctx->line_has_any_values = false;
    for(int i=0; i<Nfields; i++)
    {
        ctx->fields[i].c[0] = '-';
        ctx->fields[i].c[1] = '\0';
    }
}

void _asciilog_emit_legend(const char* legend, int Nfields)
{
    if( legend_finished )
        ERR("already have a legend");

    emit(legend);
    flush();

    global_context = realloc(global_context,
                             sizeof(struct asciilog_context_t) +
                             Nfields * sizeof(global_context->fields[0]));
    if(!global_context)
        ERR("Couldn't allocate context with %d fields", Nfields);
    legend_finished = true;

    _asciilog_clear_ctx(global_context, Nfields);
}

void _asciilog_set_field_value(struct asciilog_context_t* ctx,
                               const char* fieldname, int idx,
                               const char* fmt, ...)
{
    if( ctx == NULL ) ctx = global_context;

    if(!legend_finished)
        ERR("need a legend to do this");
    if(ctx->fields[idx].c[0] != '-' || ctx->fields[idx].c[1] != '\0')
        ERR("Field '%s' already set. Old value: '%s'",
            fieldname, ctx->fields[idx].c);

    ctx->line_has_any_values = true;

    va_list ap;
    va_start(ap, fmt);
    if( (int)sizeof(ctx->fields[0]) <=
        vsnprintf(ctx->fields[idx].c, sizeof(ctx->fields[0]), fmt, ap) )
    {
        ERR("Field size exceeded for field '%s'", fieldname);
    }
    va_end(ap);
}

void _asciilog_emit_record(struct asciilog_context_t* ctx, int Nfields)
{
    if( ctx == NULL ) ctx = global_context;

    if(!legend_finished)
        ERR("need a legend to do this");

    if(!ctx->line_has_any_values)
        ERR("Tried to emit a log line without any values being set");

    check_fp();

    flockfile(fp);
    for(int i=0; i<Nfields-1; i++)
    {
        _emit(ctx->fields[i].c);
        _emit(" ");
    }
    _emit(ctx->fields[Nfields-1].c);
    _emit("\n");
    funlockfile(fp);

    // I want to be able to process streaming data, so I flush the buffer now
    flush();

    _asciilog_clear_ctx(ctx, Nfields);
}
