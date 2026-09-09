#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/abbs.h"
#include "abbstools/common.h"

static void usage(void)
{
    abt_puts("NodeInfo 0.1\n");
    abt_puts("ABBSTools - Ploos AS\n\n");
    abt_puts("Usage: NodeInfo NODE\n");
}

static int parse_node(const char *text, ULONG *node)
{
    ULONG value = 0;
    const char *p = text;

    if (*p == 0) {
        return 0;
    }

    while (*p != 0) {
        if (*p < '0' || *p > '9') {
            return 0;
        }
        value = value * 10 + (ULONG)(*p - '0');
        if (value > 65535UL) {
            return 0;
        }
        ++p;
    }

    if (value == 0) {
        return 0;
    }

    *node = value;
    return 1;
}

int main(int argc, char **argv)
{
    struct AbtNodeInfo info;
    ULONG node;
    int rc;

    if (argc != 2 || !parse_node(argv[1], &node)) {
        usage();
        return ABBSTOOLS_RC_ERROR;
    }

    rc = abt_abbs_node_query(node, &info);

    abt_puts("NODE=");
    abt_put_u32(node);
    abt_puts("\n");

    if (rc == ABBSTOOLS_ABBS_INTERFACE_UNQUALIFIED) {
        abt_puts("STATUS=UNAVAILABLE\n");
        abt_puts("REASON=ABBS_INTERFACE_NOT_QUALIFIED\n");
        return ABBSTOOLS_RC_WARN;
    }

    if (rc != ABBSTOOLS_RC_OK || !info.available) {
        abt_puts("STATUS=ERROR\n");
        return ABBSTOOLS_RC_ERROR;
    }

    abt_puts("STATUS=OK\nSTATE=");
    abt_puts(info.state);
    abt_puts("\nUSER=");
    abt_puts(info.user);
    abt_puts("\n");

    return ABBSTOOLS_RC_OK;
}
