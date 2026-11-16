---
kind: bug
id: 2026-11-16-docs-the-restricted-state-example-never-keeps-its-value-and
aliases: []
title: "Docs: the restricted state example never keeps its value and grows the cache"
status: fix-pending-verification
classification: product-defect
scope: in-scope
impact: Readers who copy the example get state that does not work and unbounded memory growth. The same text is in every documentation language.
criteria: []
requirements: []
cases: []
evidence: []
receipts: []
environment: local-macos-arm64
revision: 7e4eb923d14b7a05c8dfdb10099ae13d83352bdc
found_by: claude-code (hc t34) (code review, reproduced in a scratch package against 7e4eb92)
actor:
  - agent: claude-code
    terminal: t34
related: []
created: 2026-11-16T05:16:28Z
updated: 2026-11-16T05:25:09Z
---
# Docs: the restricted state example never keeps its value and grows the cache

**What happened:** The example in advanced-usage.md section 3.2 yields a state that always reads nil, and each read adds a cache entry.

Actual: The computed property makes a new UUID, so a new scope key, on every access. Observed: XCTAssertEqual failed: ("nil") is not equal to ("Optional(42)"); 100 reads added 102 cache entries. The dependency variant rebuilds SomeType on every access the same way.

**Steps:** Trigger: Use state(initial: nil, id: UUID().uuidString) inside a computed property, as the page shows.
1. var restrictedState: State<Int?> { state(initial: nil, id: UUID().uuidString) }
2. write 42, then read

**Expected:** A state that keeps what is written to it.

**Why it matters:** Readers who copy the example get state that does not work and unbounded memory growth. The same text is in every documentation language.

**Fix:** Not fixed yet.

## Log

- 2026-11-16T05:16:28Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted, in all eight languages: the ids are file-private constants. The English block compiles in a Swift 6 scratch target. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
