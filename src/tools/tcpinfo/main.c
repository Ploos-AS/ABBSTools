#include <exec/io.h>
#include <exec/types.h>
#include <proto/exec.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

static void emit_result(const char *status, const char *device, ULONG unit,
                        int available, LONG open_rc)
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
    abt_puts(available ? "YES" : "NO");
    abt_puts("\nOPEN_RC=");
    sprintf(num, "%ld", (long)open_rc);
    abt_puts(num);
    abt_puts("\n");
}

int main(int argc, char **argv)
{
    const char *device = DEFAULT_DEVICE;
    ULONG unit = DEFAULT_UNIT;
    struct MsgPort *port = 0;
    struct IORequest *io = 0;
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
        emit_result("FATAL", device, unit, 0, -1);
        return ABBSTOOLS_RC_FATAL;
    }

    io = CreateIORequest(port, sizeof(struct IORequest));
    if (!io) {
        DeleteMsgPort(port);
        emit_result("FATAL", device, unit, 0, -1);
        return ABBSTOOLS_RC_FATAL;
    }

    rc = OpenDevice((STRPTR)device, unit, io, 0);
    if (rc != 0) {
        DeleteIORequest(io);
        DeleteMsgPort(port);
        emit_result("WARN", device, unit, 0, rc);
        return ABBSTOOLS_RC_WARN;
    }

    CloseDevice(io);
    DeleteIORequest(io);
    DeleteMsgPort(port);

    emit_result("OK", device, unit, 1, 0);
    return ABBSTOOLS_RC_OK;
}
