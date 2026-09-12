# M4.1 DoorInfo qualification

## Qualified revision

- Commit: `170b533d36b1636495aa44d97765c2c1ea8e2956`
- Target baseline: Motorola 68000 / AmigaOS 2.04+
- Automated guest environment: FS-UAE + AROS

## Automated results

- Native build workflow: build #167 / run `34666797292` — PASS
- FS-UAE AROS qualification: #162 / run `34666797291` — PASS
- Gates 0 through 13 — PASS
- Gate 13 exercised production `DoorInfo` against guest filesystem fixtures, including an existing file and a missing path.

## Evidence artifact

- Name: `fs-uae-aros-m4-1-qualification`
- Artifact ID: `10289463463`
- SHA-256: `ac40fb22ae5bfe24b5fafc54acee64f8cb40c6e89c4512b94c4076a30fdd080f`
- Expires: 2026-12-11

## Verdict

Automated M4.1 qualification is PASS for static checks, native 68000 build, and deterministic filesystem runtime behaviour under FS-UAE + AROS.

Final compatibility qualification against live ABBS on the intended AmigaOS 2.04 baseline remains pending. This document does not claim that final live-baseline qualification.
