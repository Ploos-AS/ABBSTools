#include <exec/memory.h>
#include <exec/ports.h>
#include <proto/exec.h>

#include "abbstools/abbs_user.h"

/*
 * Source-backed ABBS 2.x public main-port ABI.
 * Verified against ResistanceVault/preservation-abbs20 Include/bbs.h at
 * a51658289061a60392954187d2fe4bd209703a9d.
 */
#define ABBS_MAIN_PORT "ABBS mainport"
#define MAIN_LOADUSER 0
#define MAIN_GETCONFIG 46
#define ERROR_OK 0
#define ERROR_NOT_FOUND 1
#define ERROR_NO_PORT 18
#define MAX_USER_RECORD_SIZE 65535UL

/* Must remain field-for-field compatible with public struct ABBSmsg. */
struct AbbsMessage {
    struct Message msg;
    UWORD command;
    UWORD error;
    ULONG data;
    char *name;
    ULONG user_nr;
    ULONG arg;
};

/* Prefix of public struct ConfigRecord used by UserInfo. */
struct ConfigPrefix {
    UWORD revision;
    ULONG config_size;
    ULONG user_record_size;
};

/* Prefix of public struct UserRecord used by UserInfo. */
struct UserPrefix {
    char name[31];
    UBYTE pass_10;
    ULONG user_nr;
};

static void clear_bytes(void *ptr, ULONG size)
{
    UBYTE *p = (UBYTE *)ptr;
    ULONG i;
    for (i = 0; i < size; ++i) p[i] = 0;
}

static void copy_name(char *dst, const char *src)
{
    ULONG i = 0;
    while (i + 1 < ABBSTOOLS_USER_NAME_LEN && src[i] != 0) {
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
    if (reply == 0) return ABBSTOOLS_USER_NO_MEMORY;

    msg->msg.mn_ReplyPort = reply;
    msg->msg.mn_Length = sizeof(*msg);

    Forbid();
    mainport = FindPort((STRPTR)ABBS_MAIN_PORT);
    if (mainport != 0) PutMsg(mainport, (struct Message *)msg);
    Permit();

    if (mainport == 0) {
        DeleteMsgPort(reply);
        return ABBSTOOLS_USER_NO_PORT;
    }

    WaitPort(reply);
    returned = (struct AbbsMessage *)GetMsg(reply);
    DeleteMsgPort(reply);
    if (returned == 0) return ABBSTOOLS_USER_ABBS_ERROR;
    return ABBSTOOLS_USER_OK;
}

int abt_abbs_user_query_name(const char *name, struct AbtUserInfo *info)
{
    struct AbbsMessage msg;
    struct ConfigPrefix *config;
    struct UserPrefix *user;
    APTR record;
    ULONG record_size;
    int rc;

    if (name == 0 || name[0] == 0 || info == 0) return ABBSTOOLS_USER_BAD_CONFIG;
    clear_bytes(info, sizeof(*info));

    clear_bytes(&msg, sizeof(msg));
    msg.command = MAIN_GETCONFIG;
    rc = send_main(&msg);
    if (rc != ABBSTOOLS_USER_OK) return rc;

    /*
     * Preserved ABBS utilities accept Main_Getconfig only when Error_OK,
     * UserNr is non-zero, and Data points at the live ConfigRecord.
     */
    if (msg.error != ERROR_OK || msg.user_nr == 0 || msg.data == 0) {
        info->abbs_error = msg.error;
        return ABBSTOOLS_USER_ABBS_ERROR;
    }

    config = (struct ConfigPrefix *)msg.data;
    record_size = config->user_record_size;
    if (record_size < sizeof(struct UserPrefix) || record_size > MAX_USER_RECORD_SIZE) {
        return ABBSTOOLS_USER_BAD_CONFIG;
    }

    record = AllocVec(record_size, MEMF_CLEAR);
    if (record == 0) return ABBSTOOLS_USER_NO_MEMORY;

    clear_bytes(&msg, sizeof(msg));
    msg.command = MAIN_LOADUSER;
    msg.data = (ULONG)record;
    msg.name = (char *)name;
    rc = send_main(&msg);
    if (rc != ABBSTOOLS_USER_OK) {
        FreeVec(record);
        return rc;
    }

    info->record_size = record_size;
    info->abbs_error = msg.error;
    if (msg.error == ERROR_NOT_FOUND) {
        FreeVec(record);
        return ABBSTOOLS_USER_NOT_FOUND;
    }
    if (msg.error == ERROR_NO_PORT) {
        FreeVec(record);
        return ABBSTOOLS_USER_NO_PORT;
    }
    if (msg.error != ERROR_OK) {
        FreeVec(record);
        return ABBSTOOLS_USER_ABBS_ERROR;
    }

    user = (struct UserPrefix *)record;
    copy_name(info->name, user->name);
    info->user_nr = user->user_nr;
    FreeVec(record);
    return ABBSTOOLS_USER_OK;
}
