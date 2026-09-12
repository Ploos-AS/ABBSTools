# M4.1 DoorInfo contract

## Goal

`DoorInfo` begins M4 with a conservative, read-only diagnostic contract for ABBS external programs/doors without inventing an undocumented ABBS door database or drop-file format.

## Source evidence and boundary

The preserved ABBS 2.x source contains door-related code and symbols, including `FrontDoor`, `doparagondoor`, `paragonportname`, and `doorspath`. It also documents front-door login interaction through the public node message-port interface.

That evidence proves ABBS has external-program/door integration, but it does **not** by itself establish one universal public metadata database or one universal drop-file format suitable for safe generic parsing.

Therefore M4.1 deliberately does not guess:

- an internal door registry layout;
- a fixed `doorspath` value;
- a drop-file filename or record format;
- command-line arguments passed to every door;
- Paragon/front-door semantics as if they applied to every external program.

## Initial CLI

```text
DoorInfo PATH
```

The caller supplies the concrete AmigaDOS path to the external program/door to inspect.

This initial form answers a useful operational question without undocumented ABBS assumptions: does the configured external program path exist, what type of filesystem object is it, and what size is reported by AmigaDOS?

## Read-only fields

Stable machine-readable output:

```text
STATUS=OK
PATH=ABBS:Doors/MyDoor
PRESENT=YES
TYPE=FILE
SIZE=12345
```

For directories:

```text
STATUS=OK
PATH=ABBS:Doors
PRESENT=YES
TYPE=DIRECTORY
SIZE=0
```

Missing path:

```text
STATUS=WARN
PATH=ABBS:Doors/MissingDoor
PRESENT=NO
REASON=PATH_NOT_PRESENT
```

## Return codes

- RC 0: path exists and metadata was read successfully.
- RC 5: path does not exist.
- RC 10: invalid arguments or metadata/examine failure.
- RC 20: reserved for fatal setup/resource failures consistent with ABBSTools convention.

## Implementation rules

- Use AmigaDOS `Lock(..., ACCESS_READ)` and `Examine()` only.
- Do not write to or execute the target.
- Do not infer that every existing file is a valid ABBS door.
- Report filesystem object type conservatively as `FILE`, `DIRECTORY`, or `OTHER`.
- Keep path handling bounded and machine-readable output stable.

## Qualification

Initial deterministic qualification can use ordinary files/directories inside the AROS guest and therefore does not need a live ABBS door installation.

Final ABBS-specific qualification should later point `DoorInfo` at known-good and known-missing external-program paths on the intended live ABBS/AmigaOS 2.04 baseline.

## Follow-on M4 work

After M4.1 is qualified:

1. `DoorCheck` can aggregate existence/type expectations for configured paths once a source-backed configuration source is established.
2. Drop-file inspection should only be added after a real ABBS door/drop-file contract is located and documented.
3. Paragon/front-door diagnostics should remain a separate integration path if their public contracts are useful, rather than being silently generalized to all doors.
