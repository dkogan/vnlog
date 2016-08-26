#include <stdio.h>
#include <stdlib.h>

#include "asciilog_generated.h"

int main()
{
    asciilog_emit_legend();

    asciilog_set_field_value__w(-10);
    asciilog_set_field_value__x(40);
    asciilog_set_field_value__y("asdf");
    asciilog_emit_and_finish_record();

    asciilog_set_field_value__x(50);
    asciilog_set_field_value__w(-20);
    asciilog_set_field_value__z(0.3);
    asciilog_emit_and_finish_record();


    return 0;
}
