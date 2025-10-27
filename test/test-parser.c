#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../vnlog-parser.h"

#define MSG(fmt, ...) \
    fprintf(stderr, "%s:%d " fmt "\n", __FILE__, __LINE__, ##__VA_ARGS__)

int main(int argc, char* argv[])
{
    if(argc != 3)
    {
        fprintf(stderr, "Usage: %s input.vnl query-key\n", argv[0]);
        return 1;
    }

    const char* filename = argv[1];
    FILE* fp = (0 == strcmp(filename,"-")) ?
        stdin : fopen(filename, "r");
    if(fp == NULL)
    {
        MSG("Couldn't open '%s'", filename);
        return 1;
    }

    const char* querykey = argv[2];


    vnlog_parser_t ctx;
    if(VNL_OK != vnlog_parser_init(&ctx, fp))
        return 1;

    const char*const* queryvalue = vnlog_parser_record_from_key(&ctx, querykey);

    vnlog_parser_result_t result;
    while(VNL_OK == (result = vnlog_parser_read_record(&ctx, fp)))
    {
        printf("======\n");
        for(int i=0; i<ctx.Ncolumns; i++)
        {
            printf("%s = %s\n", ctx.record[i].key, ctx.record[i].value);
        }
        printf("query: %s = %s\n",
               querykey,
               queryvalue != NULL ? *queryvalue : "NOT FOUND");
    }

    vnlog_parser_free(&ctx);
    return (result == VNL_OK || result == VNL_EOF) ? 0 : 1;
}
