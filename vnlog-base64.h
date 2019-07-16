#pragma once

#include <stdint.h>

// encodes the source buffer into the destination buffer. Dest buffer is
// '\0'-terminated, and the output (including '\0') will fit into dstlen bytes,
// or else failure is indicated.
//
// The number of bytes in the output (not including the trailing '\0') is
// returned on success, or <0 on error
int vnlog_base64_encode(       char* dst, int dstlen,
                         const char* src, int srclen );

static inline int vnlog_base64_dstlen_to_encode( int len )
{
    // + 1 for the trailing '\0'
    return (1 + (len-1)/3) * 4 + 1;
}
