# M1.3a — NodeInfo contract

M1.3a establishes the public `NodeInfo` shape without guessing an undocumented or unqualified ABBS node ABI.

## Current behaviour

`NodeInfo NODE` accepts a positive numeric node identifier and emits stable key/value output.

Until the live ABBS node interface is qualified, the adapter deliberately returns:

```text
NODE=<n>
STATUS=UNAVAILABLE
REASON=ABBS_INTERFACE_NOT_QUALIFIED
```

with ABBSTools warning RC 5.

This is intentional. It prevents the first implementation from baking guessed ABBS port names, offsets, files or in-memory structures into the public tool contract.

## Adapter boundary

The shared interface is declared in `include/abbstools/abbs.h` and implemented through `abt_abbs_node_query()`.

The initial `AbtNodeInfo` model contains:

- numeric node identifier;
- availability flag;
- bounded state string;
- bounded user string.

The model can grow only when a field has a qualified ABBS source and stable semantics.

## Qualification path

M1.3b should establish the actual live ABBS node source, then replace the conservative adapter stub while preserving the CLI/output contract where possible.

Required evidence before claiming live NodeInfo support:

1. identify the supported ABBS node interface and version assumptions;
2. document how node state and user identity are obtained;
3. exercise at least idle and connected node states against ABBS;
4. verify invalid/nonexistent node behaviour;
5. qualify on the intended AmigaOS 2.04+ baseline.
