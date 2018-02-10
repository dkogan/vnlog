#include <string.h>

#include "vnlog_fields_generated1.h"

void test2(void);

int main()
{
    vnlog_emit_legend();

    vnlog_set_field_value__w(-10);
    vnlog_set_field_value__x(40);
    vnlog_set_field_value__y("asdf");
    vnlog_emit_record();

    vnlog_set_field_value__w(55);

    const char* str = "123\x01\x02\x03";
    vnlog_set_field_value__d(str, strlen(str));

    // we just set some fields in this record, and in the middle of filling this
    // record we write other records, and other vnlog sessions
    {
        struct vnlog_context_t ctx;
        vnlog_init_child_ctx(&ctx, NULL); // child of the global context
        for(int i=0; i<3; i++)
        {
            vnlog_set_field_value_ctx__w(&ctx, i + 5);
            vnlog_set_field_value_ctx__x(&ctx, i + 6);
            vnlog_emit_record_ctx(&ctx);
        }
        vnlog_free_ctx(&ctx);
        test2();
    }

    // Now we resume the previous record. We still remember that w == 55
    vnlog_set_field_value__x(77);
    vnlog_set_field_value__z(0.3);

    vnlog_emit_record();

    return 0;
}
