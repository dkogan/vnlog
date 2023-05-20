#include <stdio.h>
#include <stdlib.h>

#include "../vnlog-parser.h"

#define MSG(fmt, ...) \
    fprintf(stderr, "%s:%d " fmt "\n", __FILE__, __LINE__, ##__VA_ARGS__)

int main(int argc, char* argv[])
{
    if(argc != 2)
    {
        fprintf(stderr, "Usage: %s input.vnl\n", argv[0]);
        return 1;
    }

    const char* filename = argv[1];

    FILE* fp = fopen(filename, "r");
    if(fp == NULL)
    {
        MSG("Couldn't open '%s'", filename);
        return 1;
    }


    vnlog_parser_t ctx;
    if(VNL_OK != vnlog_parser_init(&ctx, fp))
        return 1;

    while(VNL_OK == vnlog_parser_read_record(&ctx, fp))
    {
        printf("======\n");
        for(int i=0; i<ctx.Ncolumns; i++)
        {
            printf("%s = %s\n", ctx.record[i].key, ctx.record[i].value);
        }
    }

    return 0;
}