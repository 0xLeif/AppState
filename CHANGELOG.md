# Changelog

## 3.0.2

### Fixed

- `ModelState.deleteAll()` no longer fails silently on a model that has a relationship. In 3.0.1 SwiftData rejected the batch delete, the lenient `deleteAll()` logged and swallowed the error, and the rows stayed. `deleteAll()` now fetches the matching models and deletes each one, so cascade and nullify rules run.
- `ModelState.deleteAll()` ignores the descriptor's `fetchLimit` and `fetchOffset`, as it did in 3.0.1. It deletes every model matching the descriptor's predicate, and the next `models` read is empty. `models` still honors the limit and offset.
- A write through a `DependencySlice` of a struct now sticks. The change is stored on the dependency in `Application`, whether the write goes through `@DependencySlice` or `Application.dependencySlice`. An `Application.DependencySlice` handle created earlier reads and writes the current dependency, so it keeps sibling fields and edits an `override` installed after the handle was created.
- Concurrent `Keychain` `get`, `set`, and `remove` of the same key no longer deadlock. All three take one shared lock, including across `Keychain` instances.
- A `nil` write through an `OptionalSlice` stores `nil` when the field is optional. When the field is not optional, the write is ignored and nothing is notified.

### Known issues

- The other documentation languages still describe `deleteAll()` as deleting every model matching the whole `FetchDescriptor`. The English page says the predicate, and that `fetchLimit` and `fetchOffset` are ignored.
