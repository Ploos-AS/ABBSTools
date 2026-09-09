#include <exec/ports.h>
#include <proto/exec.h>

#include "abbstools/abbs.h"

static void copy_text(char *dst, ULONG size, const char *src)
{
    ULONG i = 0;

    if (size == 0) {
        return;
    }

    while (src[i] != 0 && i + 1 < size) {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = 0;
}

static int build_node_port(ULONG node, char *dst, ULONG size)
{
    static const char prefix[] = "ABBS node #";
    static const char suffix[] = " port";
    char digits[10];
    ULONG count = 0;
    ULONG pos = 0;
    ULONG value = node;
    ULONG i;

    if (node == 0 || size == 0) {
        return 0;
    }

    while (prefix[pos] != 0) {
        if (pos + 1 >= size) {
            return 0;
        }
        dst[pos] = prefix[pos];
        ++pos;
    }

    do {
        if (count >= sizeof(digits)) {
            return 0;
        }
        digits[count++] = (char)('0' + (value % 10));
        value /= 10;
    } while (value != 0);

    for (i = 0; i < count; ++i) {
        if (pos + 1 >= size) {
            return 0;
        }
        dst[pos++] = digits[count - i - 1];
    }

    for (i = 0; suffix[i] != 0; ++i) {
        if (pos + 1 >= size) {
            return 0;
        }
        dst[pos++] = suffix[i];
    }

    dst[pos] = 0;
    return 1;
}

int abt_abbs_node_query(ULONG node, struct AbtNodeInfo *info)
{
    struct MsgPort *port;

    if (info == 0 || !build_node_port(node, info->port, sizeof(info->port))) {
        return ABBSTOOLS_ABBS_INTERFACE_UNQUALIFIED;
    }

    info->node = node;
    info->available = 1;
    info->port_present = 0;
    info->user[0] = 0;

    Forbid();
    port = FindPort(info->port);
    if (port != 0) {
        info->port_present = 1;
    }
    Permit();

    if (info->port_present) {
        copy_text(info->state, sizeof(info->state), "ONLINE");
    } else {
        copy_text(info->state, sizeof(info->state), "OFFLINE");
    }

    return 0;
}
