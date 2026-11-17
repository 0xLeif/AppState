---
kind: session
id: 2026-11-17-verify-3-1-0-bug-records
aliases: [verify-3-1-0-bug-records]
objective: Mark the ten 3.1.0 review bugs verified, each with a failing run on the pre-fix code or docs and a passing run on main
intent_scope: "Records only: .chough/bugs and evidence. No source, test or doc change."
stage: done
stage_status: archived
iteration: 1
criteria: [BUGS-1]
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
closed: 2026-11-17
outcome: done
---
# Mark the ten 3.1.0 review bugs verified, each with a failing run on the pre-fix code or docs and a passing run on main

## Goal

Mark the ten 3.1.0 review bugs verified, each with a failing run on the pre-fix code or docs and a passing run on main

## Where it stands

- All ten review bugs are verified: each has a failed observation on the pre-fix code or docs at 7e4eb92 and a later passed observation on main at 0821de7, linked to the bug record.

## Decisions and why

## What was verified

- testDefaultFileStatePathIsNotPercentEncoded fails on 7e4eb92: the old expression appending(path:).path() returns a percent-encoded path for a documents directory with a space and an accent. ^2026-11-16-path-encoding-before-fix
- testDefaultFileStatePathIsNotPercentEncoded passes on 0821de7; all 13 tests of ReviewFixTests pass. ^2026-11-16-path-encoding-after-fix
- testUnencodedFileStateReadsBackBase64LookingValues fails on 7e4eb92.  ^2026-11-16-base64-filestate-before-fix
- testUnencodedFileStateReadsBackBase64LookingValues passes on 0821de7; all 13 tests of ReviewFixTests pass. ^2026-11-16-base64-filestate-after-fix
- testPromoteKeepsExternalChangeObserver fails on 7e4eb92.  ^2026-11-16-promote-observer-before-fix
- testPromoteKeepsExternalChangeObserver passes on 0821de7; all 13 tests of ReviewFixTests pass. ^2026-11-16-promote-observer-after-fix
- testWriteThroughHostWithCustomObjectWillChangeIsStored fails on 7e4eb92.  ^2026-11-16-custom-objectwillchange-before-fix
- testWriteThroughHostWithCustomObjectWillChangeIsStored passes on 0821de7; all 13 tests of ReviewFixTests pass. ^2026-11-16-custom-objectwillchange-after-fix
- testReleasingOverrideRestoresDependency fails on 7e4eb92. Three more override tests fail there too: release after cancel, overrides ended out of order, and release off the main thread. ^2026-11-16-override-release-before-fix
- testReleasingOverrideRestoresDependency passes on 0821de7; all 13 tests of ReviewFixTests pass. ^2026-11-16-override-release-after-fix
- testStateInitialIsEvaluatedOnce fails on 7e4eb92.  ^2026-11-16-state-initial-before-fix
- testStateInitialIsEvaluatedOnce passes on 0821de7; all 13 tests of ReviewFixTests pass. ^2026-11-16-state-initial-after-fix
- testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList fails on 7e4eb92.  ^2026-11-16-storedstate-reject-before-fix
- testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList passes on 0821de7; all 13 tests of ReviewFixTests pass. ^2026-11-16-storedstate-reject-after-fix
- After reading a State, writing 5 and sleeping 0.3 s, the next read prints 5 on 0821de7. ^2026-11-16-write-after-read-after-fix
- 2026-11-16-write-after-read-after-fix
- After reading a State, writing 5 and sleeping 0.3 s, the next read prints 0 on 7e4eb92. ^2026-11-16-write-after-read-before-fix
- The dependency example from 7e4eb92 does not compile: type 'any NetworkServiceType' does not conform to the 'Sendable' protocol. ^2026-11-16-docs-dependency-example-before-fix
- The dependency example from 0821de7 compiles in Swift 6 mode. ^2026-11-16-docs-dependency-example-after-fix
- With the section 3.2 example from 7e4eb92, a read after writing 42 returns nil. ^2026-11-16-docs-restricted-example-before-fix
- With the section 3.2 example from 0821de7, a read after writing 42 returns Optional(42). ^2026-11-16-docs-restricted-example-after-fix

## Bugs

