---
change: report-persistence-failures-to-an-overridable-application-method
artifact: plan
---

# Plan

## Approach

Add a public `Application.PersistenceFailure` struct and an `open` `didFailToPersist(_:)` method in the `Application` class body, next to `didChangeExternally(notification:)`. Call it from the five existing catch sites, after the existing log call, so nothing that happens today changes.

## Out of scope

- Keychain and SecureState failures.
- SwiftData, which already has throwing variants on `ModelState`.
- Caching or de-duplicating a failed read.
- Any change to the cache, the logger or the `FileManaging` protocol.

## Steps

1. Add `PersistenceFailure` and the missing-file check.
2. Add `didFailToPersist(_:)` to `Application`.
3. Report from the FileState read, write and delete sites, and from the StoredState and SyncState encode sites.
4. Add `PersistenceFailureTests`.
5. Document it in Advanced Usage in all eight languages and add a 3.1.0 changelog section.
6. Run every test class on macOS in strict and release builds, the Linux suite on Swift 6.1, and the WASI build.

## Risks

- A failed read is reported on each attempt, and `Application.fileState(_:)` reads the value once for its debug message, so one access can report twice. The doc comment says a failed read is reported again.
- A custom `FileManaging` that signals a missing file with its own error type is reported as a read failure.

## Constraints consulted

- AGENTS.md: explicit access control, no force-unwrap, `SyncState` only inside `canImport(Security)`, `@MainActor` XCTest methods are `async`.
- The 3.0.2 lesson bundle: run test classes with a filter in this checkout.
