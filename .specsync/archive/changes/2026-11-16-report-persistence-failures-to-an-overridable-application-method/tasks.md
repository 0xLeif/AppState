---
change: report-persistence-failures-to-an-overridable-application-method
artifact: tasks
---

# Tasks

- Add `Application+PersistenceFailure.swift` with the failure struct and the missing-file check.
- Add `open func didFailToPersist(_:)` to `Application`.
- Report from the five catch sites in `Application+FileState.swift`, `Application+StoredState.swift` and `Application+SyncState.swift`.
- Add `Tests/AppStateTests/PersistenceFailureTests.swift`.
- Add section 3.6 to `documentation/*/advanced-usage.md` and a 3.1.0 section to `CHANGELOG.md`.
- Leif reviews and decides whether it ships.
