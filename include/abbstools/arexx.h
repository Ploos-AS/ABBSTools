#ifndef ABBSTOOLS_AREXX_H
#define ABBSTOOLS_AREXX_H

#include <exec/types.h>

#define ABBSTOOLS_AREXX_NO_PORT 10
#define ABBSTOOLS_AREXX_SETUP_ERROR 20

struct AbtRexxResult {
    LONG primary;
    LONG secondary;
};

int abt_arexx_send(const char *port_name,
                   const char *command,
                   struct AbtRexxResult *result);

#endif
