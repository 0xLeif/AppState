# Changelog

## 3.1.0

### Added

- `Application.didFailToPersist(_:)`, an overridable method that is called when a `FileState` file cannot be decoded, written or deleted, or when a `StoredState` or `SyncState` value cannot be encoded. It receives an `Application.PersistenceFailure` with the kind of state, the operation, the state's key and the underlying error. The default implementation does nothing, and logging is unchanged, so an app that does not override it behaves as before. A `FileState` that was never written is not reported. An unreadable file is reported once, not on every read.

### Fixed

- Overrides of the same dependency can end in any order. Ending an older override while a newer one was alive used to put the older value back at once, and left a stale override in place after both had ended. The dependency is now the newest override still alive, and the original once none is.

## 3.0.3

### Fixed

- A write to a `State` or `FileState` made right after its first read is no longer undone. Outside XCTest on Apple platforms the getter filled the cache from a deferred task, which ran after the write and put the older value back. The cache is now filled before the getter returns.
- `state(initial:)` evaluates its initial value once per scope, as documented, instead of on every access. A state with a `UUID()` or `Date()` initial now reads the same value every time, and `reset()` restores that first value.
- A write through `@AppState`, `@StoredState`, `@FileState`, `@SecureState`, `@SyncState`, `@Slice` or `@OptionalSlice` on an `ObservableObject` that declares its own `objectWillChange` is stored. It used to be dropped.
- `StoredState` no longer crashes with `NSInvalidArgumentException` on a value that `JSONEncoder` rejects, such as a struct holding `Double.nan`. The write is logged and ignored, and the previous value stays.
- A `FileState` created with `isBase64Encoded: false` reads back values whose JSON text is also valid Base64, such as `true` or `1234`. They used to read as the initial value after a relaunch.
- `Application.promote(to:)` keeps the promoted application registered for iCloud key-value store changes when `icloudStore` was loaded before the promotion.
- `FileManager.defaultFileStatePath` is no longer percent-encoded. A documents path with a space or a non-ASCII character pointed at a directory that does not exist.

### Changed

- Releasing a `DependencyOverride` restores the dependency, as the `override` documentation says. Before, only `cancel()` did. Code that discarded the token and relied on the override staying must now keep the token, or use `Application.promote(_:with:)` for a permanent replacement.

### Documentation

- The restricted state example in Advanced Usage keeps its ID in a constant. With `UUID()` inside the computed property the state never kept a value.
- The dependency example in State and Dependency Usage compiles in Swift 6 mode.

## 3.0.2

### Fixed

- `ModelState.deleteAll()` no longer fails silently on a model that has a relationship. In 3.0.1 SwiftData rejected the batch delete, the lenient `deleteAll()` logged and swallowed the error, and the rows stayed. `deleteAll()` now fetches the matching models and deletes each one, so cascade and nullify rules run.
- `ModelState.deleteAll()` ignores the descriptor's `fetchLimit` and `fetchOffset`, as it did in 3.0.1. It deletes every model matching the descriptor's predicate, and the next `models` read is empty. `models` still honors the limit and offset.
- A write through a `DependencySlice` of a struct now sticks. The change is stored on the dependency in `Application`, whether the write goes through `@DependencySlice` or `Application.dependencySlice`. An `Application.DependencySlice` handle created earlier reads and writes the current dependency, so it keeps sibling fields and edits an `override` installed after the handle was created.
- Concurrent `Keychain` `get`, `set`, and `remove` of the same key no longer deadlock. All three take one shared lock, including across `Keychain` instances.
- A `nil` write through an `OptionalSlice` stores `nil` when the field is optional. When the field is not optional, the write is ignored and nothing is notified.

### Known issues

- The other documentation languages still describe `deleteAll()` as deleting every model matching the whole `FetchDescriptor`. The English page says the predicate, and that `fetchLimit` and `fetchOffset` are ignored.
