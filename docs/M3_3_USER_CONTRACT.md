# M3.3 — ABBS user interface contract

## Purpose

Establish a source-backed contract for `UserInfo` before implementation. ABBSTools must not infer private ABBS database offsets or duplicate an on-disk layout when ABBS already exposes a public message-port interface.

## Primary evidence

The preserved ABBS 2.x source tree at `ResistanceVault/preservation-abbs20`, commit `a51658289061a60392954187d2fe4bd209703a9d`, contains the original public definitions and utilities used here as historical interface evidence.

`Include/bbs.h` defines:

- main public port name: `ABBS mainport`
- `struct ABBSmsg`
- `Main_loaduser = 0`
- `Main_getusername = 3`
- `Main_getusernumber = 4`
- `Main_loadusernr = 25`
- `Main_Getconfig = 46`
- public error values including `Error_OK`, `Error_Not_Found`, `Error_Read`, `Error_NoMem` and `Error_NoPort`
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

A second preserved utility uses `Main_loadusernr` with `msg.UserNr` and a caller-provided user buffer, establishing lookup by numeric user number as a supported main-port operation.

`JEO/Broadcast.c` documents the public message exchange pattern:

1. create a reply `MsgPort`;
2. find `ABBS mainport`;
3. `PutMsg()` an `ABBSmsg` to the main port;
4. wait on the reply port;
5. retrieve the replied `ABBSmsg`;
6. use `msg.Error` as the ABBS result.

## On-disk evidence

`JEO/CheckUserfile.c` establishes the historical files `userfile`, `userfile.index`, `userfile.nrindex` and `configfile`, and demonstrates the relationship between `Log_entry.l_RecordNr`, `l_UserNr`, `l_Name` and `UserRecord` records.

This is useful forensic/compatibility evidence, but **M3.3 UserInfo will not use direct userfile parsing as its primary interface**. Direct parsing would couple ABBSTools to record layout, compiler packing and ABBS-version details that the public main-port API can avoid.

## Qualified implementation direction

`UserInfo` should be a read-only client of `ABBS mainport`.

Initial CLI contract:

```text
UserInfo USER
```

`USER` may initially be a username. Numeric lookup can be added through the same adapter once its exact command semantics are covered by deterministic tests.

The adapter should:

1. find `ABBS mainport`;
2. create a private reply port;
3. call `Main_Getconfig` to obtain the live `UserrecordSize`;
4. allocate a zeroed buffer of exactly that size;
5. call `Main_loaduser` with the requested name and buffer;
6. copy only explicitly supported fields into an ABBSTools-owned result structure before freeing the ABBS buffer;
7. never modify or save the returned record.

Initial safe output fields should be limited to fields demonstrated by preserved ABBS code and useful for diagnostics, for example:

- `NAME`
- `USER_NR`
- `CITY_STATE`
- `TIMES_ON`
- `MSGS_LEFT`
- `MSGS_READ`
- `TOTAL_TIME`
- `UPLOADED`
- `DOWNLOADED`
- `KB_UPLOADED`
- `KB_DOWNLOADED`

Sensitive fields such as password and telephone numbers must not be emitted by `UserInfo`.

## Compatibility boundary

The preserved source is ABBS 2.x evidence. ABBSTools targets the user's ABBS environment and AmigaOS 2.04+, so this contract is **source-backed but not yet runtime-qualified against the intended live ABBS version**.

Therefore M3.3 implementation must keep the ABBS main-port details behind a small adapter and retain a live qualification item before final compatibility claims.

## Decision

M3.3 is no longer blocked on an unknown user database layout. A public ABBS main-port contract exists and is preferable to direct database parsing.

Next implementation step: add the minimal main-port request adapter plus a conservative `UserInfo` foundation, with CI trace/fake-adapter coverage first and live ABBS qualification later.
