#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/common.h"

#define MAX_EVENTS 50
#define MAX_NODES 32

struct Event {
    char key[24];
    char user[64];
    char mode[32];
    char date[9];
    char time[6];
    ULONG node;
};

static struct Event events[MAX_EVENTS];
static ULONG event_count;

static int parse_u32(const char *s, ULONG min, ULONG max, ULONG *out)
{
    ULONG v = 0;
    if (!s || !*s) return 0;
    while (*s) {
        ULONG d;
        if (*s < '0' || *s > '9') return 0;
        d = (ULONG)(*s - '0');
        if (v > (max - d) / 10UL) return 0;
        v = v * 10UL + d;
        ++s;
    }
    if (v < min || v > max) return 0;
    *out = v;
    return 1;
}

static int textcmp(const char *a, const char *b)
{
    while (*a && *a == *b) { ++a; ++b; }
    return (int)(unsigned char)*a - (int)(unsigned char)*b;
}

static void copy_range(char *dst, ULONG size, const char *a, const char *b)
{
    ULONG n = 0;
    while (a < b && n + 1 < size) dst[n++] = *a++;
    dst[n] = 0;
}

static int valid_pair(char a, char b, ULONG max)
{
    ULONG v;
    if (a < '0' || a > '9' || b < '0' || b > '9') return 0;
    v = (ULONG)(a - '0') * 10UL + (ULONG)(b - '0');
    return v <= max;
}

static int parse_login(const char *line, ULONG node, struct Event *e)
{
    const char *p = line;
    const char *user;
    const char *mode;
    const char *end;
    ULONG i;

    while (*p == ' ' || *p == '\t') ++p;
    if (!(valid_pair(p[0], p[1], 23) && p[2] == ':' && valid_pair(p[3], p[4], 59))) return 0;
    copy_range(e->time, sizeof(e->time), p, p + 5);
    p += 5;
    while (*p == ' ') ++p;
    if (!(valid_pair(p[0], p[1], 31) && p[2] == '/' && valid_pair(p[3], p[4], 12) && p[5] == '-' &&
          p[6] >= '0' && p[6] <= '9' && p[7] >= '0' && p[7] <= '9')) return 0;
    if (p[0] == '0' && p[1] == '0') return 0;
    if (p[3] == '0' && p[4] == '0') return 0;
    copy_range(e->date, sizeof(e->date), p, p + 8);
    p += 8;
    while (*p == ' ') ++p;
    if (!(p[0]=='L'&&p[1]=='o'&&p[2]=='g'&&p[3]=='i'&&p[4]=='n'&&p[5]==':'&&p[6]==' ')) return 0;
    user = p + 7;
    end = user;
    while (*end && *end != '\r' && *end != '\n') ++end;
    mode = 0;
    for (p = user; p + 1 < end; ++p) if (p[0] == ' ' && p[1] == '(') mode = p;
    if (!mode || mode == user || end <= mode + 3 || end[-1] != ')') return 0;
    copy_range(e->user, sizeof(e->user), user, mode);
    copy_range(e->mode, sizeof(e->mode), mode + 2, end - 1);
    if (!e->user[0] || !e->mode[0]) return 0;
    e->node = node;
    for (i = 0; i < 2; ++i) e->key[i] = e->date[6 + i];
    e->key[2] = e->date[3]; e->key[3] = e->date[4];
    e->key[4] = e->date[0]; e->key[5] = e->date[1];
    e->key[6] = e->time[0]; e->key[7] = e->time[1];
    e->key[8] = e->time[3]; e->key[9] = e->time[4];
    e->key[10] = (char)('0' + ((node / 10UL) % 10UL));
    e->key[11] = (char)('0' + (node % 10UL));
    e->key[12] = 0;
    return 1;
}

