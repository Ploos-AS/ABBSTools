# M1.3c — Node session metadata from ABBS logs

`NodeInfo` derives session metadata from the normal per-node ABBS log rather than from undocumented in-memory structures.

## Source

For node `N`, the read-only source is:

`ABBS:nodeNlogfile`

This naming and the observed record forms are already used by the qualified ABBS LastCallers tooling.

Recognized events are deliberately narrow:

- ` Login: <user> (<mode>)`
- ` Logout: <user>`

Records are processed in file order. The newest recognized event determines session state:

- a valid Login makes the session `ACTIVE` and records the username;
- a Logout makes the session `IDLE` and clears the username;
- a readable log with no recognized session event remains `UNKNOWN`;
- a missing/unopenable log reports `LOG_PRESENT=0` and `SESSION=UNKNOWN`.

The login mode is intentionally not exposed yet. It can be added later when there is a stable use case and qualification coverage.

## NodeInfo fields

M1.3c adds:

- `LOG=ABBS:nodeNlogfile`
- `LOG_PRESENT=0|1`
- `SESSION=ACTIVE|IDLE|UNKNOWN`
- `USER=<name>` when the latest recognized event is a Login

These fields complement, rather than replace, the Exec public-port signal from M1.3b:

- `PRESENT` / `STATE` answer whether the ABBS node public port exists now;
- `SESSION` / `USER` reflect the latest recognized session event in the node log.

A disagreement between those two sources is useful diagnostic information and must not be hidden by forcing one to match the other.

## Safety and compatibility

The log is opened with `MODE_OLDFILE` and never modified. The parser uses bounded fixed-size buffers and does not depend on ABBS private structures, offsets, or pointers.

The implementation remains targeted at the ABBSTools baseline of AmigaOS 2.04+ / Motorola 68000. Native Bebbo qualification and live ABBS runtime qualification are separate gates.
