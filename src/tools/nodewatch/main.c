#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/abbs.h"
#include "abbstools/common.h"

#ifdef ABBSTOOLS_CI_TRACE
extern int abt_abbs_node_query_trace(ULONG node, struct AbtNodeInfo *info, const char *log_path);
#endif

static void usage(void)
{
    abt_puts("NodeWatch 0.1\n");
    abt_puts("ABBSTools - Ploos AS\n\n");
#ifdef ABBSTOOLS_CI_TRACE
    abt_puts("Usage: NodeWatch NODE [INTERVAL [COUNT [CI_LOG_PATH]]]\n");
#else
    abt_puts("Usage: NodeWatch NODE [INTERVAL [COUNT]]\n");
#endif
    abt_puts("INTERVAL is seconds (1-3600), default 5. COUNT 0 means continuous, default 0.\n");
}

static int parse_u32(const char *text, ULONG min, ULONG max, ULONG *value_out)
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
        if (value > (max - digit) / 10UL) {
            return 0;
        }
        value = value * 10UL + digit;
        ++p;
    }

    if (value < min || value > max) {
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

static void print_sample(ULONG sample, const struct AbtNodeInfo *info)
{
    abt_puts("SAMPLE=");
    abt_put_u32(sample);
    abt_puts(" NODE=");
    abt_put_u32(info->node);
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
    ULONG interval = 5;
    ULONG count = 0;
    ULONG sample = 1;
    int rc;
#ifdef ABBSTOOLS_CI_TRACE
    const char *log_path = 0;

    if (argc < 2 || argc > 5) {
        usage();
        return ABBSTOOLS_RC_ERROR;
    }
#else
    if (argc < 2 || argc > 4) {
        usage();
        return ABBSTOOLS_RC_ERROR;
    }
#endif

    if (!parse_u32(argv[1], 1, 65535UL, &node) ||
        (argc >= 3 && !parse_u32(argv[2], 1, 3600UL, &interval)) ||
        (argc >= 4 && !parse_u32(argv[3], 0, 65535UL, &count))) {
        usage();
        return ABBSTOOLS_RC_ERROR;
    }

#ifdef ABBSTOOLS_CI_TRACE
    if (argc == 5) {
        log_path = argv[4];
    }
#endif

    for (;;) {
#ifdef ABBSTOOLS_CI_TRACE
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
            abt_puts("STATUS=ERROR\n");
            return ABBSTOOLS_RC_ERROR;
        }

        print_sample(sample, &info);

        if (count != 0 && sample >= count) {
            break;
        }

        Delay(interval * TICKS_PER_SECOND);
        ++sample;
    }

    return ABBSTOOLS_RC_OK;
}
