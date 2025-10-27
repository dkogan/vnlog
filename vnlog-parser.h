#pragma once

typedef struct
{
    char* key;
    char* value;
} vnlog_keyvalue_t;

typedef struct
{
    int               Ncolumns;
    vnlog_keyvalue_t* record;

    // This is aliased to vnlog_parser_internal_t.
    //
    // More space than needed today. For future binary compatibility. I ask for
    // this structure to create an aligned buffer
    struct {size_t a; int* b;} _internal[8];

} vnlog_parser_t;

typedef enum
{
    VNL_OK, VNL_EOF, VNL_ERROR
} vnlog_parser_result_t;

vnlog_parser_result_t vnlog_parser_init(vnlog_parser_t* ctx, FILE* fp);

// Call vnlog_parser_free() when done. Even if vnlog_parser_read_record() failed
void vnlog_parser_free(vnlog_parser_t* ctx);

vnlog_parser_result_t vnlog_parser_read_record(vnlog_parser_t* ctx, FILE* fp);

// pointer to the pointer to the string for the record corresponding to the
// given key in the most-recently-parsed row. NULL if the given key isn't found
const char*const* vnlog_parser_record_from_key(vnlog_parser_t* ctx, const char* key);

