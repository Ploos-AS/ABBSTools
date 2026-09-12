#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = (root / "src/tools/doorcheck/main.c").read_text()
contract = (root / "docs/M4_2_DOORCHECK_CONTRACT.md").read_text()

checks = {
    "source exists": "DoorCheck PATH FILE|DIRECTORY|ANY" in src,
    "read-only lock": "Lock((STRPTR)argv[1], ACCESS_READ)" in src,
    "examine": "Examine(lock, &fib)" in src,
    "unlock": "UnLock(lock)" in src,
    "file type": 'return "FILE"' in src,
    "directory type": 'return "DIRECTORY"' in src,
    "any type": 'streq(expected, "ANY")' in src,
    "missing warning": '"PATH_NOT_PRESENT"' in src,
    "mismatch warning": '"TYPE_MISMATCH"' in src,
    "match result": '"MATCH"' in src,
    "no execution": "System(" not in src and "Execute(" not in src,
    "no fixed door path": "ABBS:Doors" not in src,
    "contract no registry guess": "does not discover doors" in contract,
    "contract no dropfile guess": "Does not invent a generic ABBS drop-file" in contract,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"{'PASS' if ok else 'FAIL'}: {name}")

if failed:
    raise SystemExit("M4.2 static gate failed: " + ", ".join(failed))

print("M4_2_STATIC=PASS")
