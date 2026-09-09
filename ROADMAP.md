# ABBSTools Roadmap

## M0 — Foundation

- [x] Define AmigaOS 2.04+ target
- [x] Define 68000 compatibility baseline
- [x] Define ABBS-specific project scope
- [x] Define Shell + ARexx design principles
- [x] Define common return-code convention
- [x] Define initial source tree
- [x] Select first implementation batch

## M1 — ARexx and message-port foundation

Initial tools:

1. `RexxPorts`
2. `RexxProbe`
3. `NodeInfo`

Shared helpers should cover argument parsing, version strings, standardized return codes, ARexx host lifecycle, result/stem formatting and Exec public message-port inspection.

## M2 — ABBS node diagnostics

Candidate tools: `NodeWatch`, `NodeCheck`, `AssignCheck`, `BBSDoctor`.

## M3 — Users, conferences and logs

Candidate tools: `UserInfo`, `ConfInfo`, `LastCalls`, `LogInfo`.

## M4 — Doors and external programs

Candidate tools: `DoorInfo`, `DoorCheck`, and ABBS-relevant drop-file inspection/validation.

## M5 — TCP and remote-node diagnostics

Candidate tools: `TCPInfo`, Telnet diagnostics and integration diagnostics useful with TCP-backed ABBS node setups.

## Qualification strategy

Use automated build/static checks first, then runtime qualification in batches. Emulator-based smoke testing may use FS-UAE with a redistributable ROM environment where suitable; final compatibility claims should be backed by qualification on the intended AmigaOS baseline.
