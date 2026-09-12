#include <dos/dos.h>
#include <proto/dos.h>

#include "abbstools/common.h"

static const char *type_name(LONG entry_type)
{
    if (entry_type > 0) return "DIRECTORY";
    if (entry_type < 0) return "FILE";
    return "OTHER";
}

static int valid_expected_type(const char *s)
{
    return abt_streq(s, "FILE") || abt_streq(s, "DIRECTORY") || abt_streq(s, "ANY");
}

static int matches_expected(const char *expected, const char *actual)
{
    if (abt_streq(expected, "ANY")) return 1;
    return abt_streq(expected, actual);
}

static void emit_common(const char *status, const char *path, int present,
                        const char *expected, const char *actual,
                        const char *result)
{
    abt_puts("STATUS=");
    abt_puts(status);
    abt_puts("\nPATH=");
    abt_puts(path);
    abt_puts("\nPRESENT=");
    abt_puts(present ? "YES" : "NO");
    abt_puts("\nEXPECTED_TYPE=");
    abt_puts(expected);
    if (actual) {
        abt_puts("\nACTUAL_TYPE=");
        abt_puts(actual);
    }
    abt_puts("\nRESULT=");
    abt_puts(result);
    abt_puts("\n");
}

int main(int argc, char **argv)
{
    BPTR lock;
    struct FileInfoBlock fib;
    const char *actual;

    if (argc != 3 || argv[1][0] == 0 || !valid_expected_type(argv[2])) {
        abt_puts("Usage: DoorCheck PATH FILE|DIRECTORY|ANY\n");
        return ABBSTOOLS_RC_ERROR;
    }

    lock = Lock((STRPTR)argv[1], ACCESS_READ);
    if (lock == 0) {
        emit_common("WARN", argv[1], 0, argv[2], 0, "PATH_NOT_PRESENT");
        return ABBSTOOLS_RC_WARN;
    }

    if (!Examine(lock, &fib)) {
        UnLock(lock);
        emit_common("ERROR", argv[1], 1, argv[2], 0, "EXAMINE_FAILED");
        return ABBSTOOLS_RC_ERROR;
    }

    UnLock(lock);
    actual = type_name(fib.fib_DirEntryType);

    if (!matches_expected(argv[2], actual)) {
        emit_common("WARN", argv[1], 1, argv[2], actual, "TYPE_MISMATCH");
        return ABBSTOOLS_RC_WARN;
    }

    emit_common("OK", argv[1], 1, argv[2], actual, "MATCH");
    return ABBSTOOLS_RC_OK;
}
