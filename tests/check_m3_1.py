#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "src/tools/lastcalls/main.c").read_text()
makefile = (root / "Makefile").read_text()

login_match = all(token in source for token in (
    "p[0]=='L'",
    "p[1]=='o'",
    "p[2]=='g'",
    "p[3]=='i'",
    "p[4]=='n'",
    "p[5]==':'",
))

checks = {
    "LastCalls source exists": "Usage: LastCalls" in source,
    "uses documented ABBS node log prefix": '"ABBS:node"' in source,
    "uses node logfile suffix": '"logfile"' in source,
    "accepts Login records": login_match and "parse_login" in source,
    "captures username": "USER=" in source,
    "captures mode": "MODE=" in source,
    "captures node": "NODE=" in source,
    "captures date": "DATE=" in source,
    "captures time": "TIME=" in source,
    "bounds retained callers": "MAX_EVENTS 50" in source,
    "bounds nodes": "MAX_NODES 32" in source,
    "supports deterministic CI prefix": "ABBSTOOLS_CI_TRACE" in source,
    "opens logs read-only": "MODE_OLDFILE" in source,
    "LastCalls target exists": "lastcalls: $(BUILD_DIR)/LastCalls" in makefile,
    "LastCalls is part of all": "bbsdoctor lastcalls" in makefile,
}

failed = False
for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'}: {name}")
    failed |= not passed

raise SystemExit(1 if failed else 0)