- [defaultFileStatePath is percent-encoded and points at the wrong directory](../../bugs/2026-11-16-defaultfilestatepath-is-percent-encoded-and-points-at-the.md): verified
- [FileState with isBase64Encoded false loses values that look like Base64](../../bugs/2026-11-16-filestate-with-isbase64encoded-false-loses-values-that-look.md): verified
- [promote(to:) drops the iCloud observer when icloudStore was already loaded](../../bugs/2026-11-16-promote-to-drops-the-icloud-observer-when-icloudstore-was.md): verified
- [Property wrapper setter drops the write when the host has a custom objectWillChange](../../bugs/2026-11-16-property-wrapper-setter-drops-the-write-when-the-host-has-a.md): verified
- [Releasing a DependencyOverride does not restore the dependency](../../bugs/2026-11-16-releasing-a-dependencyoverride-does-not-restore-the-dependency.md): verified
- [state(initial:) evaluates the initial value on every access](../../bugs/2026-11-16-state-initial-evaluates-the-initial-value-on-every-access.md): verified
- [StoredState crashes on a value that JSONEncoder rejects](../../bugs/2026-11-16-storedstate-crashes-on-a-value-that-jsonencoder-rejects.md): verified
- [State and FileState revert a write made right after the first read](../../bugs/2026-11-16-state-and-filestate-revert-a-write-made-right-after-the-first.md): verified
- [Docs: the dependency example in usage-state-dependency.md does not compile in Swift 6 mode](../../bugs/2026-11-16-docs-the-dependency-example-in-usage-state-dependency-md-does.md): verified
- [Docs: the restricted state example never keeps its value and grows the cache](../../bugs/2026-11-16-docs-the-restricted-state-example-never-keeps-its-value-and.md): verified

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

Closed 2026-11-17: done.

## Receipts

```yaml
receipts:
  - id: 2026-11-16-path-encoding-before-fix
    claim: "testDefaultFileStatePathIsNotPercentEncoded fails on 7e4eb92: the old expression appending(path:).path() returns a percent-encoded path for a documents directory with a space and an accent."
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:32Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-base64-filestate-before-fix
    claim: "testUnencodedFileStateReadsBackBase64LookingValues fails on 7e4eb92. "
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:49Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-path-encoding-after-fix
    claim: testDefaultFileStatePathIsNotPercentEncoded passes on 0821de7; all 13 tests of ReviewFixTests pass.
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:49Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-base64-filestate-after-fix
    claim: testUnencodedFileStateReadsBackBase64LookingValues passes on 0821de7; all 13 tests of ReviewFixTests pass.
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:51Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-promote-observer-before-fix
    claim: "testPromoteKeepsExternalChangeObserver fails on 7e4eb92. "
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:51Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-custom-objectwillchange-before-fix
    claim: "testWriteThroughHostWithCustomObjectWillChangeIsStored fails on 7e4eb92. "
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:52Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-promote-observer-after-fix
    claim: testPromoteKeepsExternalChangeObserver passes on 0821de7; all 13 tests of ReviewFixTests pass.
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:52Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-custom-objectwillchange-after-fix
    claim: testWriteThroughHostWithCustomObjectWillChangeIsStored passes on 0821de7; all 13 tests of ReviewFixTests pass.
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:53Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-override-release-before-fix
    claim: "testReleasingOverrideRestoresDependency fails on 7e4eb92. Three more override tests fail there too: release after cancel, overrides ended out of order, and release off the main thread."
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:53Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-override-release-after-fix
    claim: testReleasingOverrideRestoresDependency passes on 0821de7; all 13 tests of ReviewFixTests pass.
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:54Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-state-initial-before-fix
    claim: "testStateInitialIsEvaluatedOnce fails on 7e4eb92. "
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:55Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-state-initial-after-fix
    claim: testStateInitialIsEvaluatedOnce passes on 0821de7; all 13 tests of ReviewFixTests pass.
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:56Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-storedstate-reject-before-fix
    claim: "testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList fails on 7e4eb92. "
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:56Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-storedstate-reject-after-fix
    claim: testStoredStateRejectsValueThatIsNeitherJSONNorPropertyList passes on 0821de7; all 13 tests of ReviewFixTests pass.
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:29:57Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-write-after-read-before-fix
    claim: After reading a State, writing 5 and sleeping 0.3 s, the next read prints 0 on 7e4eb92.
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:30:13Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-docs-dependency-example-before-fix
    claim: "The dependency example from 7e4eb92 does not compile: type 'any NetworkServiceType' does not conform to the 'Sendable' protocol."
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:30:14Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-write-after-read-after-fix
    claim: After reading a State, writing 5 and sleeping 0.3 s, the next read prints 5 on 0821de7.
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:30:14Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-docs-dependency-example-after-fix
    claim: The dependency example from 0821de7 compiles in Swift 6 mode.
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:30:15Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-docs-restricted-example-before-fix
    claim: With the section 3.2 example from 7e4eb92, a read after writing 42 returns nil.
    result: failed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:30:15Z
    actor: claude-code (hc t34)
  - id: 2026-11-16-docs-restricted-example-after-fix
    claim: With the section 3.2 example from 0821de7, a read after writing 42 returns Optional(42).
    result: passed
    revision: 0821de760b8fc8ae782b14b9659c0211739d8442
    environment: local-macos-arm64
    content: c73d08f471642b2f5b330e5c064a02dbb4f35acb897e886bf532dd64ef9a5829
    observed: 2026-11-17T00:30:17Z
    actor: claude-code (hc t34)
```
