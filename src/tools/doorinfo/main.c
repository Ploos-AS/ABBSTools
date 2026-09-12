#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/common.h"

static int parse_u32(const char *s, ULONG *out)
{
    ULONG v = 0;
    if (!s || !*s) return 0;
    while (*s) {
        ULONG d;
        if (*s < '0' || *s > '9') return 0;
        d = (ULONG)(*s - '0');
        if (v > (0xffffffffUL - d) / 10UL) return 0;
        v = v * 10UL + d;
        ++s;
    }
    *out = v;
    return 1;
}

static const char *type_name(LONG entry_type)
{
    if (entry_type > 0) return "DIRECTORY";
    if (entry_type < 0) return "FILE";
    return "OTHER";
}

static void emit_ok(const char *path, const char *type, ULONG size)
{
    abt_puts("STATUS=OK\nPATH=");
    abt_puts(path);
    abt_puts("\nPRESENT=YES\nTYPE=");
    abt_puts(type);
    abt_puts("\nSIZE=");
    abt_put_u32(size);
    abt_puts("\n");
}

int main(int argc, char **argv)
{
#ifdef ABBSTOOLS_CI_TRACE
    ULONG size;
    LONG entry_type;

    if (argc != 4 || !parse_u32(argv[3], &size)) {
        abt_puts("Usage: DoorInfo PATH TYPE SIZE\n");
        return ABBSTOOLS_RC_ERROR;
    }

    if (argv[2][0] == 'F' && argv[2][1] == 0) entry_type = -1;
    else if (argv[2][0] == 'D' && argv[2][1] == 0) entry_type = 1;
    else if (argv[2][0] == 'O' && argv[2][1] == 0) entry_type = 0;
    else {
        abt_puts("Usage: DoorInfo PATH TYPE SIZE\nTYPE must be F, D or O\n");
        return ABBSTOOLS_RC_ERROR;
    }

    emit_ok(argv[1], type_name(entry_type), size);
    return ABBSTOOLS_RC_OK;
#else
    BPTR lock;
    struct FileInfoBlock fib;

    (void)parse_u32;

    if (argc != 2 || argv[1][0] == 0) {
        abt_puts("Usage: DoorInfo PATH\n");
        return ABBSTOOLS_RC_ERROR;
    }

    lock = Lock((STRPTR)argv[1], ACCESS_READ);
    if (lock == 0) {
        abt_puts("STATUS=WARN\nPATH=");
        abt_puts(argv[1]);
        abt_puts("\nPRESENT=NO\nREASON=PATH_NOT_PRESENT\n");
        return ABBSTOOLS_RC_WARN;
    }

    if (!Examine(lock, &fib)) {
        UnLock(lock);
        abt_puts("STATUS=ERROR\nPATH=");
        abt_puts(argv[1]);
        abt_puts("\nPRESENT=YES\nREASON=EXAMINE_FAILED\n");
        return ABBSTOOLS_RC_ERROR;
    }

    UnLock(lock);
    emit_ok(argv[1], type_name(fib.fib_DirEntryType),
            fib.fib_Size < 0 ? 0UL : (ULONG)fib.fib_Size);
    return ABBSTOOLS_RC_OK;
#endif
}
