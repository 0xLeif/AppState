---
module: property-wrappers
version: 5
status: active
files:
  - Sources/AppState/PropertyWrappers/State/AppState.swift
  - Sources/AppState/PropertyWrappers/State/StoredState.swift
  - Sources/AppState/PropertyWrappers/State/FileState.swift
  - Sources/AppState/PropertyWrappers/State/SyncState.swift
  - Sources/AppState/PropertyWrappers/State/SecureState.swift
  - Sources/AppState/PropertyWrappers/State/ModelState.swift
  - Sources/AppState/PropertyWrappers/State/Slice/Slice.swift
  - Sources/AppState/PropertyWrappers/State/Slice/OptionalSlice.swift
  - Sources/AppState/PropertyWrappers/State/Slice/Constant.swift
  - Sources/AppState/PropertyWrappers/State/Slice/OptionalConstant.swift
  - Sources/AppState/PropertyWrappers/Dependency/AppDependency.swift
  - Sources/AppState/PropertyWrappers/Dependency/ObservedDependency.swift
  - Sources/AppState/PropertyWrappers/Dependency/Slice/DependencySlice.swift
  - Sources/AppState/PropertyWrappers/Dependency/Slice/DependencyConstant.swift

db_tables: []
depends_on: ["specs/application/application.spec.md"]
---

# Property-wrappers

## Purpose

The property wrappers are AppState's public surface for reading and writing `Application` state and dependencies from SwiftUI views, view models, and other code. Each wrapper is initialized with a `KeyPath<Application, …>` identifying the value it manages, and exposes that value through `wrappedValue` (and, on Apple platforms, a SwiftUI `Binding` or related `projectedValue`).

There are three families:

- **State wrappers** (`@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@ModelState`) read and write mutable, optionally persisted application state.
- **Dependency wrappers** (`@AppDependency`, `@ObservedDependency`) resolve injected, read-only dependency values.
- **Slice / Constant wrappers** (`@Slice`, `@OptionalSlice`, `@Constant`, `@OptionalConstant`, `@DependencySlice`, `@DependencyConstant`) provide granular access to a sub-value of a larger state or dependency via a nested key path.

As of AppState 3.0 the wrappers no longer hold an `@ObservedObject`. Instead each one exposes a computed `app` (`Application.shared`) and, in its `wrappedValue` getter, calls `Application.shared.registerObservation()` so that SwiftUI tracks reads through Apple's Observation framework (`Application` is `@Observable`). Writing through `wrappedValue` mutates the value via `Application`, which calls `notifyChange()` and refreshes dependent views.

## Public API

### Exported Functions

This module exports property wrapper types rather than free functions. The wrappers below are the public API; their `wrappedValue` getters call `Application.shared.registerObservation()` and their setters write through `Application`.

### Structs & Enums

#### State wrappers

| Wrapper | wrappedValue | projectedValue (Apple) | Platforms | Notes |
|---------|--------------|------------------------|-----------|-------|
| `@AppState<Value, ApplicationState>` | `Value` | `Binding<Value>` | All | In-memory `State`; `ApplicationState: MutableApplicationState`, `ApplicationState.Value == Value` |
| `@StoredState<Value>` | `Value` | `Binding<Value>` | All | `UserDefaults`-backed; `Value: Codable & Sendable` |
| `@FileState<Value>` | `Value` | `Binding<Value>` | All | `FileManager`-backed; `Value: Codable & Sendable` |
| `@SyncState<Value>` | `Value` | `Binding<Value>` | Apple only | iCloud `NSUbiquitousKeyValueStore`-backed; `Value: Codable & Sendable`; `@available(watchOS 9.0, *)` |
| `@SecureState` | `String?` | `Binding<String?>` | Apple only (`canImport(Security)`) | Keychain generic-password `String?`. Read calls `Application.secureState(_:).value`: the item, or the initial value when `get` returns nil (fail-open; a keychain or entitlement failure is the same nil and is not logged). Write of a string calls `Keychain.set`; write of nil calls `Keychain.remove`. Neither write reports status. The initial value is a read fallback, not a value stored at init. `reset()` writes that fallback back. |
| `@ModelState<Model>` | `[Model]` (read-only) | `Application.ModelState<Model>` | SwiftData (`canImport(SwiftData)`) | `Model: PersistentModel`; wrapped value is read-only (live fetch); mutate via the projected value's `insert`/`delete`/`save`/`deleteAll` |

