#ifndef ABBSTOOLS_ABBS_H
#define ABBSTOOLS_ABBS_H

#include <exec/types.h>

#define ABBSTOOLS_ABBS_INTERFACE_UNQUALIFIED 5
#define ABBSTOOLS_ABBS_NODE_STATE_LEN 32
#define ABBSTOOLS_ABBS_NODE_USER_LEN 64

struct AbtNodeInfo {
    ULONG node;
    UBYTE available;
    char state[ABBSTOOLS_ABBS_NODE_STATE_LEN];
    char user[ABBSTOOLS_ABBS_NODE_USER_LEN];
};

int abt_abbs_node_query(ULONG node, struct AbtNodeInfo *info);

#endif
