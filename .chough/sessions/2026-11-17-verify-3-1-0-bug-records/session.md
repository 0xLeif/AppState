---
kind: session
id: 2026-11-17-verify-3-1-0-bug-records
aliases: [verify-3-1-0-bug-records]
objective: Mark the ten 3.1.0 review bugs verified, each with a failing run on the pre-fix code or docs and a passing run on main
intent_scope: "Records only: .chough/bugs and evidence. No source, test or doc change."
modules: []
stage: done
stage_status: active
iteration: 1
callers: []
native_change: ""
pr: ""
criteria: [BUGS-1]
requirements: []
cases: []
design: []
files: []
observations:
  - 2026-11-16-path-encoding-before-fix
  - 2026-11-16-path-encoding-after-fix
  - 2026-11-16-base64-filestate-before-fix
  - 2026-11-16-base64-filestate-after-fix
  - 2026-11-16-promote-observer-before-fix
  - 2026-11-16-promote-observer-after-fix
  - 2026-11-16-custom-objectwillchange-before-fix
  - 2026-11-16-custom-objectwillchange-after-fix
  - 2026-11-16-override-release-before-fix
  - 2026-11-16-override-release-after-fix
  - 2026-11-16-state-initial-before-fix
  - 2026-11-16-state-initial-after-fix
  - 2026-11-16-storedstate-reject-before-fix
  - 2026-11-16-storedstate-reject-after-fix
  - 2026-11-16-write-after-read-after-fix
  - 2026-11-16-write-after-read-before-fix
  - 2026-11-16-docs-dependency-example-before-fix
  - 2026-11-16-docs-dependency-example-after-fix
  - 2026-11-16-docs-restricted-example-before-fix
  - 2026-11-16-docs-restricted-example-after-fix
bugs:
  - 2026-11-16-defaultfilestatepath-is-percent-encoded-and-points-at-the
  - 2026-11-16-filestate-with-isbase64encoded-false-loses-values-that-look
  - 2026-11-16-promote-to-drops-the-icloud-observer-when-icloudstore-was
  - 2026-11-16-property-wrapper-setter-drops-the-write-when-the-host-has-a
  - 2026-11-16-releasing-a-dependencyoverride-does-not-restore-the-dependency
  - 2026-11-16-state-initial-evaluates-the-initial-value-on-every-access
  - 2026-11-16-storedstate-crashes-on-a-value-that-jsonencoder-rejects
  - 2026-11-16-state-and-filestate-revert-a-write-made-right-after-the-first
  - 2026-11-16-docs-the-dependency-example-in-usage-state-dependency-md-does
  - 2026-11-16-docs-the-restricted-state-example-never-keeps-its-value-and
blockers: []
waiting_on_human: []
run_consents: []
next: None; open a records-only PR and wait for 0xLeif to merge it
---
# Mark the ten 3.1.0 review bugs verified, each with a failing run on the pre-fix code or docs and a passing run on main

## Goal

Mark the ten 3.1.0 review bugs verified, each with a failing run on the pre-fix code or docs and a passing run on main

## Where it stands

- All ten review bugs are verified: each has a failed observation on the pre-fix code or docs at 7e4eb92 and a later passed observation on main at 0821de7, linked to the bug record.

## Decisions and why

## What was verified

