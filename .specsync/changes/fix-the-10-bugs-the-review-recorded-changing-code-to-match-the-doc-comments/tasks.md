---
change: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments
artifact: tasks
---

# Tasks

- Seed the `State` and `FileState` cache synchronously, return the cached `State` from `state(initial:)`, and keep the first initial across writes.
- Always write in the enclosing-instance setters of `AppState`, `StoredState`, `FileState`, `SecureState`, `SyncState`, `Slice` and `OptionalSlice`.
- Encode before committing in `StoredState`, with a property-list check on the fallback.
- Fall back to the raw bytes in `FileManager.in`, and stop percent-encoding `defaultFileStatePath`.
- Re-register the promoted application for external iCloud changes.
- Restore on release in `DependencyOverride`, once, and hold preview overrides in `@State`.
- Add `ReviewFixTests` with one test per library bug.
- Correct the two examples in all eight documentation languages, the doc comments, the specs, and add a 3.0.3 section to `CHANGELOG.md`.
- Leif reviews; nothing is committed by the agent.
