# M1.3b — ABBS node port presence

M1.3b replaces the conservative `NodeInfo` adapter stub with the first qualified live ABBS signal: the public Exec/ARexx node port.

## Qualified interface

Existing ABBS door code in `pgousdal/ABBS-LastCallers` documents that an A-type door inherits the current node ARexx host in the form:

```text
ABBS node #<n> port
```

That same code uses commands such as `WRITETEXT` and `OUTIMAGE` against the inherited host. ABBSTools therefore treats the presence of this public port as a qualified indication that the ABBS node process/host is present.

M1.3b does **not** infer undocumented ABBS memory layouts or invent query commands for current user/session metadata.

## NodeInfo output

For a valid node number, `NodeInfo` now emits:

```text
NODE=<n>
STATUS=OK
PORT=ABBS node #<n> port
PRESENT=0|1
STATE=OFFLINE|ONLINE
USER=
```

`PRESENT=1` means the qualified ABBS node public port exists at lookup time. `PRESENT=0` means it does not exist at lookup time.

`USER` remains intentionally empty until a documented and runtime-qualified ABBS query path for user/session data is established.

## Safety

Port lookup is performed under `Forbid()`/`Permit()` and the returned `MsgPort *` is never dereferenced after scheduling resumes. Only the boolean presence result is retained.

## Remaining M1.3 work

- identify documented ABBS commands, files or other stable interfaces for richer node/session data;
- expose structured ARexx results from ABBSTools where useful;
- runtime-qualify idle, connected and invalid-node cases against an actual ABBS installation;
- final AmigaOS 2.04 compatibility qualification.
