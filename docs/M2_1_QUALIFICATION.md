# M2.1 NodeWatch qualification

## Automated qualification

M2.1 NodeWatch passed the automated native-build and FS-UAE + AROS runtime gates on commit `4fd6087129c6f1f11e0e53a03193719aa8780ed7`.

GitHub Actions FS-UAE AROS qualification run:

- Run: `#81`
- Run ID: `34502492188`
- Job: `aros-runtime`
- Job ID: `102956433584`
- Conclusion: `success`

All workflow gates completed successfully. Gate 5 specifically executed the deterministic NodeWatch polling smoke inside the AROS guest.

## Gate 5 contract

The CI-only trace variant is invoked with a deterministic active-session fixture and a bounded two-sample run. Production NodeWatch retains the public CLI:

```text
NodeWatch NODE [INTERVAL [COUNT]]
```

The runtime smoke exercises:

- native 68000 executable execution in the guest
- the shared NodeInfo/ABBS adapter path
- finite `COUNT=2` polling
- one-second polling delay
- stable one-line machine-readable sample output
- deterministic active-session fixture parsing
- successful bounded completion with RC 0

The expected samples are:

```text
SAMPLE=1 NODE=1 PRESENT=0 STATE=OFFLINE LOG_PRESENT=1 SESSION=ACTIVE USER=Test User
SAMPLE=2 NODE=1 PRESENT=0 STATE=OFFLINE LOG_PRESENT=1 SESSION=ACTIVE USER=Test User
```

## Evidence artifact

- Artifact: `fs-uae-aros-m2-1-qualification`
- Artifact ID: `10163070541`
- SHA-256: `9e2d07d53ae2705e5c1dfdd303a20b3b2975ceb38bb6667715bda8d840198da0`

## Qualification boundary

This is automated AROS guest runtime evidence. It does **not** constitute final compatibility qualification against a live ABBS installation on the intended AmigaOS 2.04 baseline.

The RexxProbe workflow gate in the same qualification remains subject to the existing AROS capability limitation: `rexxsyslib.library` is not loadable in that environment, so RexxProbe records a controlled capability SKIP rather than an end-to-end runtime PASS.

## Result

M2.1 NodeWatch automated qualification: **PASS**.

Remaining M2.1 qualification work: live ABBS / AmigaOS 2.04 baseline qualification.
