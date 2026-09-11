#ifndef ABBSTOOLS_ABBS_USER_H
#define ABBSTOOLS_ABBS_USER_H

#include <exec/types.h>

#define ABBSTOOLS_USER_NAME_LEN 31

#define ABBSTOOLS_USER_OK 0
#define ABBSTOOLS_USER_NOT_FOUND 1
#define ABBSTOOLS_USER_NO_PORT 2
#define ABBSTOOLS_USER_BAD_CONFIG 3
#define ABBSTOOLS_USER_NO_MEMORY 4
#define ABBSTOOLS_USER_ABBS_ERROR 5

struct AbtUserInfo {
    ULONG user_nr;
    ULONG record_size;
    UWORD abbs_error;
    char name[ABBSTOOLS_USER_NAME_LEN];
};

int abt_abbs_user_query_name(const char *name, struct AbtUserInfo *info);

#endif
