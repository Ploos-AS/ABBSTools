#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/common.h"

#define MAX_NODE 32

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

static int contains_event(const char *line, const char *word)
{
    const char *p = line;
    ULONG i;
    while (*p) {
        i = 0;
        while (word[i] && p[i] == word[i]) ++i;
        if (!word[i]) return 1;
        ++p;
    }
    return 0;
}

#ifndef ABBSTOOLS_CI_TRACE
static int append_u32(char *dst, ULONG size, ULONG *pos, ULONG v)
{
    char tmp[10];
    ULONG n = 0, i;
    do {
        tmp[n++] = (char)('0' + (v % 10UL));
        v /= 10UL;
    } while (v && n < sizeof(tmp));
    for (i = 0; i < n; ++i) {
        if (*pos + 1 >= size) return 0;
        dst[(*pos)++] = tmp[n - i - 1];
    }
    return 1;
}

static int build_path(char *dst, ULONG size, ULONG node)
{
    const char *prefix = "ABBS:node";
    const char *suffix = "logfile";
    ULONG pos = 0, i;
    for (i = 0; prefix[i]; ++i) {
        if (pos + 1 >= size) return 0;
        dst[pos++] = prefix[i];
    }
    if (!append_u32(dst, size, &pos, node)) return 0;
    for (i = 0; suffix[i]; ++i) {
        if (pos + 1 >= size) return 0;
        dst[pos++] = suffix[i];
    }
    dst[pos] = 0;
    return 1;
}
#endif

static void count_line(const char *line, ULONG *lines, ULONG *logins, ULONG *logouts)
{
    ++*lines;
    if (contains_event(line, " Login: ")) ++*logins;
    if (contains_event(line, " Logout: ")) ++*logouts;
}

int main(int argc, char **argv)
{
    ULONG node = 0, lines = 0, logins = 0, logouts = 0;
#ifndef ABBSTOOLS_CI_TRACE
    char path[128];
    const char *input_path = path;
#else
    const char *input_path;
#endif
    BPTR fh;
    char line[256], ch;
    ULONG len = 0;
    LONG got;

#ifdef ABBSTOOLS_CI_TRACE
    if (argc != 3 || !parse_u32(argv[1], 1, MAX_NODE, &node)) {
        abt_puts("Usage: LogInfo NODE LOG_PATH\n");
        return ABBSTOOLS_RC_ERROR;
    }
    input_path = argv[2];
#else
    if (argc != 2 || !parse_u32(argv[1], 1, MAX_NODE, &node)) {
        abt_puts("Usage: LogInfo NODE\n");
        return ABBSTOOLS_RC_ERROR;
    }
    if (!build_path(path, sizeof(path), node)) return ABBSTOOLS_RC_FATAL;
#endif

    abt_puts("NODE="); abt_put_u32(node); abt_puts("\n");
    abt_puts("LOG_PATH="); abt_puts(input_path); abt_puts("\n");

    fh = Open((STRPTR)input_path, MODE_OLDFILE);
    if (!fh) {
        abt_puts("LOG_PRESENT=NO\n");
        abt_puts("LINES=0\nLOGIN_RECORDS=0\nLOGOUT_RECORDS=0\n");
        return ABBSTOOLS_RC_WARN;
    }

    while ((got = Read(fh, &ch, 1)) == 1) {
        if (ch == '\n' || len + 1 >= sizeof(line)) {
            line[len] = 0;
            count_line(line, &lines, &logins, &logouts);
            len = 0;
        } else if (ch != '\r') {
            line[len++] = ch;
        }
    }
    if (len) {
        line[len] = 0;
        count_line(line, &lines, &logins, &logouts);
    }
    Close(fh);

    abt_puts("LOG_PRESENT=YES\n");
    abt_puts("LINES="); abt_put_u32(lines); abt_puts("\n");
    abt_puts("LOGIN_RECORDS="); abt_put_u32(logins); abt_puts("\n");
    abt_puts("LOGOUT_RECORDS="); abt_put_u32(logouts); abt_puts("\n");
    return ABBSTOOLS_RC_OK;
}
