#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#define ASCIILOG_C
#include "asciilog.h"

#define ERR(fmt, ...) do {                                              \
  fprintf(stderr, "FATAL ERROR! %s: %s(): " fmt "\n", __FILE__, __func__, ## __VA_ARGS__); \
  exit(1);                                                              \
} while(0)

void _asciilog_init_ctx( struct asciilog_context_t* ctx,
                         int Nfields);

// ASCIILOG_N_FIELDS is unknown here so the asciilog_context_t structure has 0
// elements. I dynamically allocate it later with the proper size
static struct asciilog_context_t* get_global_context(int Nfields)
{
    static struct asciilog_context_t* ctx;

    if(!ctx)
    {
        if(Nfields < 0)
            ERR("Creating a global context not at the start");
        ctx = malloc(sizeof(struct asciilog_context_t) +
                     Nfields * sizeof(ctx->fields[0]));
        if(!ctx) ERR("Couldn't allocate context with %d fields", Nfields);

        _asciilog_init_ctx(ctx, Nfields);
    }
    return ctx;
}



static void check_fp(struct asciilog_context_t* ctx)
{
    if(!ctx->fp)
        asciilog_set_output_FILE(ctx, stdout);
}
static void _emit(struct asciilog_context_t* ctx, const char* string)
{
    fprintf(ctx->fp, "%s", string);
    ctx->emitted_something = true;
}

static void emit(struct asciilog_context_t* ctx, const char* string)
{
    check_fp(ctx);
    _emit(ctx, string);
}

void _asciilog_printf(struct asciilog_context_t* ctx, const char* fmt, ...)
{
    check_fp(ctx);
    va_list ap;
    va_start(ap, fmt);
    vfprintf(ctx->fp, fmt, ap);
    va_end(ap);

    ctx->emitted_something = true;
}

void _asciilog_flush(struct asciilog_context_t* ctx)
{
    check_fp(ctx);
    fflush(ctx->fp);
}

void asciilog_set_output_FILE(struct asciilog_context_t* ctx, FILE* fp)
{
    if(ctx->fp)
        ERR("fp is already set");
    if( ctx->emitted_something )
        ERR("Can only change the output at the start");

    ctx->fp = fp;
}

static void flush(struct asciilog_context_t* ctx)
{
    fflush(ctx->fp);
}

static void clear_ctx_fields(struct asciilog_context_t* ctx, int Nfields)
{
    ctx->line_has_any_values = false;
    for(int i=0; i<Nfields; i++)
    {
        ctx->fields[i].c[0] = '-';
        ctx->fields[i].c[1] = '\0';
    }
}

void _asciilog_init_ctx( struct asciilog_context_t* ctx,
                         int Nfields)
{
    if( ctx == NULL )
        ERR("Can't init a NULL context");

    *ctx = (struct asciilog_context_t){}; // zero out structure
    clear_ctx_fields( ctx, Nfields );
}

void _asciilog_init_child_ctx(      struct asciilog_context_t* ctx,
                              const struct asciilog_context_t* ctx_src,
                              int Nfields)
{
    if( ctx     == NULL ) ERR("Can't init a NULL context");
    if( ctx_src == NULL ) ctx_src = get_global_context(Nfields);

    if( !ctx_src->legend_finished )
        ERR("Cannot create children contexts before writing a legend. Hard to keep state consistent otherwise.");


    // copy all the context except for the flexible array at the end
    *ctx = *ctx_src;

    // reset the flexible array
    clear_ctx_fields( ctx, Nfields );
}

void _asciilog_emit_legend(struct asciilog_context_t* ctx, const char* legend, int Nfields)
{
    if( ctx == NULL ) ctx = get_global_context(Nfields);

    if( ctx->legend_finished )
        ERR("already have a legend");
    ctx->legend_finished = true;

    emit(ctx, legend);
    flush(ctx);
}

void _asciilog_set_field_value(struct asciilog_context_t* ctx,
                               const char* fieldname, int idx,
                               const char* fmt, ...)
{
    if( ctx == NULL ) ctx = get_global_context(-1);

    if(!ctx->legend_finished)
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
    if( ctx == NULL ) ctx = get_global_context(-1);

    if(!ctx->legend_finished)
        ERR("need a legend to do this");

    if(!ctx->line_has_any_values)
        ERR("Tried to emit a log line without any values being set");

    check_fp(ctx);

    flockfile(ctx->fp);
    for(int i=0; i<Nfields-1; i++)
    {
        _emit(ctx, ctx->fields[i].c);
        _emit(ctx, " ");
    }
    _emit(ctx, ctx->fields[Nfields-1].c);
    _emit(ctx, "\n");
    funlockfile(ctx->fp);

    // I want to be able to process streaming data, so I flush the buffer now
    flush(ctx);

    clear_ctx_fields(ctx, Nfields);
}
