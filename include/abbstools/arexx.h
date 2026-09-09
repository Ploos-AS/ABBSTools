#ifndef ABBSTOOLS_AREXX_H
#define ABBSTOOLS_AREXX_H

#include <exec/types.h>

#define ABBSTOOLS_AREXX_NO_PORT 10
#define ABBSTOOLS_AREXX_SETUP_ERROR 20
#define ABBSTOOLS_AREXX_RESULT_LEN 256

struct AbtRexxResult {
    LONG primary;
    LONG secondary;
    UBYTE has_text;
    UBYTE truncated;
    char text[ABBSTOOLS_AREXX_RESULT_LEN];
};

int abt_arexx_send(const char *port_name,
                   const char *command,
                   struct AbtRexxResult *result);

#endif
