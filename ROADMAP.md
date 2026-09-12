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
- [ ] Runtime-smoke-test `RexxProbe` in an environment with loadable `rexxsyslib.library`
- [ ] End-to-end ARexx reply qualification against a deterministic host
- [ ] Final compatibility qualification on intended AmigaOS 2.04 baseline

The current AROS boot-ISO contains a `rexxsyslib.library` file, but the guest cannot load it in this qualification environment. The RexxProbe AROS gate therefore records a controlled SKIP rather than claiming runtime PASS.

### M1.3 — NodeInfo

#### M1.3a — public contract and conservative adapter

- [x] Define bounded node data model
- [x] Add explicit ABBS adapter boundary
- [x] Add `NodeInfo NODE` CLI and stable machine-readable output
- [x] Refuse to guess unqualified ABBS internals; return explicit `UNAVAILABLE`/RC 5
- [x] Add static and native build qualification

#### M1.3b — live ABBS node integration

- [x] Establish qualified ABBS node public-port naming from existing ABBS door code
- [x] Replace conservative adapter stub with live Exec public-port lookup
- [x] Report `PORT`, `PRESENT` and `STATE=ONLINE|OFFLINE`

#### M1.3c — session metadata from node logs

- [x] Use documented `ABBS:nodeXlogfile` naming
- [x] Parse sequential `Login:` / `Logout:` records read-only
- [x] Report `LOG`, `LOG_PRESENT`, `SESSION=ACTIVE|IDLE|UNKNOWN` and `USER`
- [x] Avoid undocumented ABBS memory structures
- [x] Native-build qualify M1.3c
- [x] Runtime-qualify deterministic idle, active and unknown log fixtures under FS-UAE + AROS
- [ ] Runtime-qualify idle, connected and missing-log cases against live ABBS
- [ ] Expose structured ARexx results
- [ ] Final compatibility qualification on intended AmigaOS 2.04 baseline

## M2 — ABBS node diagnostics

### M2.1 — NodeWatch

- [x] Define `NodeWatch NODE [INTERVAL [COUNT]]` CLI
- [x] Reuse the qualified NodeInfo/ABBS adapter rather than adding new ABBS assumptions
- [x] Emit stable one-line machine-readable samples
- [x] Support bounded `COUNT` runs for deterministic qualification and `COUNT=0` for continuous monitoring
- [x] Add static and native-build gates
- [x] Add FS-UAE + AROS deterministic runtime smoke
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

### M2.2 — NodeCheck

- [x] Define deterministic node health-check contract and return-code semantics
- [x] Reuse the qualified NodeInfo/ABBS adapter
- [x] Implement stable machine-readable diagnostics
- [x] Add static and native-build gates
- [x] Add FS-UAE + AROS deterministic runtime smoke
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

### M2.3 — AssignCheck

- [x] Define conservative ABBS assign/volume checks without undocumented layout assumptions
- [x] Implement stable machine-readable diagnostics for `BBS:` and `ABBS:`
- [x] Add static and native-build gates
- [x] Add FS-UAE + AROS deterministic runtime smoke
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

### M2.4 — BBSDoctor

- [x] Define a conservative aggregate health contract over already-qualified checks
- [x] Implement stable machine-readable system/node summary without adding undocumented ABBS assumptions
- [x] Add static and native-build gates
- [x] Add FS-UAE + AROS deterministic runtime smoke
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

Automated qualification evidence is recorded in `docs/M2_4_QUALIFICATION.md`.

## M3 — Users, conferences and logs

### M3.1 — LastCalls

- [x] Implement read-only caller history from `ABBS:node<N>logfile`
- [x] Parse node, date, time, login mode and user without undocumented ABBS structures
- [x] Bound retained events and node scanning
- [x] Add static and native 68000 qualification
- [x] Add deterministic FS-UAE + AROS multinode runtime gate
- [x] Add full-buffer newest-event retention regression coverage
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

Automated qualification evidence is recorded in `docs/M3_1_QUALIFICATION.md`.

