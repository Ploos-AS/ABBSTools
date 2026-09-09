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

## Initial tool set

The first implementation batch is planned as:

- **RexxPorts** — inspect public/ARexx message ports relevant to ABBS operation
- **RexxProbe** — send commands to an ARexx/message port and report result/return code
- **NodeInfo** — inspect ABBS node state and expose it to Shell and ARexx

Future candidates include NodeWatch, NodeCheck, UserInfo, ConfInfo, MsgInfo, FileInfo, LastCalls, DoorInfo, DoorCheck, TCPInfo and BBSDoctor.

## ARexx design

ARexx is part of the public interface. Tools that expose an ARexx port should follow [docs/AREXX_API.md](docs/AREXX_API.md).

## Build direction

The intended toolchain is Bebbo `m68k-amigaos-gcc` with `-m68000` as the compatibility baseline.

## Status

The project is currently at **M0 — foundation and interface design**.

See [ROADMAP.md](ROADMAP.md).

## License

MIT License. Copyright (c) Ploos AS.
