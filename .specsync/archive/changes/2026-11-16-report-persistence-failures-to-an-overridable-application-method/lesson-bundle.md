# Lesson bundle: report-persistence-failures-to-an-overridable-application-method

Material for folding this change's lessons into each affected module's lesson file.
Synthesise from what actually happened below; do not restate the change description.

## What this change was

- **Title**: Report persistence failures to an overridable Application method
- **Kind**: Feature
- **Specs**: application
- **Paths**: Sources/AppState/Application/Application+public.swift, Sources/AppState/Application/Application.swift, Sources/AppState/Application/Types/Helper/Application+PersistenceFailure.swift, Sources/AppState/Application/Types/State/Application+FileState.swift, Sources/AppState/Application/Types/State/Application+StoredState.swift, Sources/AppState/Application/Types/State/Application+SyncState.swift, Tests, documentation, specs, README.md, CHANGELOG.md, .chough, .specsync, knowledge, .github/workflows/iOS.yml, Examples/DemoApp
- **Acceptance**: PersistenceFailureTests passes: an Application subclass that overrides didFailToPersist hears a FileState read failure for a file that cannot be decoded, a FileState write failure, a rejected StoredState value and a SyncState value that cannot be encoded, each with the store, operation, key and error; it hears nothing for a successful round trip or for a FileState that was never written; an application without the override behaves as before; every test class passes on macOS under the strict build and in a release build, the Linux suite passes on Swift 6.1 and the WASI build passes

## Evidence

- Verification commit: `1daef60e3b1725e0e985b6aba9b6eb50f853117d`
- Base commit: `194067d89470cad8e27fa81a9fe006986a802958`
- Verified by: `specsync check --spec application`

## From the change's context.md

# Context

A failed FileState read, write or delete, and a StoredState or SyncState value that cannot be encoded, were visible only in the log. Logging is off by default, and on Apple platforms the logger is `os.Logger`, so an app could not react in code. A read silently returned the initial value, which looks the same as a state that was never written.

This came out of the review that produced the 3.0.3 fixes. Three other ideas from that review were checked and dropped:

- The collection-typed state crash on Linux does not reproduce on Swift 6.1, so the cache was left alone.
- Every English documentation example compiles once placeholder types are supplied, so no documentation build was added.
- CI already runs the whole test suite unfiltered on three platforms, so test isolation was left alone.

Keychain writes are not covered. `Keychain.set` discards the `OSStatus`, and no test here can force Security.framework to fail, so reporting it would be untested code.

The branch is stacked on the 3.0.3 fix branch.

## From the change's testing.md

# Testing

`Tests/AppStateTests/PersistenceFailureTests.swift` promotes an `Application` subclass that records each failure.

- `testSuccessfulFileStateRoundTripReportsNothing` writes and re-reads a file state from disk.
- `testFileStateThatWasNeverWrittenReportsNothing` reads a missing file and writes `nil` to it.
- `testUnreadableFileReportsReadFailureAndFallsBackToInitial` puts text that is not JSON in the file and checks the initial value, the store, the operation, the key and a `DecodingError`.
- `testUnwritableFileReportsWriteFailure` uses a directory path that is a regular file and finds one write failure.
- `testRefusedDeleteReportsDeleteFailure` overrides the file manager with one that refuses deletes, writes `nil`, and finds one delete failure.
- `testRejectedStoredStateValueReportsWriteFailure` writes a struct holding `Double.nan`, finds the previous value kept and one failure with an `EncodingError`.
- `testSyncStateValueThatCannotBeEncodedReportsWriteFailure` does the same for a `SyncState`, inside `canImport(Security)`.
- `testDefaultApplicationIgnoresFailures` reads an unreadable file with the base `Application`.

| Requirement | Test |
|---|---|
| REQ-application-007 | All eight tests in `PersistenceFailureTests` |

Run `APPSTATE_STRICT=1 swift test --filter 'AppStateTests.PersistenceFailureTests/'`. The documented example was also compiled and run in a scratch executable outside XCTest.

## Where these lessons go

- `specs/application/context.md`
