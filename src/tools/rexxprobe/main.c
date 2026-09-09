#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/arexx.h"
#include "abbstools/common.h"

static void usage(void)
{
    abt_puts("RexxProbe 0.1\n");
    abt_puts("ABBSTools - Ploos AS\n\n");
    abt_puts("Usage: RexxProbe PORT COMMAND\n");
}

int main(int argc, char **argv)
{
    struct AbtRexxResult result;
    int rc;

    if (argc != 3) {
        usage();
        return ABBSTOOLS_RC_ERROR;
    }

    rc = abt_arexx_send(argv[1], argv[2], &result);

    if (rc == ABBSTOOLS_AREXX_NO_PORT) {
        abt_puts("PORT_NOT_FOUND\n");
        return ABBSTOOLS_RC_ERROR;
    }

    if (rc == ABBSTOOLS_AREXX_SETUP_ERROR) {
        abt_puts("AREXX_SETUP_ERROR\n");
        return ABBSTOOLS_RC_FATAL;
    }

    abt_puts("PORT=");
    abt_puts(argv[1]);
    abt_puts("\nCOMMAND=");
    abt_puts(argv[2]);
    abt_puts("\nRESULT1=");
    abt_put_u32((ULONG)result.primary);

    if (result.primary == 0) {
        abt_puts("\nRESULT=");
        if (result.has_text) {
            abt_puts(result.text);
        }
        abt_puts("\nTRUNCATED=");
        abt_puts(result.truncated ? "1" : "0");
    } else {
        abt_puts("\nRESULT2=");
        abt_put_u32((ULONG)result.secondary);
    }
    abt_puts("\n");

    return rc;
}
