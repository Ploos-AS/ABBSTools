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
    "port presence is modeled": "port_present" in header and "ABBSTOOLS_ABBS_NODE_PORT_LEN" in header,
    "qualified ABBS node port naming": '"ABBS node #"' in adapter and '" port"' in adapter,
    "public port lookup is scheduler protected": (
        "Forbid();" in adapter
        and "FindPort(" in adapter
        and "info->port" in adapter
        and "Permit();" in adapter
    ),
    "node log path is modeled": "log_present" in header and "ABBSTOOLS_ABBS_NODE_LOG_LEN" in header,
    "qualified ABBS node log naming": '"ABBS:node"' in adapter and '"logfile"' in adapter,
    "session state is explicit": (
        "ABBSTOOLS_SESSION_UNKNOWN" in header
        and "ABBSTOOLS_SESSION_IDLE" in header
        and "ABBSTOOLS_SESSION_ACTIVE" in header
    ),
    "login parser exists": 'find_text(line, " Login: ")' in adapter,
    "logout parser exists": 'find_text(line, " Logout: ")' in adapter,
    "node log is read-only": (
        "MODE_OLDFILE" in adapter
        and "Read(fh," in adapter
        and "Close(fh);" in adapter
    ),
    "NodeInfo accepts a node": "Usage: NodeInfo NODE" in nodeinfo,
    "NodeInfo reports port": 'abt_puts("STATUS=OK\\nPORT=")' in nodeinfo,
    "NodeInfo reports presence": 'abt_puts("\\nPRESENT=")' in nodeinfo,
    "NodeInfo reports session": 'abt_puts("\\nSESSION=")' in nodeinfo,
    "NodeInfo reports log presence": 'abt_puts("\\nLOG_PRESENT=")' in nodeinfo,
    "NodeInfo target exists": "NodeInfo" in makefile,
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    for name in failed:
        print(f"FAIL: {name}")
    raise SystemExit(1)

for name in checks:
    print(f"PASS: {name}")
