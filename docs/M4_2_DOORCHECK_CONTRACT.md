# M4.2 DoorCheck contract

## Purpose

`DoorCheck` validates a concrete AmigaDOS path against an explicit expected object type. It is intentionally conservative: it does not discover doors, infer a global ABBS door directory, parse undocumented ABBS door registries, execute the target, or assume a universal drop-file format.

## CLI

```text
DoorCheck PATH EXPECTED_TYPE
```

`EXPECTED_TYPE` is one of:

- `FILE`
- `DIRECTORY`
- `ANY`

## Checks

The tool performs read-only filesystem inspection using `Lock(..., ACCESS_READ)` and `Examine()`.

For an existing path it determines the actual type from `fib_DirEntryType`:

- negative: `FILE`
- positive: `DIRECTORY`
- zero: `OTHER`

`ANY` accepts any existing object type. `FILE` and `DIRECTORY` require an exact type match.

## Stable output

Success:

```text
STATUS=OK
PATH=ABBS:Doors/MyDoor
PRESENT=YES
EXPECTED_TYPE=FILE
ACTUAL_TYPE=FILE
RESULT=MATCH
```

Missing path:

```text
STATUS=WARN
PATH=ABBS:Doors/MyDoor
PRESENT=NO
EXPECTED_TYPE=FILE
RESULT=PATH_NOT_PRESENT
```

Type mismatch:

```text
STATUS=WARN
PATH=ABBS:Doors/MyDoor
PRESENT=YES
EXPECTED_TYPE=FILE
ACTUAL_TYPE=DIRECTORY
RESULT=TYPE_MISMATCH
```

Inspection error after a successful lock:

```text
STATUS=ERROR
PATH=...
PRESENT=YES
EXPECTED_TYPE=...
RESULT=EXAMINE_FAILED
```

## Return codes

- RC 0: path exists and satisfies the expected type.
- RC 5: path is absent, or exists but does not satisfy the expected type.
- RC 10: invalid CLI/expected type, or metadata inspection failed.
- RC 20: reserved for fatal setup/resource failures.

## Safety and scope boundaries

- Read-only filesystem access.
- Never executes the inspected target.
- Does not claim that an existing file is a valid ABBS door.
- Does not infer a fixed `ABBS:Doors` path; callers supply the concrete path.
- Does not parse or invent undocumented door registry/configuration structures.
- Does not invent a generic ABBS drop-file filename or layout.

If a reliable source-backed ABBS door configuration or drop-file contract is established later, a separate ABBS-specific validation layer may build on this primitive.

## Qualification

Automated qualification should cover at least:

1. existing file + `FILE` => RC 0 / MATCH
2. existing directory + `DIRECTORY` => RC 0 / MATCH
3. existing file + `DIRECTORY` => RC 5 / TYPE_MISMATCH
4. missing path => RC 5 / PATH_NOT_PRESENT
5. existing file + `ANY` => RC 0 / MATCH

Production runtime qualification should exercise the real filesystem implementation under FS-UAE + AROS, not only a trace stub.
