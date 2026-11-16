---
module: application
version: 5
status: draft
files:
  - Sources/AppState/Application/Application.swift
  - Sources/AppState/Application/Application+public.swift
  - Sources/AppState/Application/Application+internal.swift
  - Sources/AppState/Application/Types/Dependency/Slice/Application+DependencySlice.swift
  - Sources/AppState/Application/Types/Dependency/Application+Dependency.swift
  - Sources/AppState/Application/Types/Helper/Application+ApplicationPreview.swift
  - Sources/AppState/Application/Types/Helper/Application+PersistenceFailure.swift
  - Sources/AppState/Application/Types/Helper/Application+Scope.swift
  - Sources/AppState/Application/Types/Helper/ApplicationLogger.swift
  - Sources/AppState/Application/Types/Helper/FileManager+AppState.swift
  - Sources/AppState/Application/Types/Helper/FileManaging.swift
  - Sources/AppState/Application/Types/Helper/Loggable.swift
  - Sources/AppState/Application/Types/Helper/MutableApplicationState.swift
  - Sources/AppState/Application/Types/Helper/UbiquitousKeyValueStoreManaging.swift
  - Sources/AppState/Application/Types/Helper/UserDefaultsManaging.swift
  - Sources/AppState/Application/Types/State/Application+FileState.swift
  - Sources/AppState/Application/Types/State/Application+SecureState.swift
  - Sources/AppState/Application/Types/State/Application+State.swift
  - Sources/AppState/Application/Types/State/Application+StoredState.swift
  - Sources/AppState/Application/Types/State/Application+SyncState.swift
  - Sources/AppState/Application/Types/State/Slice/Application+OptionalSlice.swift
  - Sources/AppState/Application/Types/State/Slice/Application+OptionalSliceOptionalValue.swift
  - Sources/AppState/Application/Types/State/Slice/Application+Slice.swift
  - Sources/AppState/Dependencies/Keychain.swift

db_tables: []
depends_on: []
---

# Application

## Purpose

The `Application` singleton manages global app state, dependencies, and scoped state containers. It provides a centralized registry for `State` values, secure state (Keychain), stored state (`UserDefaults`), synced state (iCloud), and file-backed state, and it manages dependency injection via the `Dependency` and `DependencySlice` types.

As of AppState 3.0 the singleton adopts Apple's Observation framework (`@Observable`) instead of `ObservableObject`. State and dependency values still live in an untracked `Cache`; a private observation anchor bridges cache changes to Observation so that SwiftUI views update reactively.

## Public API

### Exported Functions

| Export | Description |
|--------|-------------|
| Application.state(_:) | Retrieve or define a `State` value |
| Application.storedState(_:) | Retrieve or define a `UserDefaults`-backed state |
| Application.secureState(_:) | Retrieve or define a Keychain-backed state (Apple platforms) |
| Application.syncState(_:) | Retrieve or define an iCloud-backed state (Apple platforms) |
| Application.fileState(_:) | Retrieve or define a file-backed state |
| Application.dependency(_:) | Retrieve or define a dependency |
| Application.override(_:with:) | Temporarily override a dependency (previews/tests) |
| Application.promote(to:) | Promote the shared instance to a custom `Application` subclass |
| Application.reset(_:) | Reset a state to its initial value |
| Application.logging(isEnabled:) | Enable or disable AppState's internal logging |

> SwiftData support (`Application.modelState(_:)`, `Application.modelContext(_:)`) is documented in the `swiftdata` spec.

### Structs & Enums

| Type | Description |
|------|-------------|
| Application | `@Observable` singleton managing all app-wide state and dependencies (subclass of `NSObject`) |
| Application.Scope | Scope (name + id) used to derive unique keys for state and dependencies |
| Application.Dependency | Read-only injected dependency value |
| Application.DependencyOverride | Token that reverts a dependency override when released |
| ApplicationLogger | Logging utility used on Linux/Windows |

### Traits

| Trait | Description |
|-------|-------------|
| MutableApplicationState | Protocol for state types that expose a mutable `value` and a `reset()` |

### Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| state | `static func state<Value>(_: KeyPath<Application, State<Value>>) -> State<Value>` | Access a state value by key path |
| dependency | `static func dependency<Value>(_: KeyPath<Application, Dependency<Value>>) -> Value` | Resolve a dependency by key path |
| notifyChange | `func notifyChange()` | Ask observers (SwiftUI views) to update; called by AppState's setters and available for manual use (e.g. in `didChangeExternally` overrides) |

## Invariants

1. `Application` must always be a singleton; only one shared instance exists at runtime (`Application.shared`, main-actor isolated).
2. State and dependency values are stored in the `Cache`, which is `@ObservationIgnored`; observation is driven solely through the private change anchor via `registerObservation()` / `notifyChange()`.
3. Reading a value through a property wrapper registers an observation dependency; mutating a value notifies observers exactly once per change.
4. Dependency values are `Sendable`; dependency resolution must never cause retain cycles.
5. The library builds warning-free under the Swift 6 language mode with the `ExistentialAny` upcoming feature and `-warnings-as-errors`.
6. A `State` or `FileState` read fills the cache before it returns. A write made after a read in the same main-actor turn is the value later reads return.
7. `state(initial:)` evaluates its initial value once per scope while the state is cached, and `reset()` restores that first value.
8. A `DependencyOverride` restores the dependency it replaced on `cancel()` or on release, whichever comes first, and only once. Released on the main thread, it has restored before the release returns.
9. `promote(to:)` registers the promoted instance for the iCloud key-value store's external-change notification when the previous instance was registered.

## Behavioral Examples

```
Given an Application extension defining a state property
When the value is read via @AppState inside a SwiftUI view body
Then an observation dependency is registered for that view
And when the value is mutated, the view is asked to update via notifyChange()
```

```
Given a custom Application subclass overriding didChangeExternally(notification:)
When an iCloud change arrives
Then the subclass calls notifyChange() to refresh SwiftUI views
```

## Error Cases

| Error | When | Behavior |
|-------|------|----------|
| Keychain unavailable | SecureState accessed without entitlements | Returns the initial value; error logged |
| iCloud unavailable | SyncState accessed without iCloud capability | Falls back to the local value |
| Decode failure | Stored/File state data cannot be decoded | Returns the initial value; error logged |
| Encode failure | A `StoredState` value is neither JSON-encodable nor a property list | The write is ignored and logged; the previous value stays |

## Dependencies

- Cache (0xLeif/Cache) — underlying caching layer for state and dependency values
- Observation (Swift standard library) — `@Observable` reactivity
- Combine (Apple platforms) — bridges the cache's change notifications to the observation anchor

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-04-21 | Initial spec |
| 2 | 2026-06-09 | AppState 3.0: adopt Observation (`@Observable`); add `notifyChange()`; remove `ObservableObject` conformance; raise platform floors to iOS 17 / macOS 14; pin Swift 6 language mode + `ExistentialAny` |
| 3 | 2026-11-16 | make-modelstate-deleteall-remove-related-models-and-make-struct-dependency-slice-writes-stick: Make ModelState.deleteAll remove related models, and make struct dependency slice writes stick |
| 4 | 2026-11-16 | fix-the-10-bugs-the-review-recorded-changing-code-to-match-the-doc-comments: Fix the 10 bugs the review recorded, changing code to match the doc comments |
| 5 | 2026-11-16 | report-persistence-failures-to-an-overridable-application-method: Report persistence failures to an overridable Application method |
