#include <exec/ports.h>
#include <exec/types.h>
#include <proto/exec.h>
#include <proto/rexxsyslib.h>
#include <rexx/rxslib.h>

#include "abbstools/arexx.h"
#include "abbstools/common.h"

struct RxsLib *RexxSysBase;

static ULONG text_len(const char *text)
{
    const char *p = text;
    ULONG len = 0;

    while (*p++) {
        ++len;
    }
    return len;
}

int abt_arexx_send(const char *port_name,
                   const char *command,
                   struct AbtRexxResult *result)
{
    struct MsgPort *reply_port;
    struct MsgPort *target_port;
    struct RexxMsg *message;
    int rc = ABBSTOOLS_RC_FATAL;

    if (result != 0) {
        result->primary = 0;
        result->secondary = 0;
    }

    RexxSysBase = (struct RxsLib *)OpenLibrary((CONST_STRPTR)RXSNAME, 0);
    if (RexxSysBase == 0) {
        return ABBSTOOLS_AREXX_SETUP_ERROR;
    }

    reply_port = CreateMsgPort();
    if (reply_port == 0) {
        CloseLibrary((struct Library *)RexxSysBase);
        RexxSysBase = 0;
        return ABBSTOOLS_AREXX_SETUP_ERROR;
    }

    message = CreateRexxMsg(reply_port, 0, 0);
    if (message == 0) {
        DeleteMsgPort(reply_port);
        CloseLibrary((struct Library *)RexxSysBase);
        RexxSysBase = 0;
        return ABBSTOOLS_AREXX_SETUP_ERROR;
    }

    message->rm_Action = RXCOMM | RXFF_RESULT;
    message->rm_Args[0] = CreateArgstring((UBYTE *)command, text_len(command));
    if (message->rm_Args[0] == 0) {
        DeleteRexxMsg(message);
        DeleteMsgPort(reply_port);
        CloseLibrary((struct Library *)RexxSysBase);
        RexxSysBase = 0;
        return ABBSTOOLS_AREXX_SETUP_ERROR;
    }

    Forbid();
    target_port = FindPort((STRPTR)port_name);
    if (target_port != 0) {
        PutMsg(target_port, (struct Message *)message);
    }
    Permit();

    if (target_port == 0) {
        DeleteArgstring(message->rm_Args[0]);
        DeleteRexxMsg(message);
        DeleteMsgPort(reply_port);
        CloseLibrary((struct Library *)RexxSysBase);
        RexxSysBase = 0;
        return ABBSTOOLS_AREXX_NO_PORT;
    }

    WaitPort(reply_port);
    GetMsg(reply_port);

    if (result != 0) {
        result->primary = message->rm_Result1;
        result->secondary = message->rm_Result2;
    }

    rc = ABBSTOOLS_RC_OK;
    if (message->rm_Result1 != 0) {
        rc = ABBSTOOLS_RC_WARN;
    }

    DeleteArgstring(message->rm_Args[0]);
    DeleteRexxMsg(message);
    DeleteMsgPort(reply_port);
    CloseLibrary((struct Library *)RexxSysBase);
    RexxSysBase = 0;

    return rc;
}
