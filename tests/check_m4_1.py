#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = (root / "src/tools/doorinfo/main.c").read_text()
contract = (root / "docs/M4_1_DOORINFO_CONTRACT.md").read_text()

checks = {
    "DoorInfo source exists": "Usage: DoorInfo PATH" in src,
    "read-only AmigaDOS Lock": "Lock((STRPTR)argv[1], ACCESS_READ)" in src,
    "AmigaDOS Examine": "Examine(lock, &fib)" in src,
    "unlock after examine": "UnLock(lock)" in src,
    "stable present output": "PRESENT=YES" in src and "PRESENT=NO" in src,
    "stable object types": '"DIRECTORY"' in src and '"FILE"' in src and '"OTHER"' in src,
    "missing path warning": "PATH_NOT_PRESENT" in src,
    "no target execution": "System(" not in src and "Execute(" not in src,
    "deterministic trace": "ABBSTOOLS_CI_TRACE" in src,
    "contract refuses registry guessing": "does not guess" in contract or "does not by itself establish" in contract,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + ": " + name)

if failed:
    raise SystemExit(1)
print("M4.1 static checks PASS")
