from pathlib import Path

root = Path(__file__).resolve().parents[1]
header = (root / "include/abbstools/abbs_conf.h").read_text()
adapter = (root / "src/common/abbs_conf.c").read_text()
main = (root / "src/tools/confinfo/main.c").read_text()
contract = (root / "docs/M3_4_CONF_CONTRACT.md").read_text()

checks = {
    "public adapter API": "abt_abbs_conf_query" in header,
    "main port": 'ABBS_MAIN_PORT "ABBS mainport"' in adapter,
    "getconfig command": "MAIN_GETCONFIG 46" in adapter,
    "conference record fields": all(x in adapter for x in ["default_msg", "first_msg", "order", "switches", "max_scan"]),
    "source-backed config prefix": "ABBS_CONFIG_PREFIX_SIZE" in adapter,
    "config sentinel": "msg.user_nr == 0" in adapter,
    "bounded max conferences": "ABBSTOOLS_CONF_MAX" in adapter,
    "1-based lookup": "conference - 1" in adapter,
    "bounded name copy": "ABBSTOOLS_CONF_NAME_LEN" in adapter,
    "read-only implementation": all(x not in adapter for x in ["MAIN_SAVECONFIG", "Main_saveconfig", "Main_createconference", "Main_DeleteConference", "Main_RenameConference"]),
    "stable CLI output": all(x in main for x in ["CONFERENCE=", "NAME=", "ORDER=", "DEFAULT_MSG=", "FIRST_MSG=", "BULLETS=", "MAX_SCAN=", "SWITCHES="]),
    "trace fixture": "ABBSTOOLS_CI_TRACE" in main,
    "contract source pin": "a51658289061a60392954187d2fe4bd209703a9d" in contract,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + ": " + name)

if failed:
    raise SystemExit(1)
