# M4.2 DoorCheck qualification

## Qualified revision

- Commit: `4552d2eafb5baf90ec43fcb011e6a486b378b6d0`
- Target baseline: Motorola 68000 / AmigaOS 2.04+
- Automated guest environment: FS-UAE + AROS

## Automated results

- Native build workflow: build #180 / run `34671193334` — PASS
- FS-UAE AROS qualification: #175 / run `34671193322` — PASS
- Gates 0 through 14 — PASS
- Gate 14 exercised production `DoorCheck` against guest filesystem fixtures for:
  - matching type (`MATCH`, RC 0)
  - mismatched type (`TYPE_MISMATCH`, RC 5)
  - missing path (`PATH_NOT_PRESENT`, RC 5)

## Evidence artifact

- Name: `fs-uae-aros-m4-2-qualification`
- Artifact ID: `10291230479`
- SHA-256: `527a6e040d5a13e0e41d310c2cd147dcb0a9c7d703de0c1d54ce742ccaebd208`
- Expires: 2026-12-11

## CI robustness note

During the first Gate 14 qualification attempt, an earlier NodeInfo guest gate failed before its startup marker was reached. No NodeInfo code regression was observed. The NodeInfo guest harness was hardened with one controlled retry for that startup race; a second failed startup still causes the gate to fail. The final qualified run passed Gates 0 through 14.

## Verdict

Automated M4.2 qualification is PASS for static checks, native 68000 build, and deterministic filesystem runtime behaviour under FS-UAE + AROS.

Final compatibility qualification against live ABBS on the intended AmigaOS 2.04 baseline remains pending. This document does not claim that final live-baseline qualification.
