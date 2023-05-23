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
    void* _dict_key_index;

} vnlog_parser_t;

typedef enum
{
    VNL_OK, VNL_EOF, VNL_ERROR
} vnlog_parser_result_t;

vnlog_parser_result_t vnlog_parser_init(vnlog_parser_t* ctx, FILE* fp);

void vnlog_parser_free(vnlog_parser_t* ctx);

vnlog_parser_result_t vnlog_parser_read_record(vnlog_parser_t* ctx, FILE* fp);

// pointer to the pointer to the string that will contain the
// most-recently-parsed value for the given key. Returns NULL if the given key
// isn't found
const char*const* vnlog_parser_record_from_key(vnlog_parser_t* ctx, const char* key);

