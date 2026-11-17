---
kind: bug
id: 2026-11-16-releasing-a-dependencyoverride-does-not-restore-the-dependency
aliases: []
title: Releasing a DependencyOverride does not restore the dependency
status: verified
classification: product-defect
scope: in-scope
impact: Tests and previews that rely on scope to end an override leak the mock into later code. Either the comment or the type is wrong; which one is a decision for the maintainer.
criteria: []
requirements: []
cases: []
evidence:
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-override-release-before-fix
  - 2026-11-17-verify-3-1-0-bug-records/2026-11-16-override-release-after-fix
receipts: []
environment: local-macos-arm64
revision: 7e4eb923d14b7a05c8dfdb10099ae13d83352bdc
found_by: claude-code (hc t34) (code review, reproduced in a scratch package against 7e4eb92)
actor:
  - agent: claude-code
    terminal: t34
related: []
created: 2026-11-16T05:16:33Z
updated: 2026-11-17T00:29:55Z
---
# Releasing a DependencyOverride does not restore the dependency

**What happened:** A dependency stays overridden after the DependencyOverride object is released.

Actual: DependencyOverride has no deinit (Application+Dependency.swift:37). Observed: XCTAssertEqual failed: ("mock") is not equal to ("real").

**Steps:** Trigger: Let the object returned by Application.override(_:with:) go out of scope without awaiting cancel().
1. create the override inside a do block and let it go out of scope
2. read Application.dependency(keyPath)

**Expected:** The doc comment on override says deallocation of the returned object cancels the override and restores the original value.

**Why it matters:** Tests and previews that rely on scope to end an override leak the mock into later code. Either the comment or the type is wrong; which one is a decision for the maintainer.

**Fix:** A DependencyOverride restores the previous dependency when it is released, once, and overrides ended out of order restore the right one. Merged to main in PR 159 and released in 3.1.0.

## Log

- 2026-11-16T05:16:33Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted, code changed to match the comment as 0xLeif decided: DependencyOverride restores on release, once. ReviewFixTests.testReleasingOverrideRestoresDependency fails on 7e4eb92 sources and passes now. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
- 2026-11-17T00:21:52Z · fix: A DependencyOverride restores the previous dependency when it is released, once, and overrides ended out of order restore the right one. Merged to main in PR 159 and released in 3.1.0.. On 2026-11-16 the test was run on macOS against the pre-fix sources at 7e4eb92 and against main at 0821de7 (3.1.0 is tagged at 69d692c with the same sources). ReviewFixTests.testReleasingOverrideRestoresDependency fails on 7e4eb92 and passes on 0821de7, where all 13 tests of the class pass. testReleaseAfterCancelDoesNotUndoLaterOverride, testOverridesEndedOutOfOrderRestoreTheRightDependency and testOverrideReleasedOffMainThreadRestoresOnMainActor also fail on 7e4eb92 and pass on 0821de7. · by claude-code (hc t34)
- 2026-11-17T00:29:55Z · status: fix-pending-verification -> verified; evidence: 2026-11-17-verify-3-1-0-bug-records/2026-11-16-override-release-before-fix, 2026-11-17-verify-3-1-0-bug-records/2026-11-16-override-release-after-fix · by claude-code (hc t34)
