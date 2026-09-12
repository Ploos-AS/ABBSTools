# M6.1 Metrics snapshot contract

M6.1 adds a small, optional observability surface without turning ABBSTools into a daemon and without introducing a TCP-stack dependency.

## Scope

`Metrics NODE`

The command performs the same conservative, read-only node query used by the qualified NodeInfo/NodeCheck adapter and renders a Prometheus text-format snapshot for one node.

M6.1 does **not**:

- open a listening socket;
- run persistently;
- invent ABBS counters or internal state;
- expose usernames or other high-cardinality/session identity labels;
- infer TCP, Telnet or remote-peer state.

A host-side collector may execute `Metrics` periodically and expose or aggregate its output later.

## Metrics

The stable M6.1 metric namespace is `abbs_`.

For a valid node query, emit exactly these numeric gauges:

```text
abbs_node_present{node="N"} 0|1
abbs_node_log_present{node="N"} 0|1
abbs_node_session_active{node="N"} 0|1
abbs_node_session_known{node="N"} 0|1
```

Semantics:

- `abbs_node_present`: 1 when the qualified ABBS node public port is present.
- `abbs_node_log_present`: 1 when the qualified node logfile is readable/present.
- `abbs_node_session_active`: 1 only for a parsed ACTIVE session; IDLE and UNKNOWN are 0.
- `abbs_node_session_known`: 1 for ACTIVE or IDLE; 0 for UNKNOWN.

Only the bounded numeric `node` label is used. No username, path, reason string, caller name, conference name, door name, IP address or remote peer is a metric label in M6.1.

## Return codes

- `0`: node query succeeded and a complete metric snapshot was emitted.
- `5`: the ABBS interface is explicitly unavailable/unqualified.
- `10`: invalid CLI or node-query failure.
- `20`: reserved for fatal local setup failures under the project-wide convention.

When no complete snapshot can be produced, the command emits diagnostic text but must not emit fabricated metric values.

## Qualification boundary

Automated qualification may use the existing deterministic ABBS node trace adapter under FS-UAE + AROS. Final live compatibility qualification remains separate and must use the intended AmigaOS 2.04+ / ABBS baseline.