#### Dependency wrappers

| Wrapper | wrappedValue | projectedValue (Apple) | Platforms | Notes |
|---------|--------------|------------------------|-----------|-------|
| `@AppDependency<Value>` | `Value` | none | All | Read-only resolved dependency; `Value: Sendable` |
| `@ObservedDependency<Value>` | `Value` | `ObservedObject<Value>.Wrapper` | Apple only | `Value: Sendable & ObservableObject`; wraps the dependency in `@ObservedObject` |

#### Slice / Constant wrappers

| Wrapper | wrappedValue | projectedValue (Apple) | Mutable | Notes |
|---------|--------------|------------------------|---------|-------|
| `@Slice<SlicedState, Value, SliceValue>` | `SliceValue` | `Binding<SliceValue>` | Yes | `SlicedState.Value == Value`; sub-value via `WritableKeyPath<Value, SliceValue>` |
| `@OptionalSlice<SlicedState, Value, SliceValue>` | `SliceValue?` | `Binding<SliceValue?>` | Yes | `SlicedState.Value == Value?`; init from a `WritableKeyPath` to `SliceValue` or `SliceValue?` |
| `@Constant<SlicedState, Value, SliceValue, SliceKeyPath>` | `SliceValue` | none | No (read-only) | Read-only slice; accepts a `KeyPath` or `WritableKeyPath` to the sub-value |
| `@OptionalConstant<SlicedState, Value, SliceValue>` | `SliceValue?` | none | No (read-only) | `SlicedState.Value == Value?`; read-only optional slice |
| `@DependencySlice<Value, SliceValue>` | `SliceValue` | `Binding<SliceValue>` | Yes | Slices a dependency; `Value, SliceValue: Sendable`; setter calls `notifyChange()` (Apple) |
| `@DependencyConstant<Value, SliceValue, SliceKeyPath>` | `SliceValue` | none | No (read-only) | Read-only slice of a dependency |

### Exported Traits

| Trait | Description |
|-------|-------------|
| `DynamicProperty` (SwiftUI) | On Apple platforms every state and slice wrapper, plus `@SyncState`, `@SecureState`, `@ModelState`, `@ObservedDependency`, and `@DependencySlice`, conforms to `DynamicProperty` so SwiftUI installs them as view storage. `@AppDependency`, `@Constant`, `@OptionalConstant`, and `@DependencyConstant` do not. |

