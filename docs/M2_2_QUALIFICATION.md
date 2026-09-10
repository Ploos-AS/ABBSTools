# M2.2 NodeCheck qualification

NodeCheck has passed the automated native 68000 build/static gate and the deterministic FS-UAE + AROS runtime gate on `main`.

## Qualified commit

- Commit: `f068284fef8e69ee9370cd3ef09bd07b44646a08`
- Native compiler: Bebbo `m68k-amigaos-gcc` 6.5.0b
- CPU baseline: Motorola 68000
- Link/runtime model: `-noixemul`

## Native gate

The M2.2 native gate passed with `GATE=M2_2_NATIVE_BEBBO`. Both production `NodeCheck` and CI-only `NodeCheckTrace` were validated as AmigaOS loadseg executables.

Production NodeCheck SHA-256 at qualification time:

`5f5be427948f39d8197a56cc80baf0a6ce35bcbd41426cb1a9cefc7d805d181b`

## FS-UAE + AROS runtime gate

Workflow run: `FS-UAE AROS qualification` #89, rerun attempt that completed successfully.

The runtime job passed all applicable gates through Gate 6, including:

- Gate 4: deterministic NodeInfo session fixtures
- Gate 5: NodeWatch polling
- Gate 6: NodeCheck fixture matrix

The first attempt of the runtime job stopped at Gate 5 with `guest_startup_not_reached`; a rerun without code changes passed Gate 5 and Gate 6. This is recorded as an emulator/guest-startup transient rather than a NodeCheck product failure.

Latest successful qualification artifact:

- Name: `fs-uae-aros-m2-2-qualification`
- Artifact ID: `10166748521`
- SHA-256: `c68aa808cd71748a7cd2f5854b4f958eccbce87f2f9cee907b72ee1312bccac6`

## Scope and caveats

This qualification proves the M2.2 executable builds for the selected 68000/Bebbo baseline and that its deterministic fixture paths execute under the redistributable AROS guest used by CI.

It does **not** yet prove final compatibility with a live ABBS installation on AmigaOS 2.04. That remains a separate local/runtime qualification gate.

The RexxProbe AROS capability gate remains a controlled SKIP where `rexxsyslib.library` is present but not loadable; that does not affect the NodeCheck Gate 6 result.
