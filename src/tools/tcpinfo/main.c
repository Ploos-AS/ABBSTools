#include <devices/serial.h>
#include <exec/io.h>
#include <exec/types.h>
#include <proto/exec.h>
#include <stdio.h>
#include <stdlib.h>

#include "abbstools/common.h"

#define DEFAULT_DEVICE "abbstcp.device"
#define DEFAULT_UNIT 0UL

static int parse_unit(const char *s, ULONG *out)
{
    char *end = 0;
    unsigned long v;

    if (!s || !*s || !out) return 0;
    v = strtoul(s, &end, 10);
    if (!end || *end != '\0') return 0;
    *out = (ULONG)v;
    return 1;
}

static void emit_common(const char *status, const char *device, ULONG unit,
                        const char *available)
{
    char num[32];

    abt_puts("STATUS=");
    abt_puts(status);
    abt_puts("\nDEVICE=");
    abt_puts(device);
    abt_puts("\nUNIT=");
    sprintf(num, "%lu", (unsigned long)unit);
    abt_puts(num);
    abt_puts("\nAVAILABLE=");
    abt_puts(available);
    abt_puts("\n");
}

static void emit_open_result(const char *status, const char *device, ULONG unit,
                             const char *available, LONG open_error,
                             const char *reason)
{
    char num[32];

    emit_common(status, device, unit, available);
    abt_puts("OPEN_ERROR=");
    sprintf(num, "%ld", (long)open_error);
    abt_puts(num);
    abt_puts("\n");
    if (reason) {
        abt_puts("REASON=");
        abt_puts(reason);
        abt_puts("\n");
    }
}

int main(int argc, char **argv)
{
    const char *device = DEFAULT_DEVICE;
    ULONG unit = DEFAULT_UNIT;
    struct MsgPort *port = 0;
    struct IOExtSer *io = 0;
    LONG rc;

    if (argc > 3) {
        abt_puts("Usage: TCPInfo [DEVICE [UNIT]]\n");
        return ABBSTOOLS_RC_ERROR;
    }

    if (argc >= 2) {
        if (!argv[1][0]) {
            abt_puts("Usage: TCPInfo [DEVICE [UNIT]]\n");
            return ABBSTOOLS_RC_ERROR;
        }
        device = argv[1];
    }

    if (argc == 3 && !parse_unit(argv[2], &unit)) {
        abt_puts("Usage: TCPInfo [DEVICE [UNIT]]\n");
        return ABBSTOOLS_RC_ERROR;
    }

    port = CreateMsgPort();
    if (!port) {
        emit_common("FATAL", device, unit, "UNKNOWN");
        abt_puts("REASON=LOCAL_SETUP_FAILED\n");
        return ABBSTOOLS_RC_FATAL;
    }

    io = (struct IOExtSer *)CreateIORequest(port, sizeof(struct IOExtSer));
    if (!io) {
        DeleteMsgPort(port);
        emit_common("FATAL", device, unit, "UNKNOWN");
        abt_puts("REASON=LOCAL_SETUP_FAILED\n");
        return ABBSTOOLS_RC_FATAL;
    }

    rc = OpenDevice((STRPTR)device, unit, (struct IORequest *)io, 0);
    if (rc != 0) {
        DeleteIORequest((struct IORequest *)io);
        DeleteMsgPort(port);
        emit_open_result("WARN", device, unit, "NO", rc, "DEVICE_OPEN_FAILED");
        return ABBSTOOLS_RC_WARN;
    }

    CloseDevice((struct IORequest *)io);
    DeleteIORequest((struct IORequest *)io);
    DeleteMsgPort(port);

    emit_open_result("OK", device, unit, "YES", 0, 0);
    return ABBSTOOLS_RC_OK;
}
