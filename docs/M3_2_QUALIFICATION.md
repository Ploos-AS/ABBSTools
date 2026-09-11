# M3.2 Qualification — LogInfo

## Scope

M3.2 adds `LogInfo`, a read-only node-log statistics tool using the established `ABBS:node<N>logfile` convention. It deliberately avoids undocumented ABBS database layouts and private memory structures.

Production usage is:

- `LogInfo NODE`

The CI-only trace build accepts a direct log path so the parser contract can be tested deterministically.

## Contract

For a readable node log, `LogInfo` reports:

- `NODE=<n>`
- `LOG_PATH=<path>`
- `LOG_PRESENT=YES`
- `LINES=<count>`
- `LOGIN_RECORDS=<count>`
- `LOGOUT_RECORDS=<count>`

A present readable log returns RC 0. A missing log reports `LOG_PRESENT=NO`, zero counts and RC 5 (`WARN`). Invalid input returns the normal ABBSTools error code.

## Automated qualification

Final automated qualification commit:

- `710a0219bd7d840a4638b3057a15efc271361ba1`

GitHub Actions:

- Native build run: `34562981408` (#128) — **SUCCESS**
- FS-UAE AROS qualification run: `34562981413` (#123) — **SUCCESS**
- AROS Gate 10: `M3_2_AROS_LOGINFO` — **PASS**
- Model: A1200
- Kickstart: internal AROS ROM environment

The deterministic Gate 10 fixture contains seven lines with two `Login:` and two `Logout:` records. The expected contract is:

- RC: `0`
- `NODE=1`
- `LOG_PRESENT=YES`
- `LINES=7`
- `LOGIN_RECORDS=2`
- `LOGOUT_RECORDS=2`

Gate 10 passed in run #123. All earlier Gates 0–9 also remained green.

## Evidence artifact

- Artifact: `fs-uae-aros-m3-2-qualification`
- Artifact ID: `10185163086`
- Size: 72751 bytes
- Digest: `sha256:9061e4a6fb8e6e2ef24cbe5bb2cbd3ad265d7d57af6b4113f478221b1f3f7311`

The artifact contains native qualification evidence, Gate 10 output, FS-UAE evidence and the preceding regression-gate evidence.

## Qualification boundary

This closes the static, native 68000 and deterministic FS-UAE/AROS portion of M3.2. It does **not** establish final compatibility against a live ABBS installation on the intended AmigaOS 2.04 baseline. Live ABBS qualification remains pending.
