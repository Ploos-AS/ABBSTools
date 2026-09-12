# M5.1 TCPInfo Qualification

## Scope

M5.1 qualifies the conservative `TCPInfo` device-availability probe for the source-backed `abbstcp.device` integration boundary.

This qualification intentionally does **not** claim socket state, Telnet state, remote-peer state, listener state, connection counts, or undocumented private device commands.

## Qualified commit

- Commit: `04fee01d1f04bdb506c2e97c61c35b8fb6e09335`
- Commit message: `CI: preserve TCPInfo RC10 evidence in AROS`

## Automated qualification result

### Native 68000 build

GitHub Actions build run #194 completed successfully.

The Bebbo toolchain gate builds `TCPInfo` for the 68000 AmigaOS baseline with the project native build policy and validates the resulting AmigaOS executable.

Result: **PASS**.

### FS-UAE + AROS runtime qualification

GitHub Actions FS-UAE/AROS run #189 (`34691047953`) completed successfully.

Gate 15 exercises two deterministic cases inside the AROS guest:

1. A deliberately nonexistent device (`definitely-missing.device`, unit `0`).
   - expected `STATUS=WARN`
   - expected `AVAILABLE=NO`
   - expected `REASON=DEVICE_OPEN_FAILED`
   - expected RC `5`
   - the numeric `OPEN_ERROR` is recorded but is not overfitted to a platform-specific constant

2. Invalid CLI input for the unit argument.
   - expected usage output
   - expected RC `10`

The guest harness preserves warning/error return codes so both cases can be observed without changing `TCPInfo` semantics.

Result: **PASS**.

All workflow gates 0 through 15 completed successfully in this run.

## Evidence artifact

- Artifact: `fs-uae-aros-m5-1-qualification`
- Artifact ID: `10296598772`
- SHA-256 digest: `92d48c7f8230b2713e55037a448939072813b26a77eef61cca9d81d3b4e9c035`
- Workflow run: `34691047953`

The artifact includes the native `TCPInfo` binary, native qualification evidence, AROS system-source evidence, Gate 15 result output, FS-UAE log, FS-UAE version information, and the generated FS-UAE configuration.

## What is qualified

M5.1 automated qualification demonstrates that:

- `TCPInfo` builds as a native 68000 AmigaOS executable;
- the device availability probe uses the documented AmigaOS device interface boundary;
- unavailable devices produce the defined warning semantics and RC 5;
- invalid CLI input produces RC 10;
- deterministic execution works under FS-UAE + AROS;
- no socket/Telnet/private-device state is invented by the tool.

## What remains unqualified

The following is still pending and must not be described as qualified:

- successful `OpenDevice()` against a real `abbstcp.device`;
- live ABBS integration;
- intended AmigaOS 2.04 baseline compatibility with the real device installed;
- any deeper device-specific diagnostic command or private ABI.

Live qualification should therefore test the same production `TCPInfo` binary against an installed, known-good `abbstcp.device` on the intended AmigaOS/ABBS environment.

## Verdict

**M5.1 automated qualification: PASS.**

**Live real-device / ABBS / AmigaOS 2.04 qualification: PENDING.**
