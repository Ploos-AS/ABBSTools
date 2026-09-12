# M5.1 TCPInfo contract

## Purpose

`TCPInfo` is a conservative diagnostic for the ABBS TCP device path. The first milestone answers only whether a configured Amiga device can be opened on a selected unit. It does not infer listener state, remote connections, Telnet state, socket state, or undocumented internal counters.

## Source-backed basis

The current `pgousdal/ABBS-TCPDevice` reference documents `abbstcp.device` as a classic AmigaOS byte-stream device with a serial-shaped `IOExtSer` interface. Its observational ABBS setup uses:

```text
Device: abbstcp.device
Unit:   0
```

The device contract deliberately avoids guessing serial-specific command values and treats unsupported requests as unsupported rather than inventing semantics. ABBSTools follows the same boundary for M5.1.

## CLI

```text
TCPInfo [DEVICE [UNIT]]
```

Defaults:

```text
DEVICE=abbstcp.device
UNIT=0
```

`DEVICE` may be overridden so the same diagnostic can be used with another explicitly configured ABBS byte-stream device. `UNIT` is decimal and must fit an unsigned 32-bit value.

## Operation

M5.1 performs only a bounded device-open probe:

1. Create a message port.
2. Create an `IOExtSer` request.
3. Call `OpenDevice(DEVICE, UNIT, ...)`.
4. If open succeeds, immediately `CloseDevice()`.
5. Delete the I/O request and message port.

No `DoIO()`/`SendIO()` command is sent in M5.1. The tool therefore does not mutate device configuration or network state.

## Stable output

Successful open:

```text
STATUS=OK
DEVICE=abbstcp.device
UNIT=0
AVAILABLE=YES
OPEN_ERROR=0
```

Open failure:

```text
STATUS=WARN
DEVICE=abbstcp.device
UNIT=0
AVAILABLE=NO
OPEN_ERROR=<io error>
REASON=DEVICE_OPEN_FAILED
```

Fatal local setup failure:

```text
STATUS=FATAL
DEVICE=abbstcp.device
UNIT=0
AVAILABLE=UNKNOWN
REASON=LOCAL_SETUP_FAILED
```

## Return codes

- RC 0: device/unit opened and closed successfully.
- RC 5: `OpenDevice()` failed; device/unit unavailable or rejected the open.
- RC 10: invalid CLI input.
- RC 20: local message-port/I/O-request allocation failure.

## Explicit non-goals for M5.1

M5.1 does not claim or infer:

- that ABBS is currently using the device
- that a TCP listener is active
- that port 23 or any other TCP port is listening
- how many clients are connected
- Telnet negotiation state
- socket or bsdsocket.library internals
- private `abbstcp.device` commands or counters
- serial command semantics not established by a reliable contract

Those can be added in later M5 milestones only when backed by an explicit, testable interface.

## Qualification plan

- static repository checks for the no-guess boundary and cleanup paths
- native 68000 build with Bebbo GCC
- deterministic FS-UAE + AROS runtime using a qualification fixture/stub or known openable device where semantics are controlled
- final live qualification with real `abbstcp.device` and ABBS on the intended AmigaOS baseline
