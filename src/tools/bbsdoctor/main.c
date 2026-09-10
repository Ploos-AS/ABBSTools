#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/abbs.h"
#include "abbstools/common.h"

#ifdef ABBSTOOLS_CI_TRACE
extern int abt_abbs_node_query_trace(ULONG node, struct AbtNodeInfo *info, const char *log_path);
#endif

static UBYTE path_present(const char *path)
{
    BPTR lock = Lock((STRPTR)path, ACCESS_READ);
    if (!lock) {
        return 0;
    }
    UnLock(lock);
    return 1;
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
    if (state == ABBSTOOLS_SESSION_ACTIVE) return "ACTIVE";
    if (state == ABBSTOOLS_SESSION_IDLE) return "IDLE";
    return "UNKNOWN";
}

int main(int argc, char **argv)
{
    const char *bbs_path = "BBS:";
    const char *abbs_path = "ABBS:";
    const char *log_path = 0;
    struct AbtNodeInfo info;
    ULONG node;
    UBYTE bbs_present;
    UBYTE abbs_present;
    int query_rc;
    int overall_rc = ABBSTOOLS_RC_OK;
    const char *health = "OK";
    const char *reason = "NONE";

#ifdef ABBSTOOLS_CI_TRACE
    if (argc != 5) {
        abt_puts("Usage: BBSDoctor NODE BBS_PATH ABBS_PATH LOG_PATH\n");
        return ABBSTOOLS_RC_ERROR;
    }
    bbs_path = argv[2];
    abbs_path = argv[3];
    log_path = argv[4];
#else
    if (argc != 2) {
        abt_puts("Usage: BBSDoctor NODE\n");
        return ABBSTOOLS_RC_ERROR;
    }
#endif

    if (!parse_node(argv[1], &node)) {
        return ABBSTOOLS_RC_ERROR;
    }

    bbs_present = path_present(bbs_path);
    abbs_present = path_present(abbs_path);

#ifdef ABBSTOOLS_CI_TRACE
    query_rc = abt_abbs_node_query_trace(node, &info, log_path);
#else
    query_rc = abt_abbs_node_query(node, &info);
#endif

    if (!bbs_present && !abbs_present) {
        health = "WARN";
        reason = "BBS_AND_ABBS_NOT_PRESENT";
        overall_rc = ABBSTOOLS_RC_WARN;
    } else if (!bbs_present) {
        health = "WARN";
        reason = "BBS_NOT_PRESENT";
        overall_rc = ABBSTOOLS_RC_WARN;
    } else if (!abbs_present) {
        health = "WARN";
        reason = "ABBS_NOT_PRESENT";
        overall_rc = ABBSTOOLS_RC_WARN;
    } else if (query_rc == ABBSTOOLS_ABBS_INTERFACE_UNQUALIFIED) {
        health = "WARN";
        reason = "ABBS_INTERFACE_NOT_QUALIFIED";
        overall_rc = ABBSTOOLS_RC_WARN;
    } else if (query_rc != ABBSTOOLS_RC_OK || !info.available) {
        health = "ERROR";
        reason = "NODE_QUERY_FAILED";
        overall_rc = ABBSTOOLS_RC_ERROR;
    } else if (!info.port_present) {
        health = "WARN";
        reason = "PORT_NOT_PRESENT";
        overall_rc = ABBSTOOLS_RC_WARN;
    } else if (!info.log_present) {
        health = "WARN";
        reason = "LOG_NOT_PRESENT";
        overall_rc = ABBSTOOLS_RC_WARN;
    } else if (info.session_state == ABBSTOOLS_SESSION_UNKNOWN) {
        health = "WARN";
        reason = "SESSION_UNKNOWN";
        overall_rc = ABBSTOOLS_RC_WARN;
    }

    abt_puts("HEALTH="); abt_puts(health); abt_puts("\n");
    abt_puts("REASON="); abt_puts(reason); abt_puts("\n");
    abt_puts("BBS_PRESENT="); abt_put_u32((ULONG)bbs_present); abt_puts("\n");
    abt_puts("ABBS_PRESENT="); abt_put_u32((ULONG)abbs_present); abt_puts("\n");
    abt_puts("NODE="); abt_put_u32(node); abt_puts("\n");

    if (query_rc == ABBSTOOLS_RC_OK && info.available) {
        abt_puts("PRESENT="); abt_put_u32((ULONG)info.port_present); abt_puts("\n");
        abt_puts("STATE="); abt_puts(info.state); abt_puts("\n");
        abt_puts("LOG_PRESENT="); abt_put_u32((ULONG)info.log_present); abt_puts("\n");
        abt_puts("SESSION="); abt_puts(session_name(info.session_state)); abt_puts("\n");
        abt_puts("USER="); abt_puts(info.user); abt_puts("\n");
    } else {
        abt_puts("PRESENT=0\nSTATE=UNKNOWN\nLOG_PRESENT=0\nSESSION=UNKNOWN\nUSER=\n");
    }

    return overall_rc;
}
