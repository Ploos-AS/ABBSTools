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

header = (ROOT / "include/abbstools/arexx.h").read_text()
arexx = (ROOT / "src/common/arexx.c").read_text()
probe = (ROOT / "src/tools/rexxprobe/main.c").read_text()
makefile = (ROOT / "Makefile").read_text()

checks = {
    "opens rexxsyslib": "OpenLibrary" in arexx and ("RXSNAME" in arexx or '"rexxsyslib.library"' in arexx),
    "creates RexxMsg": "CreateRexxMsg" in arexx,
    "creates Argstring": "CreateArgstring" in arexx,
    "finds target port safely": "Forbid();" in arexx and "FindPort" in arexx and "Permit();" in arexx,
    "sends message": "PutMsg" in arexx,
    "waits for reply": "WaitPort" in arexx and "GetMsg" in arexx,
    "cleans RexxMsg": "DeleteArgstring" in arexx and "DeleteRexxMsg" in arexx,
    "models result text": "ABBSTOOLS_AREXX_RESULT_LEN" in header and "has_text" in header and "truncated" in header,
    "copies result text": "copy_result_text" in arexx,
    "frees returned result Argstring": "DeleteArgstring(result_text)" in arexx,
    "separates success text from error secondary": "message->rm_Result1 == 0" in arexx and "result->secondary = message->rm_Result2" in arexx,
    "RexxProbe usage": "Usage: RexxProbe PORT COMMAND" in probe,
    "RexxProbe prints result text": 'abt_puts("\\nRESULT=")' in probe and "result.text" in probe,
    "RexxProbe target": "RexxProbe" in makefile,
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    for name in failed:
        print(f"FAIL: {name}")
    raise SystemExit(1)

for name in checks:
    print(f"PASS: {name}")
