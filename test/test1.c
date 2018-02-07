#include <string.h>

#include "vanillog_fields_generated1.h"

void test2(void);

int main()
{
    vanillog_emit_legend();

    vanillog_set_field_value__w(-10);
    vanillog_set_field_value__x(40);
    vanillog_set_field_value__y("asdf");
    vanillog_emit_record();

    vanillog_set_field_value__w(55);

    const char* str = "123\x01\x02\x03";
    vanillog_set_field_value__d(str, strlen(str));

    // we just set some fields in this record, and in the middle of filling this
    // record we write other records, and other vanillog sessions
    {
        struct vanillog_context_t ctx;
        vanillog_init_child_ctx(&ctx, NULL); // child of the global context
        for(int i=0; i<3; i++)
        {
            vanillog_set_field_value_ctx__w(&ctx, i + 5);
            vanillog_set_field_value_ctx__x(&ctx, i + 6);
            vanillog_emit_record_ctx(&ctx);
        }
        vanillog_free_ctx(&ctx);
        test2();
    }

    // Now we resume the previous record. We still remember that w == 55
    vanillog_set_field_value__x(77);
    vanillog_set_field_value__z(0.3);

    vanillog_emit_record();

    return 0;
}
