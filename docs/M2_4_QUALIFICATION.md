# M2.4 Qualification — BBSDoctor

## Scope

M2.4 adds `BBSDoctor`, a conservative read-only aggregate health diagnostic over checks already established by ABBSTools. It combines `BBS:` / `ABBS:` path presence with the existing ABBS node adapter and session-log state without introducing undocumented ABBS memory layouts, offsets or private structures.

Production behaviour remains fixed to `BBS:`, `ABBS:` and the normal `ABBS:nodeNlogfile` path. The automated AROS qualification uses the CI-only trace build with direct BBS, ABBS and log paths so the aggregate contract can be exercised deterministically without mutating guest assigns.

## Aggregate health contract

The current precedence is intentionally deterministic:

1. Both `BBS:` and `ABBS:` absent → `WARN / BBS_AND_ABBS_NOT_PRESENT`
2. `BBS:` absent → `WARN / BBS_NOT_PRESENT`
3. `ABBS:` absent → `WARN / ABBS_NOT_PRESENT`
4. ABBS adapter unqualified → `WARN / ABBS_INTERFACE_NOT_QUALIFIED`
5. Node query failure → `ERROR / NODE_QUERY_FAILED`
6. Node public port absent → `WARN / PORT_NOT_PRESENT`
7. Node log absent → `WARN / LOG_NOT_PRESENT`
8. Session state unknown → `WARN / SESSION_UNKNOWN`
9. Otherwise → `OK / NONE`

Return codes follow the ABBSTools convention: 0 success, 5 warning, 10 error.

## Automated qualification

Commit qualified:

- `f748bd06a5b33dfc26f640afde5c4dd054a9ac5e`

GitHub Actions:

- Native build run: `34538951325` (#109)
- Native job: `103076954581` (`m68k-build`)
- Native result: **SUCCESS**
- FS-UAE AROS qualification run: `34538951333` (#104)
- AROS job: `103076954505` (`aros-runtime`)
- AROS result: **SUCCESS**
- Gate: `M2_4_AROS_BBSDOCTOR`
- Model: A1200
- Kickstart: internal AROS ROM environment

The native gate is `M2_4_NATIVE_BEBBO` and uses the pinned Bebbo image:

- `amigadev/m68k-amigaos-gcc@sha256:b18080e6ffca8f793e0f539536a9138e9d2a548ca1a301c7483f43ee15fedfed`

Both production `BBSDoctor` and CI-only `BBSDoctorTrace` are built as 68000 Amiga executables under `-Wall -Wextra -Werror`.

## AROS deterministic matrix

Gate 8 executes `BBSDoctorTrace` in the AROS guest using direct fixture paths.

### Both paths present, active session fixture, no live ABBS node port

Expected and observed contract:

- RC: `5`
- `HEALTH=WARN`
- `REASON=PORT_NOT_PRESENT`
- `BBS_PRESENT=1`
- `ABBS_PRESENT=1`
- `NODE=1`
- `PRESENT=0`
- `STATE=OFFLINE`
- `LOG_PRESENT=1`
- `SESSION=ACTIVE`
- `USER=Test User`

This case deliberately does not create an artificial `ABBS node #1 port`; the AROS test therefore proves aggregate precedence without pretending to be a live ABBS installation.

### BBS present, ABBS missing

- RC: `5`
- `HEALTH=WARN`
- `REASON=ABBS_NOT_PRESENT`
- `BBS_PRESENT=1`
- `ABBS_PRESENT=0`

### Both paths missing

- RC: `5`
- `HEALTH=WARN`
- `REASON=BBS_AND_ABBS_NOT_PRESENT`
- `BBS_PRESENT=0`
- `ABBS_PRESENT=0`

Gate result: **PASS**. All previous FS-UAE/AROS Gates 0–7 also remained green in run #104.

## Evidence artifact

- Artifact: `fs-uae-aros-m2-4-qualification`
- Artifact ID: `10176746573`
- Size: 53617 bytes
- Digest: `sha256:1a25dddc5422b0c4a52654f4eb266dfa3807c16cae07fa321ccfba9bb04f6630`

The artifact includes the production and trace BBSDoctor binaries, native build evidence, Gate 8 result, FS-UAE log/version/config and the earlier regression-gate evidence.

## Qualification boundary

This closes the static, native 68000 and deterministic FS-UAE/AROS portion of M2.4. It does **not** establish final compatibility against a live ABBS installation on the intended AmigaOS 2.04 baseline. Live ABBS qualification remains a separate unchecked item.