### M3.2 — LogInfo

- [x] Implement read-only node-log statistics using `ABBS:node<N>logfile`
- [x] Report log presence, line count, login count and logout count
- [x] Define missing-log warning behaviour
- [x] Add static and native 68000 qualification
- [x] Add deterministic FS-UAE + AROS runtime gate
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

Automated qualification evidence is recorded in `docs/M3_2_QUALIFICATION.md`.

### M3.3 — UserInfo

- [x] Establish a reliable ABBS user-data API or file-format contract from authoritative/reference material
- [x] Implement `UserInfo` without guessing database offsets or private layouts
- [x] Add static, native 68000 and deterministic runtime qualification
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

Automated qualification evidence is recorded in `docs/M3_3_QUALIFICATION.md`.

### M3.4 — ConfInfo

- [x] Establish a reliable ABBS conference-data API or file-format contract from authoritative/reference material
- [x] Implement `ConfInfo` without guessing database offsets or private layouts
- [x] Add static, native 68000 and deterministic runtime qualification
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

The source-backed conference contract is recorded in `docs/M3_4_CONF_CONTRACT.md`. Automated qualification evidence is recorded in `docs/M3_4_QUALIFICATION.md`.

## M4 — Doors and external programs

### M4.1 — DoorInfo

- [x] Establish a conservative source-backed/no-guess door inspection contract
- [x] Implement read-only `DoorInfo PATH`
- [x] Add static and native 68000 qualification
- [x] Add deterministic FS-UAE + AROS filesystem runtime qualification
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

Automated qualification evidence is recorded in `docs/M4_1_QUALIFICATION.md`.

### M4.2 — DoorCheck

- [x] Define a conservative validation contract without inventing a generic ABBS door registry or drop-file format
- [x] Implement `DoorCheck`
- [x] Add static, native 68000 and deterministic runtime qualification
- [ ] Qualify against live ABBS on intended AmigaOS 2.04 baseline

The M4.2 contract is recorded in `docs/M4_2_DOORCHECK_CONTRACT.md`. Automated qualification evidence is recorded in `docs/M4_2_QUALIFICATION.md`. ABBS-relevant drop-file inspection/validation remains deferred until a reliable source-backed contract is established.

## M5 — TCP and remote-node diagnostics

### M5.1 — TCPInfo

- [x] Define a conservative source-backed device availability contract for `abbstcp.device`
- [x] Implement `TCPInfo` without guessing socket state or undocumented device internals
- [x] Add static, native 68000 and deterministic runtime qualification
- [ ] Qualify against live ABBS/`abbstcp.device` on intended AmigaOS 2.04 baseline

The M5.1 contract is recorded in `docs/M5_1_TCPINFO_CONTRACT.md`. Automated qualification evidence is recorded in `docs/M5_1_QUALIFICATION.md`. Later M5 work may add Telnet/integration diagnostics only where a reliable device or protocol contract is established.

## M6 — Optional observability

Keep observability optional and non-invasive for classic systems. Candidate scope:

- Stable machine-readable output suitable for external collectors
- Optional `Metrics` exporter/snapshot tool with stable `abbs_` metric names
- Optional host-side exporter/bridge for Prometheus
- Node availability, session, error and activity metrics where ABBS exposes reliable data
- No mandatory TCP stack, daemon or Prometheus dependency on the Amiga itself
- Preserve normal standalone Shell/ARexx operation when observability is unused

Prometheus support is optional at runtime, but M6 is part of the v0.1.0 suite/release gate.

## v0.1.0 release target

The first release is the complete initial ABBSTools suite, not a technical preview. M0 through M6 are the v0.1.0 release scope; all planned tools and the optional observability integration must be implemented and qualified before tagging v0.1.0.

## Qualification strategy

Use automated build/static checks first, then runtime qualification in batches. Emulator-based smoke testing may use FS-UAE with a redistributable ROM environment where suitable; final compatibility claims should be backed by qualification on the intended AmigaOS baseline.
