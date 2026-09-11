#include "abbstools/common.h"
#include "abbstools/abbs_user.h"

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

static void emit_info(const struct AbtUserInfo *info)
{
    abt_puts("STATUS=OK\n");
    abt_puts("NAME="); abt_puts(info->name); abt_puts("\n");
    abt_puts("USER_NR="); abt_put_u32(info->user_nr); abt_puts("\n");
    abt_puts("RECORD_SIZE="); abt_put_u32(info->record_size); abt_puts("\n");
}

int main(int argc, char **argv)
{
    struct AbtUserInfo info;
    int rc;

#ifdef ABBSTOOLS_CI_TRACE
    ULONG user_nr, record_size;
    if (argc != 4 || !parse_u32(argv[2], &user_nr) || !parse_u32(argv[3], &record_size)) {
        abt_puts("Usage: UserInfo USER USER_NR RECORD_SIZE\n");
        return ABBSTOOLS_RC_ERROR;
    }
    info.user_nr = user_nr;
    info.record_size = record_size;
    info.abbs_error = 0;
    {
        ULONG i = 0;
        while (i + 1 < ABBSTOOLS_USER_NAME_LEN && argv[1][i] != 0) {
            info.name[i] = argv[1][i];
            ++i;
        }
        info.name[i] = 0;
    }
    emit_info(&info);
    return ABBSTOOLS_RC_OK;
#else
    (void)parse_u32;
    if (argc != 2) {
        abt_puts("Usage: UserInfo USER\n");
        return ABBSTOOLS_RC_ERROR;
    }

    rc = abt_abbs_user_query_name(argv[1], &info);
    if (rc == ABBSTOOLS_USER_OK) {
        emit_info(&info);
        return ABBSTOOLS_RC_OK;
    }

    if (rc == ABBSTOOLS_USER_NOT_FOUND) {
        abt_puts("STATUS=NOT_FOUND\nABBS_ERROR="); abt_put_u32(info.abbs_error); abt_puts("\n");
        return ABBSTOOLS_RC_WARN;
    }
    if (rc == ABBSTOOLS_USER_NO_PORT) {
        abt_puts("STATUS=UNAVAILABLE\nREASON=ABBS_MAIN_PORT_NOT_PRESENT\n");
        return ABBSTOOLS_RC_WARN;
    }
    if (rc == ABBSTOOLS_USER_BAD_CONFIG) {
        abt_puts("STATUS=ERROR\nREASON=INVALID_USER_RECORD_SIZE\n");
        return ABBSTOOLS_RC_ERROR;
    }
    if (rc == ABBSTOOLS_USER_NO_MEMORY) {
        abt_puts("STATUS=FATAL\nREASON=NO_MEMORY\n");
        return ABBSTOOLS_RC_FATAL;
    }

    abt_puts("STATUS=ERROR\nREASON=ABBS_REQUEST_FAILED\nABBS_ERROR=");
    abt_put_u32(info.abbs_error);
    abt_puts("\n");
    return ABBSTOOLS_RC_ERROR;
#endif
}
