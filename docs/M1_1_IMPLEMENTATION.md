# M1.1 — RexxPorts foundation

M1.1 introduces the first native ABBSTools utility and the minimal shared code needed to build it.

## Delivered

- `RexxPorts` native Shell utility
- Motorola 68000 build baseline
- AmigaOS 2.04+ project baseline
- `-noixemul` build direction
- shared ABBSTools return-code constants
- shared `ABBSTOOLS.` ARexx namespace constant
- minimal DOS output helpers
- static M1.1 repository gate

## RexxPorts

`RexxPorts` snapshots the Exec public message-port list while multitasking is forbidden, then prints the copied names after `Permit()`.

The tool deliberately does not keep the scheduler disabled while producing output.

Current output format:

```text
RexxPorts 0.1
ABBSTools - Ploos AS

Sig Name
4 REXX
5 ABBS
...
```

The list is capped at 128 entries. Truncation returns warning code 5.

## Qualification state

The source and static gate are implemented. Cross-build and AmigaOS runtime qualification are still required before M1.1 is considered runtime-qualified.

The next logical milestone is M1.2, implementing `RexxProbe` and the first reusable ARexx-message helper code.
