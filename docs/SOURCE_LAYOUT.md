# Source layout

Planned layout:

```text
ABBSTools/
├── include/
│   └── abbstools/
├── src/
│   ├── common/
│   └── tools/
│       ├── rexxports/
│       ├── rexxprobe/
│       └── nodeinfo/
├── tests/
├── docs/
├── examples/
├── Makefile
├── README.md
└── ROADMAP.md
```

## Shared code policy

Shared code should remain small and boring. ABBSTools should not become a framework.

Good shared candidates include version metadata, return-code helpers, Shell argument helpers, ARexx host helpers, Exec/DOS utility helpers and formatting routines.

ABBS-specific knowledge belongs in ABBSTools. Generic abstractions for unrelated BBS packages are intentionally out of scope.
