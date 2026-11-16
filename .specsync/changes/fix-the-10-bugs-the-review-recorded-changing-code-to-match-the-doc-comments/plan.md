---
change: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments
artifact: plan
---

# Plan

## Approach

Fix each defect where it is, add one regression test per library bug, and correct the two examples in every language. Add requirements for the behaviours that had none.

## Out of scope

No change to the `FileManaging`, `UserDefaultsManaging` or `MutableApplicationState` protocols. No new state kinds. No commit, tag or release. The base `didChangeExternally` still does not call `notifyChange()`.

## Steps

1. State cache seeding, single evaluation of `initial`, and `reset()` keeping the first value.
2. Enclosing-instance setters in the seven wrappers.
3. `StoredState` setter, `FileManager.in`, `defaultFileStatePath`.
4. `promote(to:)` observer hand-over.
5. `DependencyOverride` release, and `ApplicationPreview`.
6. Regression tests, then the existing suites, filtered by class.
7. Docs in eight languages, doc comments, `CHANGELOG.md` 3.0.3, spec text.

## Risks

- Code that dropped an override token and relied on the override staying now loses it at scope exit. That is the documented behaviour, and it is called out in the changelog.
- `state(initial:)` now writes a cache entry when a state is first resolved, not when it is first read.
- A `StoredState` write that used to crash is now ignored and logged.
- `PropertyListSerialization` must exist on Linux, Windows and WASI. Only macOS is built here; CI covers the rest.

## Constraints consulted

`AGENTS.md`: Swift 6 with explicit access control; no force-unwrap, `try!` or `as!` in library code; no `@unchecked Sendable`; `SecureState`, `SyncState` and `Keychain` stay inside `canImport(Security)`; `@MainActor` XCTest methods are `async`.
