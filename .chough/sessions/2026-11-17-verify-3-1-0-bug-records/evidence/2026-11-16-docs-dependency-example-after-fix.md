---
kind: evidence
id: 2026-11-16-docs-dependency-example-after-fix
aliases: []
claim: The dependency example from 0821de7 compiles in Swift 6 mode.
result: passed
evidence_kind: structural
method: the English example blocks copied into a Swift 6 target that depends on AppState at 0821de7; blocks from 0821de7
revision: 0821de760b8fc8ae782b14b9659c0211739d8442
content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
environment: local-macos-arm64
criteria: [BUGS-1]
requirements: []
contracts: []
limitations: [Only the English page was compiled.]
observed: 2026-11-17T00:30:15Z
actor:
  - agent: claude-code
    terminal: t34
---
**The dependency example from 0821de7 compiles in Swift 6 mode.**

Recorded as passed in local-macos-arm64 at revision 0821de760b8f, observed 2026-11-17T00:30:15Z.
