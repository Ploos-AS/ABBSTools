# M3.1 Qualification — LastCalls

## Scope

M3.1 adds `LastCalls`, a read-only caller-history tool based on the established ABBS node-log convention `ABBS:node<N>logfile`. It does not depend on undocumented ABBS database layouts or private memory structures.

Production usage is:

- `LastCalls [COUNT]`

The production build scans node logs using the `ABBS:node` prefix. The CI-only trace build accepts a direct prefix and bounded node count so deterministic fixtures can be exercised without requiring a live ABBS installation.

## Contract

`LastCalls` parses valid `Login:` records and reports:

- node number
- date
- time
- login mode
- user name

Events are kept chronologically and only the newest requested entries are retained. The retained caller count is bounded to 50 and the node scan is bounded to 32 nodes.

Return codes follow the ABBSTools convention. A successful scan returns RC 0.

## Automated qualification

Final automated qualification commit:

- `710a0219bd7d840a4638b3057a15efc271361ba1`

GitHub Actions:

- Native build run: `34562981408` (#128) — **SUCCESS**
- FS-UAE AROS qualification run: `34562981413` (#123) — **SUCCESS**
- AROS Gate 9: `M3_1_AROS_LASTCALLS` — **PASS**
- Model: A1200
- Kickstart: internal AROS ROM environment

The final Gate 9 fixture is a full-buffer retention regression. It requests three callers while supplying five login events across two node logs. Node 1 fills the retention buffer before node 2 is scanned. A newer node-2 event must displace the oldest retained event, while an older late-scanned node-2 event must be ignored.

Expected retained chronological result:

1. `09/08-26 23:30` — node 1 — `Per Ousdal`
2. `10/08-26 00:10` — node 2 — `Bob User`
3. `10/08-26 00:20` — node 1 — `Alice Example`

The older `Old One` and `Too Old` events must not appear. Gate 9 passed this regression in run #123.

## Evidence artifact

- Artifact: `fs-uae-aros-m3-2-qualification`
- Artifact ID: `10185163086`
- Size: 72751 bytes
- Digest: `sha256:9061e4a6fb8e6e2ef24cbe5bb2cbd3ad265d7d57af6b4113f478221b1f3f7311`

The shared artifact contains Gate 9 LastCalls evidence together with the M3.2 LogInfo evidence and prior regression gates.

## Qualification boundary

This closes the static, native 68000 and deterministic FS-UAE/AROS portion of M3.1. It does **not** establish final compatibility against a live ABBS installation on the intended AmigaOS 2.04 baseline. Live ABBS qualification remains pending.
