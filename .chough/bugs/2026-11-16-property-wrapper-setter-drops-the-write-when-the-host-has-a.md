---
kind: bug
id: 2026-11-16-property-wrapper-setter-drops-the-write-when-the-host-has-a
aliases: []
title: Property wrapper setter drops the write when the host has a custom objectWillChange
status: verified
classification: product-defect
scope: in-scope
impact: Writes are lost without a log line for any view model that uses a custom publisher.
criteria: []
requirements: []
cases: []
evidence:
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-custom-objectwillchange-before-fix
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-custom-objectwillchange-after-fix
receipts: []
environment: local-macos-arm64
revision: 7e4eb923d14b7a05c8dfdb10099ae13d83352bdc
found_by: claude-code (hc t34) (code review, reproduced in a scratch package against 7e4eb92)
actor:
  - agent: claude-code
    terminal: t34
related: []
created: 2026-11-16T05:16:14Z
updated: 2026-11-17T00:29:53Z
---
# Property wrapper setter drops the write when the host has a custom objectWillChange

**What happened:** Setting an @AppState property on an ObservableObject does nothing.

Actual: The enclosing-instance subscript returns before writing when objectWillChange is not an ObservableObjectPublisher (AppState.swift:91). Same guard in StoredState, FileState, SecureState, SyncState, Slice and OptionalSlice. Observed: XCTAssertEqual failed: ("3") is not equal to ("7"); the control host with the default publisher passed.

**Steps:** Trigger: The host class declares its own objectWillChange, for example let objectWillChange = PassthroughSubject<Void, Never>().
1. final class Model: ObservableObject { let objectWillChange = PassthroughSubject<Void, Never>(); @AppState(keyPath) var count: Int }
2. model.count = 7
3. read model.count

**Expected:** The value is written; the publisher is notified when it is an ObservableObjectPublisher.

**Why it matters:** Writes are lost without a log line for any view model that uses a custom publisher.

**Fix:** The seven enclosing-instance setters always store the write. Merged to main in PR 159 and released in 3.1.0.

## Log

- 2026-11-16T05:16:14Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted: the seven setters always write. ReviewFixTests.testWriteThroughHostWithCustomObjectWillChangeIsStored fails on 7e4eb92 sources and passes now. The property-wrapper spec's invariant 7 said the write is skipped; it is reworded. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
- 2026-11-17T00:21:52Z · fix: The seven enclosing-instance setters always store the write. Merged to main in PR 159 and released in 3.1.0.. On 2026-11-16 the test was run on macOS against the pre-fix sources at 7e4eb92 and against main at 0821de7 (3.1.0 is tagged at 69d692c with the same sources). ReviewFixTests.testWriteThroughHostWithCustomObjectWillChangeIsStored fails on 7e4eb92 and passes on 0821de7, where all 13 tests of the class pass. · by claude-code (hc t34)
- 2026-11-17T00:29:53Z · status: fix-pending-verification -> verified; evidence: 2026-11-17-verify-3-1-0-bug-records/2026-11-16-custom-objectwillchange-before-fix, 2026-11-17-verify-3-1-0-bug-records/2026-11-16-custom-objectwillchange-after-fix · by claude-code (hc t34)
