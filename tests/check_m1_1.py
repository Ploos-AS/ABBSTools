#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

required = [
    ROOT / "Makefile",
    ROOT / "include/abbstools/common.h",
    ROOT / "src/common/output.c",
    ROOT / "src/tools/rexxports/main.c",
]

for path in required:
    if not path.is_file():
        raise SystemExit(f"missing required file: {path.relative_to(ROOT)}")

makefile = (ROOT / "Makefile").read_text()
header = (ROOT / "include/abbstools/common.h").read_text()
rexxports = (ROOT / "src/tools/rexxports/main.c").read_text()

checks = {
    "68000 baseline": "-m68000" in makefile,
    "no ixemul": "-noixemul" in makefile,
    "RexxPorts target": "RexxPorts" in makefile,
    "standard RC warning": "ABBSTOOLS_RC_WARN 5" in header,
    "ARexx namespace": 'ABBSTOOLS_AREXX_PREFIX "ABBSTOOLS."' in header,
    "Exec port list": "PortList.lh_Head" in rexxports,
    "scheduler protection": "Forbid();" in rexxports and "Permit();" in rexxports,
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    for name in failed:
        print(f"FAIL: {name}")
    raise SystemExit(1)

for name in checks:
    print(f"PASS: {name}")
