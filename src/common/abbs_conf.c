#include <exec/ports.h>
#include <proto/exec.h>

#include "abbstools/abbs_conf.h"

#define ABBS_MAIN_PORT "ABBS mainport"
#define MAIN_GETCONFIG 46
#define ERROR_OK 0

struct AbbsMessage {
    struct Message msg;
    UWORD command;
    UWORD error;
    ULONG data;
    char *name;
    ULONG user_nr;
    ULONG arg;
};

struct AbbsConferenceRecord {
    char name[31];
    UBYTE bullets;
    ULONG default_msg;
    ULONG first_msg;
    UWORD order;
    UWORD switches;
    UWORD max_scan;
};

struct AbbsConfigRecord {
    UWORD revision;
    ULONG config_size;
    ULONG user_record_size;
    UWORD max_conferences;
    UWORD max_file_dirs;
    ULONG users;
    ULONG max_users;
    char base_name[31];
    char sysop_name[31];
    ULONG sysop_user_nr;
    char sysop_password[12];
    char closed_password[12];
    UWORD max_lines_message;
    UWORD active_conf;
    UWORD active_dirs;
    UWORD new_user_time_limit;
    UWORD sleep_time;
    UBYTE default_charset;
    UBYTE cflags;
    UWORD new_user_file_limit;
    UWORD byte_ratio;
    UWORD file_ratio;
    UWORD min_ul_space;
    UBYTE cflags2;
    UBYTE pad_a123;
    char dos_password[12];
    UBYTE empty[256];
    APTR first_file_dir_record;
    struct AbbsConferenceRecord first_conference[1];
};

#define ABBS_CONFIG_PREFIX_SIZE (sizeof(struct AbbsConfigRecord) - sizeof(struct AbbsConferenceRecord))

static void clear_bytes(void *ptr, ULONG size)
{
    UBYTE *p = (UBYTE *)ptr;
    ULONG i;
    for (i = 0; i < size; ++i) p[i] = 0;
}

static void copy_name(char *dst, const char *src)
{
    ULONG i = 0;
    while (i + 1 < ABBSTOOLS_CONF_NAME_LEN && src[i] != 0) {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = 0;
}

static int send_main(struct AbbsMessage *msg)
{
    struct MsgPort *reply;
    struct MsgPort *mainport;
    struct AbbsMessage *returned;

    reply = CreateMsgPort();
    if (reply == 0) return ABBSTOOLS_CONF_ABBS_ERROR;

    msg->msg.mn_ReplyPort = reply;
    msg->msg.mn_Length = sizeof(*msg);
    Forbid();
    mainport = FindPort((STRPTR)ABBS_MAIN_PORT);
    if (mainport != 0) PutMsg(mainport, (struct Message *)msg);
    Permit();

    if (mainport == 0) {
        DeleteMsgPort(reply);
        return ABBSTOOLS_CONF_NO_PORT;
    }

    WaitPort(reply);
    returned = (struct AbbsMessage *)GetMsg(reply);
    DeleteMsgPort(reply);
    return returned != 0 ? ABBSTOOLS_CONF_OK : ABBSTOOLS_CONF_ABBS_ERROR;
}

int abt_abbs_conf_query(ULONG conference, struct AbtConfInfo *info)
{
    struct AbbsMessage msg;
    struct AbbsConfigRecord *config;
    struct AbbsConferenceRecord *confs;
    struct AbbsConferenceRecord *conf;
    int rc;

    if (info == 0 || conference == 0 || conference > ABBSTOOLS_CONF_MAX)
        return ABBSTOOLS_CONF_BAD_CONFIG;

    clear_bytes(info, sizeof(*info));
    clear_bytes(&msg, sizeof(msg));
    msg.command = MAIN_GETCONFIG;
    rc = send_main(&msg);
    if (rc != ABBSTOOLS_CONF_OK) return rc;

    info->abbs_error = msg.error;
    if (msg.error != ERROR_OK || msg.user_nr == 0 || msg.data == 0)
        return ABBSTOOLS_CONF_ABBS_ERROR;

    config = (struct AbbsConfigRecord *)msg.data;
    if (config->max_conferences == 0 || config->max_conferences > ABBSTOOLS_CONF_MAX)
        return ABBSTOOLS_CONF_BAD_CONFIG;
    if (conference > config->max_conferences)
        return ABBSTOOLS_CONF_NOT_FOUND;

    confs = (struct AbbsConferenceRecord *)((UBYTE *)config + ABBS_CONFIG_PREFIX_SIZE);
    conf = &confs[conference - 1];

    info->conference = (UWORD)conference;
    info->max_conferences = config->max_conferences;
    info->order = conf->order;
    info->switches = conf->switches;
    info->max_scan = conf->max_scan;
    info->bullets = conf->bullets;
    info->default_msg = conf->default_msg;
    info->first_msg = conf->first_msg;
    copy_name(info->name, conf->name);
    return ABBSTOOLS_CONF_OK;
}
