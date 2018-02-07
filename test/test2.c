#include "vanillog_fields_generated2.h"

void test2(void)
{
    struct vanillog_context_t ctx;
    vanillog_init_session_ctx(&ctx);

    FILE* fp = fopen("test2.got", "w");
    if(fp == NULL) return;
    vanillog_set_output_FILE(&ctx, fp);

    vanillog_emit_legend_ctx(&ctx);

    vanillog_set_field_value_ctx__a(&ctx, -3);
    vanillog_emit_record_ctx(&ctx);

    vanillog_set_field_value_ctx__b(&ctx, -4);
    vanillog_emit_record_ctx(&ctx);

    fclose(fp);
    vanillog_free_ctx(&ctx);
}
