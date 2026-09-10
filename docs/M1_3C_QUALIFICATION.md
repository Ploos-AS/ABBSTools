# M1.3c Qualification — NodeInfo session-from-log

Status: **Automated AROS runtime qualification PASS**

This milestone qualifies the deterministic NodeInfo session-from-log path in an AROS m68k guest. It does **not** replace later live ABBS qualification on AmigaOS 2.04+.

## Qualified behavior

NodeInfo keeps public ABBS state sources separate:

- public node port: `ABBS node #N port`
- public node log: `ABBS:nodeNlogfile`
- `STATE=ONLINE|OFFLINE` comes from public port presence
- `SESSION=ACTIVE|IDLE|UNKNOWN` comes from the node log
- `USER=<name>` is populated only from a recognized latest Login event
- the node log is opened read-only

The deterministic fixture gate covers:

- Login -> `SESSION=ACTIVE`, `USER=Test User`
- Login followed by Logout -> `SESSION=IDLE`, empty `USER`
- readable log without a recognized session event -> `SESSION=UNKNOWN`, empty `USER`

All three fixture invocations returned RC 0.

## CI evidence

GitHub Actions workflow: `FS-UAE AROS qualification`

- run: #70
- run id: `34492758255`
- commit: `75b24b2db7b85864029ad440c28f077383ef4fbf`
- job: `aros-runtime`
- result: SUCCESS
- Gate 1 native 68000 build: PASS
- Gate 2 RexxPorts guest runtime: PASS
- Gate 3 RexxProbe: controlled SKIP because the AROS guest contains but cannot load `rexxsyslib.library`
- Gate 4 `M1_3C_AROS_NODEINFO_SESSION`: PASS
- model: A1200
- Kickstart: AROS internal
- FS-UAE timeout exit 124 is expected after guest evidence is written
- artifact id: `10158622908`
- artifact ZIP SHA-256: `617b101923dd9b96977129a52890213869dad3bc930352a452b4663e00ce75f7`

The fixture gate uses a CI-only direct path for the log file because the earlier AROS setup showed problematic behavior around the synthetic `ABBS:` assign. The public `NodeInfo` output remains `LOG=ABBS:nodeNlogfile`; the direct path is not part of the production CLI contract.

## Remaining qualification

Before v0.1.0 release, NodeInfo still requires live ABBS qualification on the intended AmigaOS baseline. That test must use a real ABBS installation and the real `ABBS:` assign. The automated AROS PASS proves the native binary, file reader, parser, public output contract, and deterministic session-state transitions, but not the complete live ABBS environment.
