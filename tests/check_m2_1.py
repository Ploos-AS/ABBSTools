#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = (root / "src/tools/nodewatch/main.c").read_text()
makefile = (root / "Makefile").read_text()

checks = {
    "NodeWatch source exists": "Usage: NodeWatch NODE [INTERVAL [COUNT]]" in main,
    "NodeWatch uses qualified node adapter": "abt_abbs_node_query(node, &info)" in main,
    "NodeWatch reports stable sample number": 'abt_puts("SAMPLE=")' in main,
    "NodeWatch reports node state": 'abt_puts(" STATE=")' in main,
    "NodeWatch reports session": 'abt_puts(" SESSION=")' in main,
    "NodeWatch reports user": 'abt_puts(" USER=")' in main,
    "NodeWatch supports finite qualification runs": "sample >= count" in main,
    "NodeWatch uses DOS Delay between samples": "Delay(interval * TICKS_PER_SECOND)" in main,
    "NodeWatch target exists": "nodewatch: $(BUILD_DIR)/NodeWatch" in makefile,
    "NodeWatch is part of all": "all: rexxports rexxprobe nodeinfo nodewatch" in makefile,
}

failed = False
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + f": {name}")
    failed |= not ok

raise SystemExit(1 if failed else 0)
