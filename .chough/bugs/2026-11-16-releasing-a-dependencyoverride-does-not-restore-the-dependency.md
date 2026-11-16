---
kind: bug
id: 2026-11-16-releasing-a-dependencyoverride-does-not-restore-the-dependency
aliases: []
title: Releasing a DependencyOverride does not restore the dependency
status: fix-pending-verification
classification: product-defect
scope: in-scope
impact: Tests and previews that rely on scope to end an override leak the mock into later code. Either the comment or the type is wrong; which one is a decision for the maintainer.
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
created: 2026-11-16T05:16:33Z
updated: 2026-11-16T05:25:09Z
---
# Releasing a DependencyOverride does not restore the dependency

**What happened:** A dependency stays overridden after the DependencyOverride object is released.

Actual: DependencyOverride has no deinit (Application+Dependency.swift:37). Observed: XCTAssertEqual failed: ("mock") is not equal to ("real").

**Steps:** Trigger: Let the object returned by Application.override(_:with:) go out of scope without awaiting cancel().
1. create the override inside a do block and let it go out of scope
2. read Application.dependency(keyPath)

**Expected:** The doc comment on override says deallocation of the returned object cancels the override and restores the original value.

**Why it matters:** Tests and previews that rely on scope to end an override leak the mock into later code. Either the comment or the type is wrong; which one is a decision for the maintainer.

**Fix:** Not fixed yet.

## Log

- 2026-11-16T05:16:33Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted, code changed to match the comment as 0xLeif decided: DependencyOverride restores on release, once. ReviewFixTests.testReleasingOverrideRestoresDependency fails on 7e4eb92 sources and passes now. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
