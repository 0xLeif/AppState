---
change: report-persistence-failures-to-an-overridable-application-method
artifact: testing
---

# Testing

`Tests/AppStateTests/PersistenceFailureTests.swift` promotes an `Application` subclass that records each failure.

- `testSuccessfulFileStateRoundTripReportsNothing` writes and re-reads a file state from disk.
- `testFileStateThatWasNeverWrittenReportsNothing` reads a missing file and writes `nil` to it.
- `testUnreadableFileReportsReadFailureAndFallsBackToInitial` puts text that is not JSON in the file and checks the initial value, the store, the operation, the key and a `DecodingError`.
- `testUnwritableFileReportsWriteFailure` uses a directory path that is a regular file and finds one write failure.
- `testRejectedStoredStateValueReportsWriteFailure` writes a struct holding `Double.nan`, finds the previous value kept and one failure with an `EncodingError`.
- `testSyncStateValueThatCannotBeEncodedReportsWriteFailure` does the same for a `SyncState`, inside `canImport(Security)`.
- `testDefaultApplicationIgnoresFailures` reads an unreadable file with the base `Application`.

| Requirement | Test |
|---|---|
| REQ-application-007 | All seven tests in `PersistenceFailureTests` |

Run `APPSTATE_STRICT=1 swift test --filter 'AppStateTests.PersistenceFailureTests/'`. The documented example was also compiled and run in a scratch executable outside XCTest.