static void retain_event(const struct Event *e, ULONG limit)
{
    ULONG pos = 0;
    ULONG i;
    while (pos < event_count && textcmp(events[pos].key, e->key) <= 0) ++pos;
    if (event_count < limit) {
        for (i = event_count; i > pos; --i) events[i] = events[i - 1];
        events[pos] = *e;
        ++event_count;
    } else if (pos < limit) {
        for (i = 1; i < pos; ++i) events[i - 1] = events[i];
        if (pos > 0) --pos;
        for (i = event_count - 1; i > pos; --i) events[i] = events[i - 1];
        events[pos] = *e;
    }
}

static int append_u32(char *dst, ULONG size, ULONG *pos, ULONG v)
{
    char tmp[10]; ULONG n = 0, i;
    do { tmp[n++] = (char)('0' + (v % 10UL)); v /= 10UL; } while (v && n < sizeof(tmp));
    for (i = 0; i < n; ++i) { if (*pos + 1 >= size) return 0; dst[(*pos)++] = tmp[n - i - 1]; }
    return 1;
}

static int build_path(char *dst, ULONG size, const char *prefix, ULONG node)
{
    ULONG pos = 0, i = 0;
    while (prefix[i]) { if (pos + 1 >= size) return 0; dst[pos++] = prefix[i++]; }
    if (!append_u32(dst, size, &pos, node)) return 0;
    for (i = 0; "logfile"[i]; ++i) { if (pos + 1 >= size) return 0; dst[pos++] = "logfile"[i]; }
    dst[pos] = 0; return 1;
}

static void scan_log(const char *path, ULONG node, ULONG limit, ULONG *logs_found)
{
    BPTR fh = Open((STRPTR)path, MODE_OLDFILE);
    char line[256], ch; ULONG len = 0; LONG got; struct Event e;
    if (!fh) return;
    ++*logs_found;
    while ((got = Read(fh, &ch, 1)) == 1) {
        if (ch == '\n' || len + 1 >= sizeof(line)) {
            line[len] = 0;
            if (parse_login(line, node, &e)) retain_event(&e, limit);
            len = 0;
        } else if (ch != '\r') line[len++] = ch;
    }
    if (len) { line[len] = 0; if (parse_login(line, node, &e)) retain_event(&e, limit); }
    Close(fh);
}

int main(int argc, char **argv)
{
    ULONG limit = 10, max_nodes = MAX_NODES, node, logs_found = 0, i;
    const char *prefix = "ABBS:node";
    char path[128];
#ifdef ABBSTOOLS_CI_TRACE
    if (argc != 4 || !parse_u32(argv[2], 1, MAX_EVENTS, &limit) || !parse_u32(argv[3], 1, MAX_NODES, &max_nodes)) {
        abt_puts("Usage: LastCalls PREFIX COUNT MAXNODES\n"); return ABBSTOOLS_RC_ERROR;
    }
    prefix = argv[1];
#else
    if (argc > 2 || (argc == 2 && !parse_u32(argv[1], 1, MAX_EVENTS, &limit))) {
        abt_puts("Usage: LastCalls [COUNT]\n"); return ABBSTOOLS_RC_ERROR;
    }
#endif
    for (node = 1; node <= max_nodes; ++node) if (build_path(path, sizeof(path), prefix, node)) scan_log(path, node, limit, &logs_found);
    abt_puts("LOGS_FOUND="); abt_put_u32(logs_found); abt_puts("\n");
    abt_puts("CALLERS="); abt_put_u32(event_count); abt_puts("\n");
    for (i = 0; i < event_count; ++i) {
        abt_puts("CALLER INDEX="); abt_put_u32(i + 1); abt_puts(" NODE="); abt_put_u32(events[i].node);
        abt_puts(" DATE="); abt_puts(events[i].date); abt_puts(" TIME="); abt_puts(events[i].time);
        abt_puts(" MODE="); abt_puts(events[i].mode); abt_puts(" USER="); abt_puts(events[i].user); abt_puts("\n");
    }
    return ABBSTOOLS_RC_OK;
}
