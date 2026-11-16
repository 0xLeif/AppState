---
kind: bug
id: 2026-11-16-promote-to-drops-the-icloud-observer-when-icloudstore-was
aliases: []
title: promote(to:) drops the iCloud observer when icloudStore was already loaded
status: fix-pending-verification
classification: product-defect
scope: in-scope
impact: External iCloud changes stop reaching the app, depending only on call order at launch.
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
created: 2026-11-16T05:16:14Z
updated: 2026-11-16T05:25:09Z
---
# promote(to:) drops the iCloud observer when icloudStore was already loaded

**What happened:** A custom Application's didChangeExternally override is never called.

Actual: promote removes the old instance as observer and copies the cached icloudStore dependency, so the closure that registers the observer never runs for the new instance (Application+public.swift:70, Application+SyncState.swift:25). Observed: XCTAssertEqual failed: ("0") is not equal to ("1"); the control that promotes first passed.

**Steps:** Trigger: Any SyncState read or Application.load(dependency: icloudStore) happens before Application.promote(to:).
1. _ = Application.dependency(icloudStore keyPath)
2. Application.promote(to: CustomApplication.self)
3. post didChangeExternallyNotification for NSUbiquitousKeyValueStore.default

**Expected:** The promoted application receives NSUbiquitousKeyValueStore.didChangeExternallyNotification.

**Why it matters:** External iCloud changes stop reaching the app, depending only on call order at launch.

**Fix:** Not fixed yet.

## Log

- 2026-11-16T05:16:14Z · Reported (code review, reproduced in a scratch package against 7e4eb92) · by claude-code (hc t34)
- 2026-11-16T05:25:06Z · Fixed in the working tree, uncommitted: promote hands the registration to the new instance. ReviewFixTests.testPromoteKeepsExternalChangeObserver fails on 7e4eb92 sources and passes now. · by claude-code (hc t34)
- 2026-11-16T05:25:09Z · status: open -> fix-pending-verification · by claude-code (hc t34)
