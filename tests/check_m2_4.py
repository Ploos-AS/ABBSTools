#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "src/tools/bbsdoctor/main.c").read_text()
makefile = (root / "Makefile").read_text()

checks = {
    "BBSDoctor source exists": "Usage: BBSDoctor" in source,
    "checks BBS path": '"BBS:"' in source,
    "checks ABBS path": '"ABBS:"' in source,
    "reuses node adapter": "abt_abbs_node_query" in source,
    "supports CI trace node adapter": "abt_abbs_node_query_trace" in source,
    "uses read-only Lock": "Lock((STRPTR)path, ACCESS_READ)" in source,
    "reports aggregate health": 'abt_puts("HEALTH=")' in source,
    "reports aggregate reason": 'abt_puts("REASON=")' in source,
    "reports BBS presence": 'abt_puts("BBS_PRESENT=")' in source,
    "reports ABBS presence": 'abt_puts("ABBS_PRESENT=")' in source,
    "reports node presence": 'abt_puts("PRESENT=")' in source,
    "reports session": 'abt_puts("SESSION=")' in source,
    "distinguishes assign failure": "BBS_AND_ABBS_NOT_PRESENT" in source,
    "distinguishes port failure": "PORT_NOT_PRESENT" in source,
    "distinguishes log failure": "LOG_NOT_PRESENT" in source,
    "distinguishes unknown session": "SESSION_UNKNOWN" in source,
    "BBSDoctor target exists": "bbsdoctor: $(BUILD_DIR)/BBSDoctor" in makefile,
    "BBSDoctor is part of all": "assigncheck bbsdoctor" in makefile,
}

failed = False
for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'}: {name}")
    failed |= not passed

raise SystemExit(1 if failed else 0)
