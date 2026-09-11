#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "src/tools/loginfo/main.c").read_text()
makefile = (root / "Makefile").read_text()

checks = {
    "LogInfo source exists": "Usage: LogInfo" in source,
    "uses documented ABBS node log prefix": '"ABBS:node"' in source,
    "uses node logfile suffix": '"logfile"' in source,
    "opens logs read-only": "MODE_OLDFILE" in source,
    "reports log presence": "LOG_PRESENT=" in source,
    "reports line count": "LINES=" in source,
    "reports login records": "LOGIN_RECORDS=" in source,
    "reports logout records": "LOGOUT_RECORDS=" in source,
    "recognizes login events": '" Login: "' in source,
    "recognizes logout events": '" Logout: "' in source,
    "supports deterministic CI path": "ABBSTOOLS_CI_TRACE" in source and "LOG_PATH" in source,
    "bounds node range": "MAX_NODE 32" in source,
    "LogInfo target exists": "loginfo: $(BUILD_DIR)/LogInfo" in makefile,
    "LogInfo is part of all": "lastcalls loginfo" in makefile,
}

failed = False
for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'}: {name}")
    failed |= not passed

raise SystemExit(1 if failed else 0)
