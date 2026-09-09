# M1.2 — RexxProbe

M1.2 adds `RexxProbe`, a small native Shell utility for sending one command to an ARexx public port and reporting the reply in a scriptable form.

## Implemented behaviour

`RexxProbe PORT COMMAND` opens `rexxsyslib.library`, creates a private reply port and a `RexxMsg`, requests `RXFF_RESULT`, resolves the destination public port, sends the message and waits for the reply.

The shared helper lives in `src/common/arexx.c` with its public interface in `include/abbstools/arexx.h`.

Result handling follows ARexx ownership rules:

- `rm_Result1 == 0`: a non-zero `rm_Result2` is treated as a returned result Argstring, copied into the bounded `AbtRexxResult.text` buffer, then released with `DeleteArgstring()`.
- `rm_Result1 != 0`: `rm_Result2` is retained as the numeric secondary result/error value.
- Returned result text is bounded to 255 characters plus NUL; `truncated` reports clipping.

## Shell output

Successful remote command:

```text
PORT=<port>
COMMAND=<command>
RESULT1=0
RESULT=<text>
TRUNCATED=0|1
```

Remote command error:

```text
PORT=<port>
COMMAND=<command>
RESULT1=<primary>
RESULT2=<secondary>
```

Local setup failures use stable symbolic output:

- missing public port: `PORT_NOT_FOUND`, Shell RC 10
- local ARexx setup failure: `AREXX_SETUP_ERROR`, Shell RC 20

A remote ARexx error maps to ABBSTools warning RC 5 while preserving the remote primary and secondary codes in the output.

## Wait and timeout semantics

M1.2 intentionally does not implement a hard timeout after `PutMsg()`.

Before delivery, a missing destination port is detected immediately and returns RC 10. After a message has been delivered, ownership is shared with the receiving task until it replies. Abandoning and freeing the message on a timer would be unsafe because the receiver may still hold the message pointer. Therefore M1.2 waits for the ARexx host reply with `WaitPort()`.

A future cancellable/timeout-capable transport must introduce an explicit protocol or ownership-safe cancellation mechanism rather than freeing an outstanding message.

## Qualification

Automated qualification consists of:

1. static M1.2 repository checks;
2. Bebbo `m68k-amigaos-gcc` cross-build with `-m68000 -noixemul` and warnings treated as errors;
3. an FS-UAE + AROS capability/runtime gate for `RexxProbe`.

The first AROS run on 2026-09-09 executed the native `RexxProbe` binary but returned `rexxsyslib.library failed to load`. Inspection of the same AROS boot-ISO environment showed that `rexxsyslib.library` is not present in that minimal core image. This is therefore classified as an environment limitation, not a RexxProbe runtime PASS or a RexxProbe regression.

The CI gate now checks the extracted AROS image before execution. If `rexxsyslib.library` is absent it records `STATUS=SKIP`, `REASON=AROS_BOOT_ISO_NO_REXXSYSLIB` and exits successfully so unrelated AROS qualification remains useful. If the library is present, the gate executes `RexxProbe` against a deliberately nonexistent port and requires `PORT_NOT_FOUND` with guest Shell RC 10.

M1.2 runtime qualification remains open until RexxProbe is exercised in an environment that actually provides `rexxsyslib.library`. End-to-end qualification against a deterministic ARexx host and final compatibility qualification on the intended AmigaOS 2.04 baseline remain separate release gates.
