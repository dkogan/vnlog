#include <string.h>

#include "asciilog_fields_generated1.h"

void test2(void);

int main()
{
    asciilog_emit_legend();

    asciilog_set_field_value__w(-10);
    asciilog_set_field_value__x(40);
    asciilog_set_field_value__y("asdf");
    asciilog_emit_record();

    asciilog_set_field_value__w(55);

    const char* str = "123\x01\x02\x03";
    asciilog_set_field_value__d(str, strlen(str));

    // we just set some fields in this record, and in the middle of filling this
    // record we write other records, and other asciilog sessions
    {
        struct asciilog_context_t ctx;
        asciilog_init_child_ctx(&ctx, NULL); // child of the global context
        for(int i=0; i<3; i++)
        {
            asciilog_set_field_value_ctx__w(&ctx, i + 5);
            asciilog_set_field_value_ctx__x(&ctx, i + 6);
            asciilog_emit_record_ctx(&ctx);
        }
        test2();
    }

    // Now we resume the previous record. We still remember that w == 55
    asciilog_set_field_value__x(77);
    asciilog_set_field_value__z(0.3);

    asciilog_emit_record();



    // Let's do it again, but the internal record should leave x blank. x is an
    // anchor, so its value that was set(), but not emitted(), should come
    // through. To make it even more interesting, I set the anchor from a
    // non-root context
    struct asciilog_context_t ctx2;
    asciilog_init_child_ctx(&ctx2, NULL); // child of the global context
    asciilog_set_field_value_ctx__x(&ctx2, 70);
    {
        struct asciilog_context_t ctx;
        asciilog_init_child_ctx(&ctx, NULL); // child of the global context
        for(int i=0; i<3; i++)
        {
            asciilog_set_field_value_ctx__w(&ctx, i + 50);
            asciilog_set_field_value_ctx__z(&ctx, (double)i + 60);
            asciilog_emit_record_ctx(&ctx);
        }
    }

    // Now we resume the previous record. We still remember that x == 70
    asciilog_set_field_value_ctx__w(&ctx2, -21);
    asciilog_set_field_value_ctx__z(&ctx2, 0.4);
    asciilog_emit_record_ctx(&ctx2);

    return 0;
}
