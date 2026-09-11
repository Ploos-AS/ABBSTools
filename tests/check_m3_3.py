#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = (root / "src/tools/userinfo/main.c").read_text()
adapter = (root / "src/common/abbs_user.c").read_text()
header = (root / "include/abbstools/abbs_user.h").read_text()
contract = (root / "docs/M3_3_USER_CONTRACT.md").read_text()

checks = {
    "UserInfo source exists": "Usage: UserInfo USER" in main,
    "main-port name is source-backed": '"ABBS mainport"' in adapter,
    "uses Main_Getconfig": "MAIN_GETCONFIG 46" in adapter,
    "uses Main_loaduser": "MAIN_LOADUSER 0" in adapter,
    "Error_Not_Found matches preserved ABI": "ERROR_NOT_FOUND 1" in adapter,
    "Error_NoPort matches preserved ABI": "ERROR_NO_PORT 18" in adapter,
    "ABBSmsg field order is documented": "field-for-field compatible with public struct ABBSmsg" in adapter,
    "Getconfig validates UserNr sentinel": "msg.user_nr == 0" in adapter,
    "allocates runtime UserrecordSize": "user_record_size" in adapter and "AllocVec(record_size" in adapter,
    "bounds runtime record size": "MAX_USER_RECORD_SIZE" in adapter,
    "never saves users": "MAIN_SAVEUSER" not in adapter and "Main_saveuser" not in adapter,
    "does not emit password": "PASSWORD=" not in main and "Password" not in main,
    "does not emit telephone fields": "TEL" not in main.upper(),
    "stable output includes name": '"NAME="' in main,
    "stable output includes user number": '"USER_NR="' in main,
    "stable output includes record size": '"RECORD_SIZE="' in main,
    "CI trace is deterministic": "ABBSTOOLS_CI_TRACE" in main,
    "adapter API exists": "abt_abbs_user_query_name" in header and "abt_abbs_user_query_name" in adapter,
    "contract records main-port decision": "public ABBS main-port contract exists" in contract,
}

failed = False
for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'}: {name}")
    failed |= not passed

raise SystemExit(1 if failed else 0)
