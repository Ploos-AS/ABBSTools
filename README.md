# ABBSTools

Native administration, diagnostics and automation tools for **ABBS** on classic Amiga systems.

ABBSTools follows the small-tool philosophy: each utility should do one useful job well, work from the Shell, and expose a consistent ARexx interface where practical.

## Project goals

- Target **AmigaOS 2.04+**
- Baseline CPU: **68000**
- ABBS-specific rather than generic BBS abstractions
- Small native command-line utilities
- ARexx as a first-class automation interface
- No MUI/ReAction requirement for core tools
- Keep individual tools useful on their own
- Prefer stable, scriptable output and return codes

## Tools

### RexxPorts

Implemented in M1.1. `RexxPorts` snapshots and lists Exec public message ports, providing a small diagnostic building block for ABBS/ARexx environments.

### RexxProbe

Implemented in M1.2. `RexxProbe PORT COMMAND` sends one command to an ARexx public port and reports stable result/error fields for Shell automation. Missing ports return `PORT_NOT_FOUND` with RC 10; successful result strings are copied safely from the returned ARexx Argstring before ownership is released.

Planned next:

- **NodeInfo** — inspect ABBS node state and expose it to Shell and ARexx
- Further ABBS-specific node, user, conference, log, door and TCP diagnostics
- Optional observability integration, including a host-side Prometheus bridge where useful

Future candidates include NodeWatch, NodeCheck, UserInfo, ConfInfo, MsgInfo, FileInfo, LastCalls, DoorInfo, DoorCheck, TCPInfo and BBSDoctor.

## Build

The intended toolchain is Bebbo `m68k-amigaos-gcc`.

```sh
make check-config
make
```

The build defaults to `-m68000 -noixemul`.

## ARexx design

ARexx is part of the public interface. Tools that expose an ARexx port should follow [docs/AREXX_API.md](docs/AREXX_API.md).

## Observability

Prometheus support is optional. ABBSTools itself should remain useful without a network stack or resident monitoring daemon; machine-readable output can be consumed by an external exporter/bridge when observability is desired.

## Status

**M1.2 RexxProbe is implemented and native-qualified. FS-UAE + AROS runtime qualification is being extended to execute RexxProbe itself; final AmigaOS 2.04 compatibility qualification remains separate.**

See [ROADMAP.md](ROADMAP.md), [docs/M1_1_IMPLEMENTATION.md](docs/M1_1_IMPLEMENTATION.md) and [docs/M1_2_IMPLEMENTATION.md](docs/M1_2_IMPLEMENTATION.md).

## License

MIT License. Copyright (c) Ploos AS.