- [testDefaultFileStatePathIsNotPercentEncoded fails on 7e4eb92: the old expression appending(path:).path() returns a percent-encoded path for a documents directory with a space and an accent.](evidence/2026-11-16-path-encoding-before-fix.md)
- [testDefaultFileStatePathIsNotPercentEncoded passes on 0821de7; all 13 tests of ReviewFixTests pass.](evidence/2026-11-16-path-encoding-after-fix.md)
- [testUnencodedFileStateReadsBackBase64LookingValues fails on 7e4eb92. ](evidence/2026-11-16-base64-filestate-before-fix.md)
- [testUnencodedFileStateReadsBackBase64LookingValues passes on 0821de7; all 13 tests of ReviewFixTests pass.](evidence/2026-11-16-base64-filestate-after-fix.md)
- [testPromoteKeepsExternalChangeObserver fails on 7e4eb92. ](evidence/2026-11-16-promote-observer-before-fix.md)
- [testPromoteKeepsExternalChangeObserver passes on 0821de7; all 13 tests of ReviewFixTests pass.](evidence/2026-11-16-promote-observer-after-fix.md)
- [testWriteThroughHostWithCustomObjectWillChangeIsStored fails on 7e4eb92. ](evidence/2026-11-16-custom-objectwillchange-before-fix.md)
- [testWriteThroughHostWithCustomObjectWillChangeIsStored passes on 0821de7; all 13 tests of ReviewFixTests pass.](evidence/2026-11-16-custom-objectwillchange-after-fix.md)
- [testReleasingOverrideRestoresDependency fails on 7e4eb92. Three more override tests fail there too: release after cancel, overrides ended out of order, and release off the main thread.](evidence/2026-11-16-override-release-before-fix.md)
- [testReleasingOverrideRestoresDependency passes on 0821de7; all 13 tests of ReviewFixTests pass.](evidence/2026-11-16-override-release-after-fix.md)
- [testStateInitialIsEvaluatedOnce fails on 7e4eb92. ](evidence/2026-11-16-state-initial-before-fix.md)
- [testStateInitialIsEvaluatedOnce passes on 0821de7; all 13 tests of ReviewFixTests pass.](evidence/2026-11-16-state-initial-after-fix.md)
- [testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList fails on 7e4eb92. ](evidence/2026-11-16-storedstate-reject-before-fix.md)
- [testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList passes on 0821de7; all 13 tests of ReviewFixTests pass.](evidence/2026-11-16-storedstate-reject-after-fix.md)
- [After reading a State, writing 5 and sleeping 0.3 s, the next read prints 5 on 0821de7.](evidence/2026-11-16-write-after-read-after-fix.md)
- 2026-11-16-write-after-read-after-fix
- [After reading a State, writing 5 and sleeping 0.3 s, the next read prints 0 on 7e4eb92.](evidence/2026-11-16-write-after-read-before-fix.md)
- [The dependency example from 7e4eb92 does not compile: type 'any NetworkServiceType' does not conform to the 'Sendable' protocol.](evidence/2026-11-16-docs-dependency-example-before-fix.md)
- [The dependency example from 0821de7 compiles in Swift 6 mode.](evidence/2026-11-16-docs-dependency-example-after-fix.md)
- [With the section 3.2 example from 7e4eb92, a read after writing 42 returns nil.](evidence/2026-11-16-docs-restricted-example-before-fix.md)
- [With the section 3.2 example from 0821de7, a read after writing 42 returns Optional(42).](evidence/2026-11-16-docs-restricted-example-after-fix.md)

## Open threads

## Timeline

- 2026-11-17T00:21:27Z · start · intent → intent · Mark the ten 3.1.0 review bugs verified, each with a failing run on the pre-fix code or docs and a passing run on main ^t-177d6c
  - revision: 0821de760b8fc8ae782b14b9659c0211739d8442
  - by: claude-code (hc t34)
- 2026-11-17T00:30:26Z · advance · intent → design ·  ^t-c1241b
  - revision: 0821de760b8fc8ae782b14b9659c0211739d8442
  - by: claude-code (hc t34)
- 2026-11-17T00:30:26Z · advance · design → plan ·  ^t-fa9c22
  - revision: 0821de760b8fc8ae782b14b9659c0211739d8442
  - by: claude-code (hc t34)
- 2026-11-17T00:30:26Z · advance · plan → build · ungated:sdd-disabled ^t-c60776
  - gate: ungated:sdd-disabled
  - revision: 0821de760b8fc8ae782b14b9659c0211739d8442
  - by: claude-code (hc t34)
- 2026-11-17T00:30:26Z · advance · build → test · ungated:sdd-disabled ^t-396945
  - gate: ungated:sdd-disabled
  - revision: 0821de760b8fc8ae782b14b9659c0211739d8442
  - by: claude-code (hc t34)
- 2026-11-17T00:30:26Z · advance · test → accept · ungated:sdd-disabled ^t-d6ff3c
  - gate: ungated:sdd-disabled
  - revision: 0821de760b8fc8ae782b14b9659c0211739d8442
  - by: claude-code (hc t34)
- 2026-11-17T00:30:26Z · advance · accept → done · ungated:sdd-disabled ^t-00207c
  - gate: ungated:sdd-disabled
  - revision: 0821de760b8fc8ae782b14b9659c0211739d8442
  - by: claude-code (hc t34)
