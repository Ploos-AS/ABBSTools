#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
main = (root / "src/tools/nodecheck/main.c").read_text()
makefile = (root / "Makefile").read_text()

checks = {
    "NodeCheck source exists": "Usage: NodeCheck NODE" in main,
    "NodeCheck uses qualified node adapter": "abt_abbs_node_query(node, &info)" in main,
    "NodeCheck reports HEALTH": 'abt_puts(" HEALTH=")' in main,
    "NodeCheck reports REASON": 'abt_puts(" REASON=")' in main,
    "NodeCheck distinguishes missing port": '"PORT_NOT_PRESENT"' in main,
    "NodeCheck distinguishes missing log": '"LOG_NOT_PRESENT"' in main,
    "NodeCheck distinguishes unknown session": '"SESSION_UNKNOWN"' in main,
    "NodeCheck has success state": '"OK", "NONE"' in main,
    "NodeCheck target exists": "nodecheck: $(BUILD_DIR)/NodeCheck" in makefile,
    "NodeCheck is part of all": "all: rexxports rexxprobe nodeinfo nodewatch nodecheck" in makefile,
}

failed = False
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + f": {name}")
    failed |= not ok

raise SystemExit(1 if failed else 0)
