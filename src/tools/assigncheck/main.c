#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/common.h"

static UBYTE path_present(const char *path)
{
    BPTR lock = Lock((STRPTR)path, ACCESS_READ);

    if (!lock) {
        return 0;
    }

    UnLock(lock);
    return 1;
}

int main(int argc, char **argv)
{
    UBYTE bbs_present;
    UBYTE abbs_present;

    (void)argv;

    if (argc != 1) {
        abt_puts("Usage: AssignCheck\n");
        return ABBSTOOLS_RC_ERROR;
    }

    bbs_present = path_present("BBS:");
    abbs_present = path_present("ABBS:");

    abt_puts("BBS=BBS:\n");
    abt_puts("BBS_PRESENT=");
    abt_put_u32((ULONG)bbs_present);
    abt_puts("\n");
    abt_puts("ABBS=ABBS:\n");
    abt_puts("ABBS_PRESENT=");
    abt_put_u32((ULONG)abbs_present);
    abt_puts("\n");

    if (bbs_present && abbs_present) {
        abt_puts("HEALTH=OK\n");
        abt_puts("REASON=NONE\n");
        return ABBSTOOLS_RC_OK;
    }

    abt_puts("HEALTH=WARN\n");
    if (!bbs_present && !abbs_present) {
        abt_puts("REASON=BBS_AND_ABBS_NOT_PRESENT\n");
    } else if (!bbs_present) {
        abt_puts("REASON=BBS_NOT_PRESENT\n");
    } else {
        abt_puts("REASON=ABBS_NOT_PRESENT\n");
    }

    return ABBSTOOLS_RC_WARN;
}
