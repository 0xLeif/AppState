---
spec: property-wrappers.spec.md
---

## Test Plan

### Unit Tests

- `AppStateTests` — `@AppState` reads/writes through `Application`; property-wrapper round-trips; behavior across different value types; logging toggle.
- `StoredStateTests` — `@StoredState` persists to and reads back from `UserDefaults`; default/reset behavior.
- `FileStateTests` — `@FileState` persists to and reads back from the file system via `FileManager`.
- `SyncStateTests` — `@SyncState` round-trips through the iCloud key-value store (Apple platforms).
- `SecureStateTests` — `@SecureState` round-trips a `String?` through the Keychain (Apple platforms).
- `SliceTests` — `Application.slice(_:_:)` and the `@Slice` property wrapper read and write a sub-value of a backing state.
- `OptionalSliceTests` — `@OptionalSlice` get/set against a `nil` and non-`nil` parent, for both `WritableKeyPath<Value, SliceValue>` and `WritableKeyPath<Value, SliceValue?>` initializers.
- `DependencySliceTests` — `Application.dependencySlice(_:_:)` and `@DependencySlice` read and mutate a sub-value of a dependency.
- `ModelStateTests` — `@ModelState` fetch via `FetchDescriptor` (including predicates), insert via the `wrappedValue` setter, projected-value CRUD (`insert`/`delete`/`save`), `modelContext` dependency, and `reset`.
- `ObservedDependencyTests` — `@ObservedDependency` resolves an `ObservableObject` dependency and exposes it plus its `$`-projected `ObservedObject.Wrapper`.
- `ObservationTests` — reading a wrapper registers an Observation dependency and mutating the value fires the `registerObservation()` / `notifyChange()` bridge (`testMutatingStateNotifiesObservers`); negative case asserts no notification without a tracked mutation (`testReadingWithoutTrackedMutationDoesNotNotify`).

### Integration Tests

- Reactive SwiftUI view updates (re-render on state change, `Binding` two-way flow, enclosing-instance subscript driving an `ObservableObject` host) require a real Apple target and are verified manually; CI covers compilation, unit tests, and `-warnings-as-errors`.
