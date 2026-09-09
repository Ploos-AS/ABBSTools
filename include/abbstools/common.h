#ifndef ABBSTOOLS_COMMON_H
#define ABBSTOOLS_COMMON_H

#include <exec/types.h>

#define ABBSTOOLS_VERSION_MAJOR 0
#define ABBSTOOLS_VERSION_MINOR 1

#define ABBSTOOLS_RC_OK 0
#define ABBSTOOLS_RC_WARN 5
#define ABBSTOOLS_RC_ERROR 10
#define ABBSTOOLS_RC_FATAL 20

#define ABBSTOOLS_AREXX_PREFIX "ABBSTOOLS."

void abt_puts(const char *text);
void abt_put_u32(ULONG value);

#endif
