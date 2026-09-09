#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

required = [
    ROOT / "include/abbstools/arexx.h",
    ROOT / "src/common/arexx.c",
    ROOT / "src/tools/rexxprobe/main.c",
]

for path in required:
    if not path.is_file():
        raise SystemExit(f"missing required file: {path.relative_to(ROOT)}")

arexx = (ROOT / "src/common/arexx.c").read_text()
probe = (ROOT / "src/tools/rexxprobe/main.c").read_text()
makefile = (ROOT / "Makefile").read_text()

checks = {
    "opens rexxsyslib": 'OpenLibrary("rexxsyslib.library", 0)' in arexx,
    "creates RexxMsg": "CreateRexxMsg" in arexx,
    "creates Argstring": "CreateArgstring" in arexx,
    "finds target port safely": "Forbid();" in arexx and "FindPort" in arexx and "Permit();" in arexx,
    "sends message": "PutMsg" in arexx,
    "waits for reply": "WaitPort" in arexx and "GetMsg" in arexx,
    "cleans RexxMsg": "DeleteArgstring" in arexx and "DeleteRexxMsg" in arexx,
    "RexxProbe usage": "Usage: RexxProbe PORT COMMAND" in probe,
    "RexxProbe target": "RexxProbe" in makefile,
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    for name in failed:
        print(f"FAIL: {name}")
    raise SystemExit(1)

for name in checks:
    print(f"PASS: {name}")
