// Need to make this with
//
//    asciilog-gen-header 'int w' 'uint8_t x' 'char* y' 'double z' > asciilog_fields_generated.h
#include "asciilog_fields_generated.h"

int main()
{
    asciilog_emit_legend();

    asciilog_set_field_value__w(-10);
    asciilog_set_field_value__x(40);
    asciilog_set_field_value__y("asdf");
    asciilog_emit_record();

    asciilog_set_field_value__x(50);
    asciilog_set_field_value__w(-20);
    asciilog_set_field_value__z(0.3);
    asciilog_emit_record();


    return 0;
}
