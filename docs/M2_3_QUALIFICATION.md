# M2.3 Qualification — AssignCheck

## Scope

M2.3 adds `AssignCheck`, a conservative read-only diagnostic for the documented/known `BBS:` and `ABBS:` paths without relying on undocumented ABBS memory layouts or offsets.

Production behaviour remains fixed to the real `BBS:` and `ABBS:` paths. The automated AROS qualification uses a CI-only trace build with direct paths so the guest test can exercise the same presence/health logic deterministically without mutating assigns in the boot Startup-Sequence.

## Automated qualification

Commit qualified:

- `8c1b26d2fce005c1266f143334ce10c79b700e8c`

GitHub Actions:

- FS-UAE AROS qualification run: `34528561353` (#98)
- Job: `103043384929` (`aros-runtime`)
- Result: **SUCCESS**
- Gate: `M2_3_AROS_ASSIGNCHECK`
- Model: A1200
- Kickstart: internal AROS ROM environment
- FS-UAE exit: 124 (expected external timeout after evidence was written)

Native Bebbo gate in the same run:

- `STATUS=PASS`
- `GATE=M2_3_NATIVE_BEBBO`
- Compiler image: `amigadev/m68k-amigaos-gcc@sha256:b18080e6ffca8f793e0f539536a9138e9d2a548ca1a301c7483f43ee15fedfed`
- Production `AssignCheck` SHA-256: `064f24cf3379962ae97429634d3e34855849a1de316a176979bdd95667ef5714`
- CI trace `AssignCheckTrace` SHA-256: `bde2031f6f409aabc3c17d84d73ce048aa407155da4cfa8284076643a09928fb`

## AROS deterministic matrix

The guest completed every stage:

- `STAGE_STARTED=1`
- `STAGE_BOTH_DONE=1`
- `STAGE_BBS_ONLY_DONE=1`
- `STAGE_NONE_DONE=1`
- `STAGE_DONE=1`

Observed cases:

### Both paths present

- RC: `0`
- `BBS_PRESENT=1`
- `ABBS_PRESENT=1`
- `HEALTH=OK`
- `REASON=NONE`

### BBS present, ABBS missing

- RC: `5`
- `BBS_PRESENT=1`
- `ABBS_PRESENT=0`
- `HEALTH=WARN`
- `REASON=ABBS_NOT_PRESENT`

### Both paths missing

- RC: `5`
- `BBS_PRESENT=0`
- `ABBS_PRESENT=0`
- `HEALTH=WARN`
- `REASON=BBS_AND_ABBS_NOT_PRESENT`

Gate result:

- `STATUS=PASS`
- `OBSERVATION=guest_executed_assigncheck_matrix_direct_paths`

## Evidence artifact

- Artifact: `fs-uae-aros-m2-3-qualification`
- Artifact ID: `10172792783`
- Size: 40980 bytes
- Digest: `sha256:99a7002a8d406fe1c61369c45c5e0b8ab8df0ea3c3a71c23216c103cd2a9df06`

## Qualification boundary

This closes the automated/static/native/AROS portion of M2.3. It does **not** establish final compatibility against a live ABBS installation on the intended AmigaOS 2.04 baseline. That remains a separate qualification item.
