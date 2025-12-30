#define _GNU_SOURCE // for tdestroy()
#define _SEARCH_PRIVATE // for node_t, in absence of tdestroy

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>
#include <stddef.h>
#include <search.h>

#include "vnlog-parser.h"

#define MSG(fmt, ...) \
    fprintf(stderr, "%s:%d " fmt "\n", __FILE__, __LINE__, ##__VA_ARGS__)

typedef struct
{
    // internal
    char*  line;
    size_t n;
    void*  dict_key_index;
} vnlog_parser_internal_t;

_Static_assert( sizeof(vnlog_parser_internal_t) <=
                sizeof(vnlog_parser_t) - offsetof(vnlog_parser_t, _internal),
                "vnlog_parser_internal_t must fit in the allotted space");

static
bool accumulate_legend(// out
                       int* Ncolumns_allocated,
                       int* i_col,
                       vnlog_keyvalue_t** record,

                       // in
                       char* str)
{
    if(*str == '\0')
        // Empty string. Nothing to do
        return true;

    if(*Ncolumns_allocated <= *i_col)
    {
        (*Ncolumns_allocated) += 1;
        (*Ncolumns_allocated) *= 2;

        *record = (vnlog_keyvalue_t*)realloc(*record,
                                             (*Ncolumns_allocated) * sizeof((*record)[0]));
        if(*record == NULL)
        {
            MSG("Couldn't allocate record");
            return false;
        }
    }

    (*record)[*i_col].value = NULL;
    (*record)[*i_col].key   = strdup(str);
    if((*record)[*i_col].key == NULL)
        return false;

    (*i_col)++;
    return true;
}

static
bool accumulate_data_row(// out
                         vnlog_keyvalue_t* record,
                         int*              i_col,
                         // in
                         int   Ncolumns,
                         char* str)
{
    if(*str == '\0')
        // Empty string. Nothing to do
        return true;

    if(Ncolumns == 0)
    {
        MSG("Saw data line before a legend line");
        return false;
    }

    if((*i_col) >= Ncolumns)
    {
        MSG("legend said we have %d columns, but saw a data line that has too many", Ncolumns);
        return false;
    }

    record[(*i_col)++].value = str;
    return true;
}

static
vnlog_parser_result_t read_line(vnlog_parser_t* ctx, FILE* fp)
{
    int Ncolumns_allocated = 0;

    vnlog_parser_internal_t* internal = (vnlog_parser_internal_t*)ctx->_internal;

    while(true)
    {
        if(0 > getline(&internal->line, &internal->n, fp))
        {
            if(feof(fp))
                // done reading file
                return VNL_EOF;

            MSG("vnl_error reading file: %d", errno);
            return VNL_ERROR;
        }

        // Have one line. Parse it.
        char* token;
        char* string_to_tokenize = internal->line;
        int i_col = 0;

        const bool legend_is_done = (ctx->record != NULL);
        bool parsing_legend_now = false;

        while(NULL != (token = strtok(string_to_tokenize, " \t\n")))
        {
            string_to_tokenize = NULL;

            if(token[0] == '#')
            {
                if(token[1] == '#' || token[1] == '!')
                    // hard comment
                    break;
                if(i_col > 0)
                    // The legend can only appear in the first column
                    break;
                if(legend_is_done)
                    // Already parsed the legend. The rest of this line is
                    // comments to be ignored
                    break;
                if(parsing_legend_now)
                    // We already started the legend. This comment finishes it
                    break;

                // This is the start of the legend. Parse all the columns
                parsing_legend_now = true;
                if(!accumulate_legend(&Ncolumns_allocated,
                                      &i_col,
                                      &ctx->record,
                                      &token[1]))
                        return VNL_ERROR;

                // grab next token from this line
                continue;
            }

            if(parsing_legend_now)
            {
                if(!accumulate_legend(&Ncolumns_allocated,
                                      &i_col,
                                      &ctx->record,
                                      token))
                    return VNL_ERROR;
                continue;
            }

            // Data token
            if(!accumulate_data_row(ctx->record,
                                    &i_col,
                                    ctx->Ncolumns,
                                    token))
                return VNL_ERROR;
        }

        // Finished line
        if(i_col == 0)
        {
            // Empty line. Get another.
            parsing_legend_now = false;
            continue;
        }

        if(parsing_legend_now)
            ctx->Ncolumns = i_col;
        else if(i_col != ctx->Ncolumns)
        {
            MSG("Legend has %d columns, but just saw a data line of %d columns",
                ctx->Ncolumns, i_col);
            return VNL_ERROR;
        }

        // Done. All good!
        return VNL_OK;
    }

    MSG("Getting here is a bug");
    return VNL_ERROR;
}

#ifdef __APPLE__
// tdestry is a nonstandard extension not present in Apple's libc, but it is easy to redefine

static void tdestroy_recurse(node_t *root, void (*freefct)(void *))
{
    if (root->llink != NULL)
    {
        tdestroy_recurse(root->llink, freefct);
    }
    if (root->rlink != NULL)
    {
        tdestroy_recurse(root->rlink, freefct);
    }
    // Free the node contents (if necessary)
    freefct(root->key);
    // Free the node itself
    free(root);
}

void tdestroy(void *root, void (*freefct)(void *))
{
    if (root == NULL)
    {
        // Tree is already empty
        return;
    }

    tdestroy_recurse(root, freefct);
}
#endif

static
int compare_record(const vnlog_keyvalue_t* a, const vnlog_keyvalue_t* b)
{
    return strcmp(a->key, b->key);
}
static void noop_free(void* _dummy __attribute__((unused)) )
{
}

vnlog_parser_result_t vnlog_parser_init(vnlog_parser_t* ctx, FILE* fp)
{
    *ctx = (vnlog_parser_t){};

    vnlog_parser_result_t result = read_line(ctx, fp);

    if(result != VNL_OK)
    {
        vnlog_parser_free(ctx);
        return result;
    }

    vnlog_parser_internal_t* internal = (vnlog_parser_internal_t*)ctx->_internal;

    // Parsed the legend. Now create a tree to make it easy to look up the
    // specific column by key name. Probably these will be called once per run,
    // so it could be a simple linear search, but a binary tree is easy-enough
    // to use, so I do that
    for(int i=0; i<ctx->Ncolumns; i++)
    {
        if(NULL ==
           tsearch( (const void*)&ctx->record[i],
                    &internal->dict_key_index,
                    (int(*)(const void*,const void*))compare_record))
            return VNL_ERROR;
    }

    return VNL_OK;
}

void vnlog_parser_free(vnlog_parser_t* ctx)
{
    if(ctx != NULL)
    {
        vnlog_parser_internal_t* internal = (vnlog_parser_internal_t*)ctx->_internal;
        if(internal != NULL)
        {
            free(internal->line);
            tdestroy(internal->dict_key_index, &noop_free);
        }

        if(ctx->record != NULL)
        {
            for(int i=0; i<ctx->Ncolumns; i++)
                free(ctx->record[i].key);
            free(ctx->record);
        }
    }
    *ctx = (vnlog_parser_t){};
}

vnlog_parser_result_t vnlog_parser_read_record(vnlog_parser_t* ctx, FILE* fp)
{
    if(ctx == NULL || ctx->record == NULL)
    {
        MSG("Legend hasn't been read. Call vnlog_parser_init() first");
        return VNL_ERROR;
    }

    return read_line(ctx, fp);
}

// pointer to the pointer to the string for the record corresponding to the
// given key in the most-recently-parsed row. NULL if the given key isn't found
const char*const* vnlog_parser_record_from_key(vnlog_parser_t* ctx, const char* key)
{
    vnlog_parser_internal_t* internal = (vnlog_parser_internal_t*)ctx->_internal;

    const vnlog_keyvalue_t*const* keyvalue =
        tfind( (const void*)&(const vnlog_keyvalue_t){.key = (char*)key},
               &internal->dict_key_index,
               (int(*)(const void*,const void*))compare_record);
    if(keyvalue == NULL)
        return NULL;

    return (const char*const*)&(*keyvalue)->value;
}
