#include <dos/dos.h>

#include "abbstools/abbs.h"
#include "abbstools/common.h"

#ifdef ABBSTOOLS_CI_TRACE
extern int abt_abbs_node_query_trace(ULONG node, struct AbtNodeInfo *info, const char *log_path);
#endif

static void usage(void)
{
    abt_puts("NodeCheck 0.1\n");
    abt_puts("ABBSTools - Ploos AS\n\n");
#ifdef ABBSTOOLS_CI_TRACE
    abt_puts("Usage: NodeCheck NODE [CI_LOG_PATH]\n");
#else
    abt_puts("Usage: NodeCheck NODE\n");
#endif
}

static int parse_node(const char *text, ULONG *value_out)
{
    ULONG value = 0;
    const char *p = text;

    if (*p == 0) {
        return 0;
    }

    while (*p != 0) {
        ULONG digit;
        if (*p < '0' || *p > '9') {
            return 0;
        }
        digit = (ULONG)(*p - '0');
        if (value > (65535UL - digit) / 10UL) {
            return 0;
        }
        value = value * 10UL + digit;
        ++p;
    }

    if (value < 1 || value > 65535UL) {
        return 0;
    }

    *value_out = value;
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

static void print_result(const struct AbtNodeInfo *info, const char *health, const char *reason)
{
    abt_puts("NODE=");
    abt_put_u32(info->node);
    abt_puts(" HEALTH=");
    abt_puts(health);
    abt_puts(" REASON=");
    abt_puts(reason);
    abt_puts(" PRESENT=");
    abt_puts(info->port_present ? "1" : "0");
    abt_puts(" STATE=");
    abt_puts(info->state);
    abt_puts(" LOG_PRESENT=");
    abt_puts(info->log_present ? "1" : "0");
    abt_puts(" SESSION=");
    abt_puts(session_name(info->session_state));
    abt_puts(" USER=");
    abt_puts(info->user);
    abt_puts("\n");
}

int main(int argc, char **argv)
{
    struct AbtNodeInfo info;
    ULONG node;
    int rc;
#ifdef ABBSTOOLS_CI_TRACE
    const char *log_path = 0;

    if (argc < 2 || argc > 3) {
        usage();
        return ABBSTOOLS_RC_ERROR;
    }
#else
    if (argc != 2) {
        usage();
        return ABBSTOOLS_RC_ERROR;
    }
#endif

    if (!parse_node(argv[1], &node)) {
        usage();
        return ABBSTOOLS_RC_ERROR;
    }

#ifdef ABBSTOOLS_CI_TRACE
    if (argc == 3) {
        log_path = argv[2];
    }
    if (log_path != 0) {
        rc = abt_abbs_node_query_trace(node, &info, log_path);
    } else {
        rc = abt_abbs_node_query(node, &info);
    }
#else
    rc = abt_abbs_node_query(node, &info);
#endif

    if (rc == ABBSTOOLS_ABBS_INTERFACE_UNQUALIFIED) {
        abt_puts("STATUS=UNAVAILABLE REASON=ABBS_INTERFACE_NOT_QUALIFIED\n");
        return ABBSTOOLS_RC_WARN;
    }
    if (rc != ABBSTOOLS_RC_OK || !info.available) {
        abt_puts("STATUS=ERROR REASON=NODE_QUERY_FAILED\n");
        return ABBSTOOLS_RC_ERROR;
    }

    if (!info.port_present) {
        print_result(&info, "WARN", "PORT_NOT_PRESENT");
        return ABBSTOOLS_RC_WARN;
    }
    if (!info.log_present) {
        print_result(&info, "WARN", "LOG_NOT_PRESENT");
        return ABBSTOOLS_RC_WARN;
    }
    if (info.session_state == ABBSTOOLS_SESSION_UNKNOWN) {
        print_result(&info, "WARN", "SESSION_UNKNOWN");
        return ABBSTOOLS_RC_WARN;
    }

    print_result(&info, "OK", "NONE");
    return ABBSTOOLS_RC_OK;
}
