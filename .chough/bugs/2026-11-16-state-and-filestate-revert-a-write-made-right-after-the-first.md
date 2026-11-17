---
kind: bug
id: 2026-11-16-state-and-filestate-revert-a-write-made-right-after-the-first
aliases: []
title: State and FileState revert a write made right after the first read
status: verified
classification: product-defect
scope: in-scope
impact: Silent data loss in shipping apps only. The test suite cannot see it, because under XCTest and on Linux the cache is seeded synchronously. Application.state(_:) reads the value for its log message even with logging off, so every imperative read-then-write is exposed.
criteria: []
requirements: []
cases: []
evidence:
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-write-after-read-before-fix
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-write-after-read-after-fix
receipts: []
environment: local-macos-arm64
revision: 7e4eb923d14b7a05c8dfdb10099ae13d83352bdc
found_by: claude-code (hc t34) (code review, reproduced in a scratch package against 7e4eb92)
actor:
  - agent: claude-code
    terminal: t34
related: []
created: 2026-11-16T05:16:14Z
updated: 2026-11-17T00:30:14Z
---
# State and FileState revert a write made right after the first read

**What happened:** Outside XCTest on Apple platforms, a write to a State is undone a moment later, and a FileState keeps returning the old file content although the file holds the new value.

Actual: The getter seeds the cache in a deferred Task when XCTest is not loaded (Application+State.swift:66, Application+FileState.swift:78). The Task runs after the write and overwrites it with the value read earlier. Observed: 'R1 after the main actor ran its queued jobs (expected 5): 0'; 'R3 FileState after the queued jobs ran (expected new value): on disk' with 'R3 value in the file: new value'; two consecutive reads of state(initial: UUID()) differ.

**Steps:** Trigger: Read a State or FileState for the first time and write it in the same main-actor turn, for example Application.state(keyPath) then state.value = 5, or count += 1 through @AppState.
1. Build an executable (not a test) that depends on AppState
2. var s = Application.state(keyPath); s.value = 5
3. await Task.sleep briefly, then read Application.state(keyPath).value

**Expected:** The written value stays. A State whose initial is UUID() or Date() returns the same value on every read.

**Why it matters:** Silent data loss in shipping apps only. The test suite cannot see it, because under XCTest and on Linux the cache is seeded synchronously. Application.state(_:) reads the value for its log message even with logging off, so every imperative read-then-write is exposed.

**Fix:** Both getters fill the cache before returning. Merged to main in PR 159 and released in 3.1.0.

## Log

- 2026-11-16T05:16:14Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted: both getters seed the cache before returning. The scratch executable now prints 5 and 'new value'. ReviewFixTests.testWriteAfterFirstReadSurvivesQueuedMainActorJobs covers the single remaining path. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
- 2026-11-17T00:21:52Z · fix: Both getters fill the cache before returning. Merged to main in PR 159 and released in 3.1.0.. On 2026-11-16 a plain executable (not a test) that reads a State, writes 5, sleeps 0.3 s and reads again was built on macOS against 7e4eb92 and against main at 0821de7. It printed 0 on 7e4eb92 and 5 on 0821de7. ReviewFixTests.testWriteAfterFirstReadSurvivesQueuedMainActorJobs passes on both, because under XCTest the old code filled the cache synchronously. · by claude-code (hc t34)
- 2026-11-17T00:30:14Z · status: fix-pending-verification -> verified; evidence: 2026-11-17-verify-3-1-0-bug-records/2026-11-16-write-after-read-before-fix, 2026-11-17-verify-3-1-0-bug-records/2026-11-16-write-after-read-after-fix · by claude-code (hc t34)