> Cross-module bound: `MutableApplicationState` — the generic bound for `@AppState`, `@Slice`, `@OptionalSlice`, `@Constant`, and `@OptionalConstant`, whose backing state exposes a mutable `value` — is owned by the `application` module; see `application.spec.md`. It is intentionally **not** listed as a property-wrappers export (doing so would duplicate ownership, the bug #162 fixed for `ModelState`).

### Exported Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `wrappedValue` get | `var wrappedValue: Value { get }` | Calls `app.registerObservation()` then returns the value resolved from `Application` (e.g. `Application.state(_:)`, `Application.slice(_:_:)`, `Application.dependency(_:)`) |
| `wrappedValue` set | `nonmutating set` | Logs the change, then mutates via `app.value(keyPath:)`, writing the new value back through `Application` (which triggers `notifyChange()`) |
| `projectedValue` | `var projectedValue: Binding<Value>` (Apple) | A `Binding` whose get/set forward to `wrappedValue`; `@ModelState` instead projects `Application.ModelState<Model>`, `@ObservedDependency` projects `ObservedObject<Value>.Wrapper` |
| enclosing-instance subscript | `static subscript<OuterSelf: ObservableObject>(_enclosingInstance:wrapped:storage:)` | Supports use inside an `ObservableObject` host (view model): reads forward to `wrappedValue`; writes send the host's `objectWillChange` then write through (Apple platforms; not on `@Constant`/`@DependencyConstant`/`@AppDependency`) |
| `wrappedValue` | TODO | Document caller-visible behavior and constraints. |
| `init` | TODO | Document caller-visible behavior and constraints. |
| `AppState` | TODO | Document caller-visible behavior and constraints. |
| `StoredState` | TODO | Document caller-visible behavior and constraints. |
| `FileState` | TODO | Document caller-visible behavior and constraints. |
| `SyncState` | TODO | Document caller-visible behavior and constraints. |
| `SecureState` | `@propertyWrapper public struct SecureState: DynamicProperty` | `canImport(Security)`. Holds the key path, not the secret. `wrappedValue`, `projectedValue`, `init`, and the enclosing-instance subscript are `@MainActor`. Get calls `registerObservation()`, then `Application.secureState(keyPath, fileID, function, line, column).value`, so every read uses the `Keychain` generic-password item for that scope. When `get` returns nil the result is the initial `String?` from that read's factory call. Fail-open: missing item, bad UTF-8, and any failed Security status share that fallback. No error is logged and `didFailToPersist` is not called. When logging is enabled, that key-path read debug-logs the returned string in a DEBUG build. Set, when logging is enabled, debug-logs too, and a DEBUG build interpolates the new string into the message. It then copies `Application.SecureState` and assigns `value`, which calls `notifyChange()` and then `Keychain.set` or, for nil, `Keychain.remove`. Those calls ignore Security status (silent drop). The next read after a nil write returns the initial value again, not a stored nil. `projectedValue` forwards to `wrappedValue`. The subscript sends `objectWillChange` when it is an `ObservableObjectPublisher`, then always assigns `wrappedValue`. No rotation, key derivation, or protection class is chosen in this wrapper. |
| `ModelState` | TODO | Document caller-visible behavior and constraints. |
| `Slice` | TODO | Document caller-visible behavior and constraints. |
| `OptionalSlice` | TODO | Document caller-visible behavior and constraints. |
| `Constant` | TODO | Document caller-visible behavior and constraints. |
| `OptionalConstant` | TODO | Document caller-visible behavior and constraints. |
| `AppDependency` | TODO | Document caller-visible behavior and constraints. |
| `ObservedDependency` | TODO | Document caller-visible behavior and constraints. |
| `DependencySlice` | TODO | Document caller-visible behavior and constraints. |
| `DependencyConstant` | TODO | Document caller-visible behavior and constraints. |

## Invariants

1. Every wrapper is constructed with a `KeyPath<Application, …>` and resolves all values through `Application.shared`; the wrapper holds no copy of the value itself.
2. Reading `wrappedValue` of a reactive wrapper calls `Application.shared.registerObservation()` exactly once per access, registering an Observation dependency so SwiftUI re-renders when the value changes.
3. Wrappers no longer hold `@ObservedObject` for state (3.0); reactivity flows through Observation, not Combine `objectWillChange`. (`@ObservedDependency` is the sole exception and intentionally wraps an `ObservableObject`.)
4. Mutating `wrappedValue` writes through `Application`, which calls `notifyChange()` so observers update; `@Constant`, `@OptionalConstant`, and `@DependencyConstant` are read-only and expose no setter.
5. `@SyncState` and `@SecureState` compile only on Apple platforms (`!os(Linux) && !os(Windows)`); `@ModelState` compiles only where `canImport(SwiftData)`. `@AppState`, `@StoredState`, `@FileState`, `@AppDependency`, and the value slices/constants build cross-platform.
6. On Apple platforms each reactive wrapper conforms to `DynamicProperty`; the `Binding` projected value's get and set both round-trip through `wrappedValue`.
7. The enclosing-instance subscript sends `objectWillChange` when the host's publisher is an `ObservableObjectPublisher`, and always writes the value. A host that declares its own `objectWillChange` of another type still has its write stored.
8. `Value` (and `SliceValue`) of dependency wrappers is `Sendable`; `Value` of `@StoredState`/`@FileState`/`@SyncState` is `Codable & Sendable`.

## Behavioral Examples

```
Given an Application extension defines `var counter: State<Int>`
When a SwiftUI view reads `@AppState(\.counter) var counter` in its body
Then the getter calls Application.shared.registerObservation()
And an Observation dependency is registered for that view
And when `counter` is later mutated, Application.notifyChange() asks the view to update
```

```
Given `@StoredState(\.username) var username`
When the view writes `username = "ada"`
Then the setter logs the change
And writes the new value through Application.value(keyPath:), persisting it to UserDefaults
And dependent views refresh via notifyChange()
```

```
Given a struct `Settings` with `var volume: Double` stored in `State<Settings>`
When a view uses `@Slice(\.settings, \.volume) var volume`
Then reading `volume` registers an Observation dependency and returns settings.volume
And writing `volume = 0.5` mutates only the `volume` sub-value of the backing Settings state
```

```
Given `@ModelState(\.todos) var todos` backed by a SwiftData ModelContainer dependency
When the view reads `todos`
Then a FetchDescriptor fetch returns the matching [Todo] (the wrapped value is read-only; it cannot be assigned)
And `$todos.insert(newTodo)` / `$todos.delete(todo)` / `$todos.save()` / `$todos.deleteAll()` mutate the backing context via the projected value
And (note) these mutations are not auto-broadcast to SwiftUI; use @Query for reactive views
```

```
Given a dependency `Value: ObservableObject` injected at `\.session`
When a view uses `@ObservedDependency(\.session) var session`
Then the wrapper resolves the dependency once at init and wraps it in @ObservedObject
And the view updates when the dependency itself publishes objectWillChange
```

```
Given a wrapper used inside an ObservableObject view model
When the view model writes through the wrapper's enclosing-instance subscript
Then the host's objectWillChange publisher is sent (if it is an ObservableObjectPublisher)
And the value is written through to Application
```

## Error Cases

| Error | When | Behavior |
|-------|------|----------|
| Keychain read failed, missing entitlement, or item missing | `@SecureState` read whose `Keychain.get` returns nil | Fail-open: returns the initial value. No error is logged and `didFailToPersist` is not called. A DEBUG build with logging enabled debug-logs the secret on that read and on a write; logging is off by default. Writes call `Keychain.set` or `remove` and ignore the Security status. Storage rules are the `application` module's `Keychain` and `Application.SecureState` rows. |
| iCloud unavailable | `@SyncState` accessed without iCloud capability | Falls back to the local value |
| Decode failure | `@StoredState` / `@FileState` data cannot be decoded | Returns the initial value; error logged |
| SwiftData fetch/save failure | `@ModelState` read or `insert`/`delete`/`save`/`deleteAll` fails | Surfaced by `Application.ModelState`; see the `swiftdata` spec |
| `nil` parent in optional slice | `@OptionalSlice` whose backing `Value?` is `nil` | Getter returns `nil`; setter is a no-op against the missing parent |
| Non-`ObservableObjectPublisher` host | Enclosing-instance subscript set on a host without an `ObservableObjectPublisher` | Write is skipped (guard returns) |

## Dependencies

- `application` (this repo) — all wrappers resolve values through `Application` (`Application.state/storedState/fileState/syncState/secureState/modelState/dependency/slice/dependencySlice`, `registerObservation()`, `notifyChange()`, `MutableApplicationState`).
- SwiftUI (Apple platforms) — `DynamicProperty`, `Binding`, `ObservedObject` for projected values and reactive installation.
- Observation (Swift standard library) — the `@Observable` `Application` drives view updates via `registerObservation()`.
- Combine (Apple platforms) — imported for `ObservableObjectPublisher` used by the enclosing-instance subscript.
- SwiftData (`canImport(SwiftData)`) — `@ModelState` only; `PersistentModel`, `ModelContainer`, `FetchDescriptor`. See the `swiftdata` spec for details.

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-04-21 | Initial spec |
| 2 | 2026-06-09 | Author full spec; Observation-based reactivity; add `@ModelState` |
| 2 | 2026-06-09 | `@ModelState` wrapped value is read-only `[Model]` (live fetch); mutate via the projected value's `insert`/`delete`/`save`/`deleteAll` (no wrapped-value assignment) |
| 3 | 2026-11-16 | make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick: Make ModelState.deleteAll remove related models, and make struct dependency slice writes stick |
| 4 | 2026-11-16 | fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments: Fix the 10 bugs the review recorded, changing code to match the doc comments |
| 5 | 2026-11-20 | Document `@SecureState` from source: each read hits Keychain and falls open to the initial value; writes call `set` or `remove` and ignore status. The old error row said an error is logged; the source does not log the Security status. |
