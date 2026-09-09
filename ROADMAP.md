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

### M1.1 — RexxPorts foundation

- [x] Add 68000/AmigaOS 2.04+ build foundation
- [x] Add shared ABBSTools constants/output helpers
- [x] Implement `RexxPorts`
- [x] Add static repository gate
- [x] Cross-build with Bebbo `m68k-amigaos-gcc`
- [x] Runtime-smoke-test with FS-UAE + AROS
- [ ] Final compatibility qualification on intended AmigaOS 2.04 baseline

### M1.2 — RexxProbe

- [x] Implement `RexxProbe`
- [x] Add reusable ARexx message helpers
- [x] Define timeout/error behaviour
- [x] Add static and native qualification
- [x] Add FS-UAE + AROS RexxProbe capability gate
- [ ] Runtime-smoke-test `RexxProbe` in an environment with `rexxsyslib.library`
- [ ] End-to-end ARexx reply qualification against a deterministic host
- [ ] Final compatibility qualification on intended AmigaOS 2.04 baseline

Current AROS boot-ISO qualification environment is useful for native/Exec smoke testing but does not contain `rexxsyslib.library`; the RexxProbe AROS gate therefore records a controlled SKIP rather than claiming runtime PASS.

### M1.3 — NodeInfo

- [ ] Establish qualified ABBS node interface
- [ ] Implement `NodeInfo`
- [ ] Expose structured ARexx results
- [ ] Runtime-qualify against ABBS

## M2 — ABBS node diagnostics

Candidate tools: `NodeWatch`, `NodeCheck`, `AssignCheck`, `BBSDoctor`.

## M3 — Users, conferences and logs

Candidate tools: `UserInfo`, `ConfInfo`, `LastCalls`, `LogInfo`.

## M4 — Doors and external programs

Candidate tools: `DoorInfo`, `DoorCheck`, and ABBS-relevant drop-file inspection/validation.

## M5 — TCP and remote-node diagnostics

Candidate tools: `TCPInfo`, Telnet diagnostics and integration diagnostics useful with TCP-backed ABBS node setups.

## M6 — Optional observability

Keep observability optional and non-invasive for classic systems. Candidate scope:

- Stable machine-readable output suitable for external collectors
- Optional host-side exporter/bridge for Prometheus
- Node availability, session, error and activity metrics where ABBS exposes reliable data
- No mandatory TCP stack, daemon or Prometheus dependency on the Amiga itself
- Preserve normal standalone Shell/ARexx operation when observability is unused

Prometheus support is an integration target, not a requirement for using ABBSTools.

## v0.1.0 release target

The first release should contain the useful initial suite rather than only the M1 foundation. Target the implemented and qualified tools from M1 through M5, with M6 observability support included where it is mature enough to remain optional and low-risk.

## Qualification strategy

Use automated build/static checks first, then runtime qualification in batches. Emulator-based smoke testing may use FS-UAE with a redistributable ROM environment where suitable; final compatibility claims should be backed by qualification on the intended AmigaOS baseline.
