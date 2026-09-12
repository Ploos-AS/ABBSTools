# M5.2 — ABBS-TCPDevice ABI research decision

## Purpose

M5.2 evaluated whether `TCPInfo` can safely grow beyond the M5.1 `OpenDevice()` availability probe into TCP/Telnet/peer-state diagnostics.

## Source reviewed

Repository: `pgousdal/ABBS-TCPDevice`

Pinned source commit:

`039f548c3f3c681dd957987f3e03c47bdec642be`

Relevant files:

- `src/abbstcp_device.h`
- `docs/DEVICE-CONTRACT.md`

## Findings

The public header exposes:

- device name `abbstcp.device`
- version/revision constants
- a private test command `ABBTCP_CMD_INJECT_RING`
- internal state enum values `IDLE`, `RINGING`, `ONLINE`

The private test command is explicitly documented as non-production and not part of the modem contract used by ABBS.

The device contract currently implements only generic Exec commands backed by the AmigaOS NDK:

- `CMD_READ`
- `CMD_WRITE`
- `CMD_CLEAR`
- `CMD_FLUSH`
- `CMD_RESET`

Unsupported requests receive `IOERR_NOCMD`. Serial-specific commands and any deeper ABBS-facing contract are intentionally deferred until they are observed and qualified rather than guessed.

No stable public command or structure was found for read-only retrieval of:

- TCP listener state
- active TCP connection count
- remote peer address
- Telnet negotiation state
- modem/session state via a query API

## Decision

**NO-GO for deeper TCPInfo introspection in M5.2.**

ABBSTools must not consume the private `ABBTCP_CMD_INJECT_RING` test command or infer internal device state from implementation details. Doing so would couple ABBSTools to a non-production ABI and violate the project's source-backed/no-guess policy.

M5 therefore remains intentionally narrow:

- `TCPInfo` may probe whether a device/unit can be opened.
- It may report the returned `OpenDevice()` error code.
- It must not claim socket, Telnet, remote-peer, listener, or connection-state information without a future stable and qualified ABI.

## Reopen criteria

M5.2 may be reopened if `ABBS-TCPDevice` later publishes and qualifies a stable read-only status/query ABI, or if authoritative ABBS/device observations establish a reliable contract that can be tested on the intended AmigaOS baseline.

## Remaining live qualification

M5.1 still requires local qualification against a real `abbstcp.device` configured for ABBS on the intended AmigaOS 2.04+ baseline. That test is separate from this ABI decision.

## Outcome

M5.2 research gate: **PASS — conservative NO-GO decision recorded.**

Next implementation milestone: **M6 optional observability / Metrics**.
