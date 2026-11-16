---
change: fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments
artifact: requirements
---

# Requirements

- A value written to a `State` or `FileState` stays, whether or not it was read first in the same main-actor turn, and whether or not XCTest is loaded.
- `state(initial:)` evaluates its initial value once per scope while the state is cached. `reset()` still restores that first value.
- A write through a property wrapper on an `ObservableObject` host is stored whatever type the host's `objectWillChange` has. The host's publisher is sent when it is an `ObservableObjectPublisher`.
- `StoredState` never hands `UserDefaults` a value that is not a property list. A value that can be neither JSON-encoded nor stored as a property list is rejected, logged, and leaves the previous value in place.
- A `FileState` written with `isBase64Encoded: false` reads back the value written, for every JSON text.
- `Application.promote(to:)` keeps the promoted instance registered for `didChangeExternally` when the iCloud store was loaded before the promotion.
- `FileManager.defaultFileStatePath` is a plain file path, not a percent-encoded one.
- Releasing a `DependencyOverride` restores the dependency it replaced. `cancel()` still does, and the restore runs once.
- The restricted-state and `NetworkServiceType` examples work as written under Swift 6, in every documentation language.
