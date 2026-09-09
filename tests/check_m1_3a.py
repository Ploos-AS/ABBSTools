#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

header = (ROOT / "include/abbstools/abbs.h").read_text()
adapter = (ROOT / "src/common/abbs.c").read_text()
nodeinfo = (ROOT / "src/tools/nodeinfo/main.c").read_text()
makefile = (ROOT / "Makefile").read_text()

checks = {
    "node model exists": "struct AbtNodeInfo" in header,
    "adapter boundary exists": "abt_abbs_node_query" in header and "abt_abbs_node_query" in adapter,
    "unqualified interface is explicit": "ABBSTOOLS_ABBS_INTERFACE_UNQUALIFIED" in header,
    "NodeInfo accepts a node": "Usage: NodeInfo NODE" in nodeinfo,
    "NodeInfo has stable unavailable output": "ABBS_INTERFACE_NOT_QUALIFIED" in nodeinfo,
    "NodeInfo target exists": "NodeInfo" in makefile,
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    for name in failed:
        print(f"FAIL: {name}")
    raise SystemExit(1)

for name in checks:
    print(f"PASS: {name}")
