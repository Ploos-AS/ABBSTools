from pathlib import Path

source = Path("src/tools/metrics/main.c").read_text()
contract = Path("docs/M6_1_METRICS_CONTRACT.md").read_text()
makefile = Path("Makefile").read_text()

checks = {
    "source exists": "int main(" in source,
    "qualified node adapter": "abt_abbs_node_query(" in source,
    "trace adapter": "abt_abbs_node_query_trace(" in source,
    "node present metric": 'abbs_node_present' in source,
    "log present metric": 'abbs_node_log_present' in source,
    "session active metric": 'abbs_node_session_active' in source,
    "session known metric": 'abbs_node_session_known' in source,
    "no username label": 'USER=' not in source and 'user=\\"' not in source,
    "unqualified interface explicit": "ABBS_INTERFACE_NOT_QUALIFIED" in source,
    "query failure explicit": "NODE_QUERY_FAILED" in source,
    "contract namespace": "`abbs_`" in contract,
    "contract no daemon": "open a listening socket" in contract,
    "contract avoids high cardinality": "high-cardinality" in contract,
    "make target": "metrics:" in makefile,
}

failed = False
for name, ok in checks.items():
    print(f"{'PASS' if ok else 'FAIL'}: {name}")
    failed |= not ok

if failed:
    raise SystemExit(1)

print("M6_1_STATIC=PASS")
