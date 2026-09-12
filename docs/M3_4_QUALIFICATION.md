# M3.4 ConfInfo qualification

## Scope

M3.4 implements read-only `ConfInfo CONFERENCE` using the source-backed ABBS main-port/config contract recorded in `docs/M3_4_CONF_CONTRACT.md`.

The implementation does not parse the ABBS config file directly. It uses `Main_Getconfig`, validates the returned config pointer/sentinel, bounds `Maxconferences`, and copies only the selected `ConferenceRecord` into bounded local output fields.

## Qualified head

- Commit: `dacd2103255491dfad4a4cbf02d71b3350514acd`

## GitHub Actions

- Native build workflow: build #160 — PASS
- FS-UAE AROS qualification #155 — PASS
- Workflow run: `34623986263`
- Runtime job: `103344513100` — PASS
- Gates 0 through 12: PASS

Gate 12 executes the deterministic `ConfInfo` fixture in the AROS guest and validates the stable machine-readable conference output and RC 0 path.

## Evidence artifact

- Artifact: `fs-uae-aros-m3-4-qualification`
- Artifact ID: `10273482414`
- Size: 88,696 bytes
- SHA-256 digest: `c0ddcca7b4dd671515fbf6e80b33b435caf284f1a9b152bb5fc76a6a32c0ca81`
- Expires: 2026-12-10

## Result

Automated M3.4 qualification: **PASS**.

Remaining before a final compatibility claim:

- Run `ConfInfo` against a live ABBS installation on the intended AmigaOS 2.04+ / 68000-compatible baseline.
- Confirm the preserved ABBS 2.x conference/config contract matches the intended live ABBS version.

Until that live qualification is complete, documentation must distinguish deterministic automated PASS from final live ABBS compatibility qualification.
