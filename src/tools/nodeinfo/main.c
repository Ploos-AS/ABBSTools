#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/abbs.h"
#include "abbstools/common.h"

#ifdef ABBSTOOLS_CI_TRACE
extern int abt_abbs_node_query_trace(ULONG node, struct AbtNodeInfo *info, const char *log_path);
#endif

static void usage(void)
{
    abt_puts("NodeInfo 0.1\n");
    abt_puts("ABBSTools - Ploos AS\n\n");
#ifdef ABBSTOOLS_CI_TRACE
    abt_puts("Usage: NodeInfo NODE [CI_LOG_PATH]\n");
#else
    abt_puts("Usage: NodeInfo NODE\n");
#endif
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

static const char *session_name(UBYTE state)
{
    if (state == ABBSTOOLS_SESSION_ACTIVE) {
        return "ACTIVE";
    }
    if (state == ABBSTOOLS_SESSION_IDLE) {
        return "IDLE";
    }
    return "UNKNOWN";
}

int main(int argc, char **argv)
{
    struct AbtNodeInfo info;
    ULONG node;
    int rc;

#ifdef ABBSTOOLS_CI_TRACE
    if ((argc != 2 && argc != 3) || !parse_node(argv[1], &node)) {
#else
    if (argc != 2 || !parse_node(argv[1], &node)) {
#endif
        usage();
        return ABBSTOOLS_RC_ERROR;
    }

#ifdef ABBSTOOLS_CI_TRACE
    if (argc == 3) {
        rc = abt_abbs_node_query_trace(node, &info, argv[2]);
    } else {
        rc = abt_abbs_node_query(node, &info);
    }
#else
    rc = abt_abbs_node_query(node, &info);
#endif

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

    abt_puts("STATUS=OK\nPORT=");
    abt_puts(info.port);
    abt_puts("\nPRESENT=");
    abt_puts(info.port_present ? "1" : "0");
    abt_puts("\nSTATE=");
    abt_puts(info.state);
    abt_puts("\nLOG=");
    abt_puts(info.log);
    abt_puts("\nLOG_PRESENT=");
    abt_puts(info.log_present ? "1" : "0");
    abt_puts("\nSESSION=");
    abt_puts(session_name(info.session_state));
    abt_puts("\nUSER=");
    abt_puts(info.user);
    abt_puts("\n");

    return ABBSTOOLS_RC_OK;
}
