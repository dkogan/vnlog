#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>

#include "vnlog-parser.h"

#define MSG(fmt, ...) \
    fprintf(stderr, "%s:%d " fmt "\n", __FILE__, __LINE__, ##__VA_ARGS__)

static
bool add_to_legend(// out
                   int* Ncolumns_allocated,
                   int* Ncolumns,
                   keyvalue_t** record,

                   // in
                   char* str)
{
    if(*str == '\0')
        // Empty string. Nothing to do
        return true;

    if(*Ncolumns_allocated <= *Ncolumns)
    {
        (*Ncolumns_allocated) += 1;
        (*Ncolumns_allocated) *= 2;

        *record = (keyvalue_t*)realloc(*record,
                                       (*Ncolumns_allocated) * sizeof((*record)[0]));
        if(*record == NULL)
        {
            MSG("Couldn't allocate record");
            return false;
        }
    }

    (*record)[*Ncolumns].value = NULL;
    (*record)[*Ncolumns].key   = strdup(str);
    if((*record)[*Ncolumns].key == NULL)
        return false;

    (*Ncolumns)++;
    return true;
}

static
bool add_to_row(// out
                keyvalue_t* record,
                int*        i_col,
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

    while(true)
    {
        if(0 > getline(&ctx->_line, &ctx->_n, fp))
        {
            if(errno == 0)
                // done reading file
                return VNL_EOF;

            MSG("vnl_error reading file: %d", errno);
            return VNL_ERROR;
        }

        // Have one line. Parse it.
        char* token;
        char* string_to_tokenize = ctx->_line;
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
                if(!add_to_legend(&Ncolumns_allocated,
                                  &ctx->Ncolumns,
                                  &ctx->record,
                                  &token[1]))
                        return VNL_ERROR;

                // grab next token from this line
                continue;
            }

            if(parsing_legend_now)
            {
                if(!add_to_legend(&Ncolumns_allocated,
                                  &ctx->Ncolumns,
                                  &ctx->record,
                                  token))
                    return VNL_ERROR;
                continue;
            }

            // Data token
            if(!add_to_row(ctx->record,
                           &i_col,
                           ctx->Ncolumns,
                           token))
                return VNL_ERROR;
        }

        // Finished line
        if(parsing_legend_now && ctx->Ncolumns == 0)
        {
            // Empty legend line. Wasn't really a legend. Get another.
            parsing_legend_now = false;
            continue;
        }
        if(i_col == 0)
            // Empty line. Get another one
            continue;

        if(!parsing_legend_now &&
           i_col != ctx->Ncolumns)
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

vnlog_parser_result_t vnlog_parser_init(vnlog_parser_t* ctx, FILE* fp)
{
    *ctx = (vnlog_parser_t){};

    vnlog_parser_result_t result = read_line(ctx, fp);

    if(result != VNL_OK)
        vnlog_parser_free(ctx);
    return result;
}

void vnlog_parser_free(vnlog_parser_t* ctx)
{
    if(ctx != NULL)
    {
        free(ctx->_line);

        if(ctx->record != NULL)
        {
            for(int i=0; i<ctx->Ncolumns; i++)
                free(ctx->record[i].key);
        }
        free(ctx->record);
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

    vnlog_parser_result_t result = read_line(ctx, fp);

    if(result != VNL_OK)
        vnlog_parser_free(ctx);
    return result;
}