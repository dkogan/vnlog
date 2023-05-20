#pragma once

typedef struct
{
    char* key;
    char* value;
} keyvalue_t;

typedef struct
{
    int         Ncolumns;
    keyvalue_t* record;

    // internal
    char*  _line;
    size_t _n;
} vnlog_parser_t;

typedef enum
{
    VNL_OK, VNL_EOF, VNL_ERROR
} vnlog_parser_result_t;

vnlog_parser_result_t vnlog_parser_init(vnlog_parser_t* ctx, FILE* fp);

void vnlog_parser_free(vnlog_parser_t* ctx);

vnlog_parser_result_t vnlog_parser_read_record(vnlog_parser_t* ctx, FILE* fp);

