---
kind: evidence
id: 2026-11-16-path-encoding-before-fix
aliases: []
claim: "testDefaultFileStatePathIsNotPercentEncoded fails on 7e4eb92: the old expression appending(path:).path() returns a percent-encoded path for a documents directory with a space and an accent."
result: failed
evidence_kind: product-test
method: swift test, ReviewFixTests class only, on the sources of 7e4eb92
revision: 0821de760b8fc8ae782b14b9659c0211739d8442
content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
environment: local-macos-arm64
criteria: [BUGS-1]
requirements: []
contracts: []
limitations:
  - The helper the test calls does not exist at 7e4eb92, so the assertion was run on the old expression instead.
observed: 2026-11-17T00:29:32Z
actor:
  - agent: claude-code
    terminal: t34
---
**testDefaultFileStatePathIsNotPercentEncoded fails on 7e4eb92: the old expression appending(path:).path() returns a percent-encoded path for a documents directory with a space and an accent.**

Recorded as failed in local-macos-arm64 at revision 0821de760b8f, observed 2026-11-17T00:29:32Z.
