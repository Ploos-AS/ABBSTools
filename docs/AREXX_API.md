# ABBSTools ARexx API Conventions

## Principles

- Shell use and ARexx automation are equally important interfaces.
- Commands should be deterministic and script-friendly.
- Human-readable Shell output must not prevent structured ARexx results.

## Port naming

Preferred form: `ABBSTOOLS.<TOOLNAME>`.

Examples: `ABBSTOOLS.REXXPORTS`, `ABBSTOOLS.REXXPROBE`, `ABBSTOOLS.NODEINFO`.

## Common commands

Where applicable: `HELP`, `VERSION`, `INFO`, `STATUS`, `QUIT`.

## Return codes

- `0` — success
- `5` — warning / non-fatal condition
- `10` — error
- `20` — fatal error

## RESULT and stems

Simple commands should return a useful value through `RESULT` when practical. Structured commands should support a caller-provided stem where practical.

Example target usage:

```rexx
ADDRESS ABBSTOOLS.NODEINFO
'GET NODE 2 STEM N.'

say N.NODE
say N.USER
say N.STATUS
say N.CONFERENCE
say N.TIMELEFT
```

The exact NodeInfo field set will be defined after the ABBS node interface has been qualified.

## Stability

Once an ARexx command or stem field is documented as stable, incompatible changes should require an explicit interface-version change.
