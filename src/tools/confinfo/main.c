#include "abbstools/common.h"
#include "abbstools/abbs_conf.h"

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

static void emit_info(const struct AbtConfInfo *info)
{
    abt_puts("STATUS=OK\n");
    abt_puts("CONFERENCE="); abt_put_u32(info->conference); abt_puts("\n");
    abt_puts("NAME="); abt_puts(info->name); abt_puts("\n");
    abt_puts("ORDER="); abt_put_u32(info->order); abt_puts("\n");
    abt_puts("DEFAULT_MSG="); abt_put_u32(info->default_msg); abt_puts("\n");
    abt_puts("FIRST_MSG="); abt_put_u32(info->first_msg); abt_puts("\n");
    abt_puts("BULLETS="); abt_put_u32(info->bullets); abt_puts("\n");
    abt_puts("MAX_SCAN="); abt_put_u32(info->max_scan); abt_puts("\n");
    abt_puts("SWITCHES="); abt_put_u32(info->switches); abt_puts("\n");
    abt_puts("MAX_CONFERENCES="); abt_put_u32(info->max_conferences); abt_puts("\n");
}

int main(int argc, char **argv)
{
    struct AbtConfInfo info;
    ULONG conference;

#ifdef ABBSTOOLS_CI_TRACE
    ULONG order, default_msg, first_msg, bullets, max_scan, switches, max_confs;
    if (argc != 10 || !parse_u32(argv[1], &conference) || !parse_u32(argv[3], &order)
        || !parse_u32(argv[4], &default_msg) || !parse_u32(argv[5], &first_msg)
        || !parse_u32(argv[6], &bullets) || !parse_u32(argv[7], &max_scan)
        || !parse_u32(argv[8], &switches) || !parse_u32(argv[9], &max_confs)) {
        abt_puts("Usage: ConfInfo CONFERENCE NAME ORDER DEFAULT_MSG FIRST_MSG BULLETS MAX_SCAN SWITCHES MAX_CONFERENCES\n");
        return ABBSTOOLS_RC_ERROR;
    }
    info.conference = (UWORD)conference;
    info.order = (UWORD)order;
    info.default_msg = default_msg;
    info.first_msg = first_msg;
    info.bullets = (UBYTE)bullets;
    info.max_scan = (UWORD)max_scan;
    info.switches = (UWORD)switches;
    info.max_conferences = (UWORD)max_confs;
    info.abbs_error = 0;
    {
        ULONG i = 0;
        while (i + 1 < ABBSTOOLS_CONF_NAME_LEN && argv[2][i] != 0) {
            info.name[i] = argv[2][i];
            ++i;
        }
        info.name[i] = 0;
    }
    emit_info(&info);
    return ABBSTOOLS_RC_OK;
#else
    int rc;
    if (argc != 2 || !parse_u32(argv[1], &conference) || conference == 0 || conference > ABBSTOOLS_CONF_MAX) {
        abt_puts("Usage: ConfInfo CONFERENCE\n");
        return ABBSTOOLS_RC_ERROR;
    }

    rc = abt_abbs_conf_query(conference, &info);
    if (rc == ABBSTOOLS_CONF_OK) {
        emit_info(&info);
        return ABBSTOOLS_RC_OK;
    }
    if (rc == ABBSTOOLS_CONF_NO_PORT) {
        abt_puts("STATUS=UNAVAILABLE\nREASON=ABBS_MAIN_PORT_NOT_PRESENT\n");
        return ABBSTOOLS_RC_WARN;
    }
    if (rc == ABBSTOOLS_CONF_NOT_FOUND) {
        abt_puts("STATUS=NOT_FOUND\nCONFERENCE="); abt_put_u32(conference); abt_puts("\n");
        return ABBSTOOLS_RC_WARN;
    }
    if (rc == ABBSTOOLS_CONF_BAD_CONFIG) {
        abt_puts("STATUS=ERROR\nREASON=INVALID_CONFERENCE_CONFIG\n");
        return ABBSTOOLS_RC_ERROR;
    }

    abt_puts("STATUS=ERROR\nREASON=ABBS_REQUEST_FAILED\nABBS_ERROR=");
    abt_put_u32(info.abbs_error);
    abt_puts("\n");
    return ABBSTOOLS_RC_ERROR;
#endif
}
