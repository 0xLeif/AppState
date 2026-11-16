---
kind: bug
id: 2026-11-16-state-initial-evaluates-the-initial-value-on-every-access
aliases: []
title: state(initial:) evaluates the initial value on every access
status: fix-pending-verification
classification: product-defect
scope: in-scope
impact: An expensive or side-effecting initial runs on every read and every SwiftUI body pass. The result is discarded once the cache holds a value.
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
# state(initial:) evaluates the initial value on every access

**What happened:** The initial expression of a State runs each time the key path is read.

Actual: State.init calls initial() unconditionally (Application+State.swift:111). Observed after 5 reads: XCTAssertEqual failed: ("5") is not equal to ("1").

**Steps:** Trigger: Any read of a State defined with state(initial: expression).
1. var counted: State<Int> { state(initial: countedInitial(), id: "counted") }
2. read Application.state(keyPath).value five times
3. check how often countedInitial ran

**Expected:** The doc comment on state(initial:feature:id:) says the closure is evaluated only once, when the state is not found in the cache.

**Why it matters:** An expensive or side-effecting initial runs on every read and every SwiftUI body pass. The result is discarded once the cache holds a value.

**Fix:** Not fixed yet.

## Log

- 2026-11-16T05:16:28Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted, code changed to match the comment as 0xLeif decided: state(initial:) returns the cached State. ReviewFixTests.testStateInitialIsEvaluatedOnce fails on 7e4eb92 sources and passes now. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
