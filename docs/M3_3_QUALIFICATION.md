# M3.3 UserInfo qualification

## Scope

M3.3 establishes and implements the read-only `UserInfo` path using the preserved public ABBS main-port ABI rather than guessed userfile offsets or private database layouts.

The implementation uses the public `ABBS mainport` message interface, obtains the runtime user-record size through `Main_Getconfig`, allocates that exact bounded size, and performs a read-only `Main_loaduser` lookup. Sensitive fields such as password and phone data are not emitted.

## Source-backed contract

The ABI contract and its source evidence are recorded in `docs/M3_3_USER_CONTRACT.md`. The adapter is aligned with the preserved ABBS 2.x `struct ABBSmsg` field order/types and the verified command/error constants used by the public main-port interface.

This closes the static ABI uncertainty for M3.3. It does not by itself constitute a live ABBS/AmigaOS 2.04 runtime qualification.

## Automated qualification

Qualified head:

- Commit: `b59e6f35b9bbda169da849aae51ea6b376531fc3`

GitHub Actions:

- Native build workflow: build #153 — PASS
- FS-UAE AROS qualification #148 — PASS
- Workflow run: `34609406015`
- Runtime job: `103295818908` — PASS
- Gates 0 through 11: PASS

Gate 11 executes the deterministic `UserInfo` trace fixture inside the AROS guest and verifies:

- `STATUS=OK`
- `NAME=Per Ousdal`
- `USER_NR=42`
- `RECORD_SIZE=512`
- return code 0

The shared AROS system-image discovery/fetch gate also passed in this run, followed by all prior ABBSTools runtime gates.

## Evidence artifact

- Artifact: `fs-uae-aros-m3-3-qualification`
- Artifact ID: `10268370533`
- Size: 80,599 bytes
- SHA-256 digest: `3f6c3edce65299725612b6659e0ff1869e146225316faec02d68769f41691d9a`
- Expires: 2026-12-10

## Result

Automated M3.3 qualification: **PASS**.

Remaining before a final compatibility claim:

- Run `UserInfo` against a live ABBS installation on the intended AmigaOS 2.04+ / 68000-compatible baseline.
- Confirm the preserved ABBS 2.x public main-port contract behaves as expected on the intended ABBS version.

Until that live qualification is complete, documentation must distinguish the automated deterministic PASS from final live ABBS compatibility qualification.
