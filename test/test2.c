#include "vnlog_fields_generated2.h"

void test2(void)
{
    struct vnlog_context_t ctx;
    vnlog_init_session_ctx(&ctx);

    FILE* fp = fopen("test2.got", "w");
    if(fp == NULL) return;
    vnlog_set_output_FILE(&ctx, fp);

    vnlog_emit_legend_ctx(&ctx);

    vnlog_set_field_value_ctx__a(&ctx, -3);
    vnlog_emit_record_ctx(&ctx);

    vnlog_set_field_value_ctx__b(&ctx, -4);
    vnlog_emit_record_ctx(&ctx);

    fclose(fp);
    vnlog_free_ctx(&ctx);
}
