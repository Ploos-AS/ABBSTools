#ifndef ABBSTOOLS_ABBS_CONF_H
#define ABBSTOOLS_ABBS_CONF_H

#include <exec/types.h>

#define ABBSTOOLS_CONF_NAME_LEN 31
#define ABBSTOOLS_CONF_MAX 256

#define ABBSTOOLS_CONF_OK 0
#define ABBSTOOLS_CONF_NO_PORT 1
#define ABBSTOOLS_CONF_BAD_CONFIG 2
#define ABBSTOOLS_CONF_NOT_FOUND 3
#define ABBSTOOLS_CONF_ABBS_ERROR 4

struct AbtConfInfo {
    UWORD conference;
    UWORD max_conferences;
    UWORD order;
    UWORD switches;
    UWORD max_scan;
    UBYTE bullets;
    UWORD abbs_error;
    ULONG default_msg;
    ULONG first_msg;
    char name[ABBSTOOLS_CONF_NAME_LEN];
};

int abt_abbs_conf_query(ULONG conference, struct AbtConfInfo *info);

#endif
