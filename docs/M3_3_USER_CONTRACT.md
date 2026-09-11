# M3.3 — ABBS user interface contract

## Purpose

Establish a source-backed contract for `UserInfo` before implementation. ABBSTools must not infer private ABBS database offsets or duplicate an on-disk layout when ABBS already exposes a public message-port interface.

## Primary evidence

The preserved ABBS 2.x source tree at `ResistanceVault/preservation-abbs20`, commit `a51658289061a60392954187d2fe4bd209703a9d`, contains the original public definitions and utilities used here as historical interface evidence.

`Include/bbs.h` defines:

- main public port name: `ABBS mainport`
- exact public `struct ABBSmsg` field order: `Message`, `UWORD Command`, `UWORD Error`, `ULONG Data`, `char *Name`, `ULONG UserNr`, `ULONG arg`
- `Main_loaduser = 0`
- `Main_getusername = 3`
- `Main_getusernumber = 4`
- `Main_loadusernr = 25`
- `Main_Getconfig = 46`
- `Error_OK = 0`
- `Error_Not_Found = 1`
- `Error_NoMem = 17`
- `Error_NoPort = 18`
- `NameT` is `char[31]`
- `struct UserRecord`
- `struct Log_entry`

The preserved `JEO/UserEditor.c` demonstrates a real ABBS utility loading a user through the main port rather than parsing `userfile` directly:

```c
msg.Command = Main_loaduser;
msg.Name    = name;
msg.Data    = (ULONG)curuser;
n = HandleMsg(&msg);
```

It first obtains the live configuration using `Main_Getconfig`, then allocates `config->UserrecordSize` bytes for the user buffer. This is important: the runtime record size is obtained from ABBS rather than assumed from a compile-time `sizeof(struct UserRecord)`.

Preserved utilities such as `JEO/ZapFile.c` and `JEO/UserEditor.c` also establish an additional `Main_Getconfig` success condition: after `HandleMsg()` returns `Error_OK`, `msg.UserNr` must be non-zero before `msg.Data` is accepted as the live configuration pointer. ABBSTools therefore validates all three conditions: `Error_OK`, non-zero `UserNr`, and non-null `Data`.

A second preserved utility uses `Main_loadusernr` with `msg.UserNr` and a caller-provided user buffer, establishing lookup by numeric user number as a supported main-port operation.

The preserved `HandleMsg()` implementation demonstrates the public message exchange pattern:

1. use a reply `MsgPort`;
2. `Forbid()` and find `ABBS mainport`;
3. `PutMsg()` an `ABBSmsg` to the main port;
4. `Permit()`;
5. wait on the reply port;
6. retrieve the replied `ABBSmsg`;
7. return `msg.Error`, or `Error_NoPort` if the public main port does not exist.

## On-disk evidence

`JEO/CheckUserfile.c` establishes the historical files `userfile`, `userfile.index`, `userfile.nrindex` and `configfile`, and demonstrates the relationship between `Log_entry.l_RecordNr`, `l_UserNr`, `l_Name` and `UserRecord` records.

This is useful forensic/compatibility evidence, but **M3.3 UserInfo will not use direct userfile parsing as its primary interface**. Direct parsing would couple ABBSTools to record layout, compiler packing and ABBS-version details that the public main-port API can avoid.

## Qualified implementation direction

`UserInfo` is a read-only client of `ABBS mainport`.

Initial CLI contract:

```text
UserInfo USER
```

`USER` may initially be a username. Numeric lookup can be added through the same adapter once its exact command semantics are covered by deterministic tests.

The adapter:

1. finds `ABBS mainport`;
2. creates a private reply port;
3. calls `Main_Getconfig` and requires `Error_OK`, non-zero `UserNr`, and non-null `Data`;
4. obtains the live `UserrecordSize` from the returned configuration;
5. allocates a zeroed buffer of exactly that size;
6. calls `Main_loaduser` with the requested name and buffer;
7. copies only explicitly supported fields into an ABBSTools-owned result structure before freeing the ABBS buffer;
8. never modifies or saves the returned record.

Initial safe output is intentionally conservative:

- `NAME`
- `USER_NR`
- `RECORD_SIZE`

Sensitive fields such as password and telephone numbers are not emitted by `UserInfo`.

## ABI verification status

The production adapter has now been compared directly with the preserved public ABBS 2.x definitions. The following are source-verified:

- `struct ABBSmsg` field order and types used by the adapter;
- `Main_loaduser = 0`;
- `Main_Getconfig = 46`;
- `Error_Not_Found = 1`;
- `Error_NoPort = 18`;
- 31-byte `NameT` storage;
- `UserRecord` begins with `NameT Name`, `UBYTE pass_10`, `ULONG Usernr`;
- `ConfigRecord` exposes the runtime `UserrecordSize` used by preserved ABBS utilities;
- `Main_Getconfig` requires the non-zero `UserNr` success sentinel before using `Data`.

This closes the known static ABI uncertainty in the M3.3 adapter. It does **not** replace live qualification against the intended ABBS installation.

## Compatibility boundary

The preserved source is ABBS 2.x evidence. ABBSTools targets the user's ABBS environment and AmigaOS 2.04+, so this contract is source-backed and the adapter ABI is statically verified, but it is **not yet runtime-qualified against the intended live ABBS version**.

Therefore M3.3 retains a live qualification item before final compatibility claims.

## Decision

M3.3 is no longer blocked on an unknown user database layout or an unverified public-message ABI. A source-backed ABBS main-port contract exists and is preferable to direct database parsing.

Next step: keep CI/native/AROS qualification green with the verified adapter, then perform live ABBS/AmigaOS qualification when the real ABBS environment is available.
