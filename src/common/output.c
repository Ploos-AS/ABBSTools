#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/common.h"

static BPTR abt_stdout(void)
{
    return Output();
}

void abt_puts(const char *text)
{
    const char *p = text;
    LONG len = 0;

    while (*p++) {
        ++len;
    }

    if (len > 0) {
        Write(abt_stdout(), (APTR)text, len);
    }
}

void abt_put_u32(ULONG value)
{
    char buf[11];
    int i = 10;

    buf[i] = '\0';
    do {
        buf[--i] = (char)('0' + (value % 10));
        value /= 10;
    } while (value != 0);

    abt_puts(&buf[i]);
}
