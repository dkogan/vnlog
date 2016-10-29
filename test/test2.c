#include "asciilog_fields_generated2.h"

void test2(void)
{
    struct asciilog_context_t ctx;
    asciilog_init_session_ctx(&ctx);

    FILE* fp = fopen("test2.got", "w");
    if(fp == NULL) return;
    asciilog_set_output_FILE(&ctx, fp);

    asciilog_emit_legend_ctx(&ctx);

    asciilog_set_field_value_ctx__a(&ctx, -3);
    asciilog_emit_record_ctx(&ctx);

    asciilog_set_field_value_ctx__b(&ctx, -4);
    asciilog_emit_record_ctx(&ctx);

    fclose(fp);
    asciilog_free_ctx(&ctx);
}
