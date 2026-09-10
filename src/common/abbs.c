#include <dos/dos.h>
#include <exec/ports.h>
#include <proto/dos.h>
#include <proto/exec.h>

#include "abbstools/abbs.h"

#ifdef ABBSTOOLS_CI_TRACE
static void trace_stage(const char *name)
{
    char path[96];
    ULONG i = 0;
    ULONG p = 0;
    BPTR fh;

    while ("SYS:abbstools-nodeinfo-internal-"[i] != 0 && p + 1 < sizeof(path)) {
        path[p++] = "SYS:abbstools-nodeinfo-internal-"[i++];
    }
    i = 0;
    while (name[i] != 0 && p + 5 < sizeof(path)) {
        path[p++] = name[i++];
    }
    path[p++] = '.';
    path[p++] = 't';
    path[p++] = 'x';
    path[p++] = 't';
    path[p] = 0;

    fh = Open((STRPTR)path, MODE_NEWFILE);
    if (fh != 0) {
        static const char marker[] = "1\n";
        Write(fh, (APTR)marker, 2);
        Close(fh);
    }
}
#else
#define trace_stage(name) ((void)0)
#endif

static void copy_text(char *dst, ULONG size, const char *src)
{
    ULONG i = 0;

    if (size == 0) {
        return;
    }

    while (src[i] != 0 && i + 1 < size) {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = 0;
}

static int append_u32(ULONG value, char *dst, ULONG size, ULONG *pos)
{
    char digits[10];
    ULONG count = 0;
    ULONG i;

    do {
        if (count >= sizeof(digits)) {
            return 0;
        }
        digits[count++] = (char)('0' + (value % 10));
        value /= 10;
    } while (value != 0);

    for (i = 0; i < count; ++i) {
        if (*pos + 1 >= size) {
            return 0;
        }
        dst[(*pos)++] = digits[count - i - 1];
    }
    return 1;
}

static int append_text(const char *src, char *dst, ULONG size, ULONG *pos)
{
    ULONG i = 0;

    while (src[i] != 0) {
        if (*pos + 1 >= size) {
            return 0;
        }
        dst[(*pos)++] = src[i++];
    }
    return 1;
}

static int build_node_port(ULONG node, char *dst, ULONG size)
{
    ULONG pos = 0;

    if (node == 0 || size == 0 ||
        !append_text("ABBS node #", dst, size, &pos) ||
        !append_u32(node, dst, size, &pos) ||
        !append_text(" port", dst, size, &pos)) {
        return 0;
    }

    dst[pos] = 0;
    return 1;
}

static int build_node_log(ULONG node, char *dst, ULONG size)
{
    ULONG pos = 0;

    if (node == 0 || size == 0 ||
        !append_text("ABBS:node", dst, size, &pos) ||
        !append_u32(node, dst, size, &pos) ||
        !append_text("logfile", dst, size, &pos)) {
        return 0;
    }

    dst[pos] = 0;
    return 1;
}

static const char *find_text(const char *text, const char *needle)
{
    ULONG i;
    ULONG j;

    for (i = 0; text[i] != 0; ++i) {
        for (j = 0; needle[j] != 0; ++j) {
            if (text[i + j] == 0 || text[i + j] != needle[j]) {
                break;
            }
        }
        if (needle[j] == 0) {
            return text + i;
        }
    }
    return 0;
}

static void copy_field(char *dst, ULONG size, const char *start, const char *end)
{
    ULONG len = 0;

    while (start < end && (*start == ' ' || *start == '\t')) {
        ++start;
    }
    while (end > start &&
           (end[-1] == ' ' || end[-1] == '\t' || end[-1] == '\r' || end[-1] == '\n')) {
        --end;
    }

    while (start < end && len + 1 < size) {
        dst[len++] = *start++;
    }
    if (size != 0) {
        dst[len] = 0;
    }
}

static void parse_session_line(const char *line, struct AbtNodeInfo *info, UBYTE *saw_event)
{
    const char *marker;
    const char *start;
    const char *end;

    marker = find_text(line, " Login: ");
    if (marker != 0) {
        start = marker + 8;
        end = start;
        while (*end != 0 && *end != '\r' && *end != '\n') {
            ++end;
        }

        marker = find_text(start, " (");
        if (marker != 0 && marker < end) {
            end = marker;
        }

        copy_field(info->user, sizeof(info->user), start, end);
        if (info->user[0] != 0) {
            info->session_state = ABBSTOOLS_SESSION_ACTIVE;
            *saw_event = 1;
        }
        return;
    }

    marker = find_text(line, " Logout: ");
    if (marker != 0) {
        info->user[0] = 0;
        info->session_state = ABBSTOOLS_SESSION_IDLE;
        *saw_event = 1;
    }
}

static void read_node_session(struct AbtNodeInfo *info)
{
    BPTR fh;
    char line[256];
    char ch;
    LONG got;
    ULONG len = 0;
    UBYTE saw_event = 0;

    info->log_present = 0;
    info->session_state = ABBSTOOLS_SESSION_UNKNOWN;
    info->user[0] = 0;

    trace_stage("before-open");
    fh = Open((STRPTR)info->log, MODE_OLDFILE);
    trace_stage("after-open");
    if (fh == 0) {
        return;
    }

    info->log_present = 1;
    trace_stage("before-read");
    while ((got = Read(fh, &ch, 1)) == 1) {
        if (ch == '\n' || len + 1 >= sizeof(line)) {
            line[len] = 0;
            parse_session_line(line, info, &saw_event);
            len = 0;
            if (ch != '\n' && len + 1 < sizeof(line)) {
                line[len++] = ch;
            }
        } else if (ch != '\r') {
            line[len++] = ch;
        }
    }
    trace_stage("after-read");

    if (len != 0) {
        line[len] = 0;
        parse_session_line(line, info, &saw_event);
    }
    trace_stage("before-close");
    Close(fh);
    trace_stage("after-close");

    if (!saw_event) {
        info->session_state = ABBSTOOLS_SESSION_UNKNOWN;
        info->user[0] = 0;
    }
}

static int node_query_impl(ULONG node, struct AbtNodeInfo *info, const char *log_override)
{
    struct MsgPort *port;

    trace_stage("query-enter");
    if (info == 0 ||
        !build_node_port(node, info->port, sizeof(info->port)) ||
        !build_node_log(node, info->log, sizeof(info->log))) {
        return ABBSTOOLS_ABBS_INTERFACE_UNQUALIFIED;
    }
    if (log_override != 0 && log_override[0] != 0) {
        copy_text(info->log, sizeof(info->log), log_override);
    }
    trace_stage("paths-built");

    info->node = node;
    info->available = 1;
    info->port_present = 0;

    trace_stage("before-forbid");
    Forbid();
    trace_stage("after-forbid");
    port = FindPort((STRPTR)info->port);
    trace_stage("after-findport");
    if (port != 0) {
        info->port_present = 1;
    }
    Permit();
    trace_stage("after-permit");

    if (info->port_present) {
        copy_text(info->state, sizeof(info->state), "ONLINE");
    } else {
        copy_text(info->state, sizeof(info->state), "OFFLINE");
    }
    trace_stage("before-session");

    read_node_session(info);
    trace_stage("query-exit");
    return 0;
}

int abt_abbs_node_query(ULONG node, struct AbtNodeInfo *info)
{
    return node_query_impl(node, info, 0);
}

#ifdef ABBSTOOLS_CI_TRACE
int abt_abbs_node_query_trace(ULONG node, struct AbtNodeInfo *info, const char *log_path)
{
    return node_query_impl(node, info, log_path);
}
#endif
