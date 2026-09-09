#include "abbstools/abbs.h"

int abt_abbs_node_query(ULONG node, struct AbtNodeInfo *info)
{
    if (info != 0) {
        info->node = node;
        info->available = 0;
        info->state[0] = 0;
        info->user[0] = 0;
    }

    return ABBSTOOLS_ABBS_INTERFACE_UNQUALIFIED;
}
