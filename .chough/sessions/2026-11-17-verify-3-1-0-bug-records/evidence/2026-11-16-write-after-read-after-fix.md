---
kind: evidence
id: 2026-11-16-write-after-read-after-fix
aliases: []
claim: After reading a State, writing 5 and sleeping 0.3 s, the next read prints 5 on 0821de7.
result: passed
evidence_kind: product-test
method: a plain Swift 6 executable, not a test, that depends on AppState on main at 0821de7
revision: 0821de760b8fc8ae782b14b9659c0211739d8442
content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
environment: local-macos-arm64
criteria: [BUGS-1]
requirements: []
contracts: []
limitations: [One State of Int was exercised; FileState was not run in the executable.]
observed: 2026-11-17T00:30:14Z
actor:
  - agent: claude-code
    terminal: t34
---
**After reading a State, writing 5 and sleeping 0.3 s, the next read prints 5 on 0821de7.**

Recorded as passed in local-macos-arm64 at revision 0821de760b8f, observed 2026-11-17T00:30:14Z.
