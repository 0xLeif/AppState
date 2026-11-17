---
kind: bug
id: 2026-11-16-storedstate-crashes-on-a-value-that-jsonencoder-rejects
aliases: []
title: StoredState crashes on a value that JSONEncoder rejects
status: verified
classification: product-defect
scope: in-scope
impact: A crash that Swift code cannot catch. The in-memory UserDefaults fakes in the test suite accept any value, so the tests do not show it.
criteria: []
requirements: []
cases: []
evidence:
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-storedstate-reject-before-fix
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-storedstate-reject-after-fix
receipts: []
environment: local-macos-arm64
revision: 7e4eb923d14b7a05c8dfdb10099ae13d83352bdc
found_by: claude-code (hc t34) (code review, reproduced in a scratch package against 7e4eb92)
actor:
  - agent: claude-code
    terminal: t34
related: []
created: 2026-11-16T05:16:14Z
updated: 2026-11-17T00:29:57Z
---
# StoredState crashes on a value that JSONEncoder rejects

**What happened:** The app terminates with NSInvalidArgumentException.

Actual: When encoding fails the setter falls back to userDefaults.set(newValue, forKey:) with the raw Swift value (Application+StoredState.swift:82). Observed: Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Attempt to insert non-property list object repro.Reading(celsius: nan) for key App/reading'.

**Steps:** Trigger: Write a Codable struct that holds Double.nan or Double.infinity to a StoredState backed by the real UserDefaults.
1. struct Reading: Codable, Sendable { var celsius: Double }
2. var s = Application.storedState(keyPath); s.value = Reading(celsius: .nan)

**Expected:** The write is rejected and logged, as SyncState does by encoding before it commits.

**Why it matters:** A crash that Swift code cannot catch. The in-memory UserDefaults fakes in the test suite accept any value, so the tests do not show it.

**Fix:** The StoredState setter encodes first and falls back only for a property list; a value that is neither is rejected and reported. Merged to main in PR 159 and released in 3.1.0.

## Log

- 2026-11-16T05:16:14Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted: the setter encodes first and only falls back for a property list. ReviewFixTests.testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList fails on 7e4eb92 sources and passes now; the scratch executable no longer crashes. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
- 2026-11-17T00:21:52Z · fix: The StoredState setter encodes first and falls back only for a property list; a value that is neither is rejected and reported. Merged to main in PR 159 and released in 3.1.0.. On 2026-11-16 the test was run on macOS against the pre-fix sources at 7e4eb92 and against main at 0821de7 (3.1.0 is tagged at 69d692c with the same sources). ReviewFixTests.testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList fails on 7e4eb92 and passes on 0821de7, where all 13 tests of the class pass. · by claude-code (hc t34)
- 2026-11-17T00:29:57Z · status: fix-pending-verification -> verified; evidence: 2026-11-17-verify-3-1-0-bug-records/2026-11-16-storedstate-reject-before-fix, 2026-11-17-verify-3-1-0-bug-records/2026-11-16-storedstate-reject-after-fix · by claude-code (hc t34)
