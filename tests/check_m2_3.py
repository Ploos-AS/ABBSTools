#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "src/tools/assigncheck/main.c").read_text()
makefile = (root / "Makefile").read_text()

checks = {
    "AssignCheck source exists": "Usage: AssignCheck" in source,
    "checks BBS volume/assign": 'path_present("BBS:")' in source,
    "checks ABBS assign": 'path_present("ABBS:")' in source,
    "uses read-only Lock": "Lock((STRPTR)path, ACCESS_READ)" in source,
    "unlocks successful locks": "UnLock(lock)" in source,
    "reports BBS presence": "BBS_PRESENT=" in source,
    "reports ABBS presence": "ABBS_PRESENT=" in source,
    "reports health": "HEALTH=" in source,
    "reports reason": "REASON=" in source,
    "distinguishes missing BBS": "BBS_NOT_PRESENT" in source,
    "distinguishes missing ABBS": "ABBS_NOT_PRESENT" in source,
    "distinguishes both missing": "BBS_AND_ABBS_NOT_PRESENT" in source,
    "success returns OK": "return ABBSTOOLS_RC_OK;" in source,
    "warning returns WARN": "return ABBSTOOLS_RC_WARN;" in source,
    "AssignCheck target exists": "assigncheck: $(BUILD_DIR)/AssignCheck" in makefile,
    "AssignCheck is part of all": "all: rexxports rexxprobe nodeinfo nodewatch nodecheck assigncheck" in makefile,
}

failed = False
for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'}: {name}")
    failed |= not passed

raise SystemExit(1 if failed else 0)
