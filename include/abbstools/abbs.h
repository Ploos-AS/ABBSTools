#ifndef ABBSTOOLS_ABBS_H
#define ABBSTOOLS_ABBS_H

#include <exec/types.h>

#define ABBSTOOLS_ABBS_INTERFACE_UNQUALIFIED 5
#define ABBSTOOLS_ABBS_NODE_STATE_LEN 32
#define ABBSTOOLS_ABBS_NODE_USER_LEN 64
#define ABBSTOOLS_ABBS_NODE_PORT_LEN 40

struct AbtNodeInfo {
    ULONG node;
    UBYTE available;
    UBYTE port_present;
    char port[ABBSTOOLS_ABBS_NODE_PORT_LEN];
    char state[ABBSTOOLS_ABBS_NODE_STATE_LEN];
    char user[ABBSTOOLS_ABBS_NODE_USER_LEN];
};

int abt_abbs_node_query(ULONG node, struct AbtNodeInfo *info);

#endif
