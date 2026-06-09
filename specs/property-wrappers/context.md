---
spec: property-wrappers.spec.md
---

## Context

Property wrappers are how AppState is actually used day-to-day. The `Application` singleton holds the state and dependency registry, but developers rarely touch it directly: instead they declare `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@ModelState`, `@AppDependency`, `@ObservedDependency`, or one of the slice/constant wrappers, passing a `KeyPath<Application, …>`. The wrapper reads and writes the underlying value and, on Apple platforms, hands SwiftUI a `Binding` so the value can be bound to controls. This keeps call sites terse and type-safe while centralizing storage in `Application`.

## Related Modules

- `application` — owns the `Application` singleton, the `Cache`, `MutableApplicationState`, and the `state`/`storedState`/`fileState`/`syncState`/`secureState`/`modelState`/`dependency`/`slice`/`dependencySlice` resolvers plus `registerObservation()` / `notifyChange()` that every wrapper calls.
- `swiftdata` — defines the SwiftData `ModelContainer` dependency and `Application.ModelState` that `@ModelState` projects (`insert`/`delete`/`save`, `FetchDescriptor`).

## Design Decisions

- **Key paths over strings.** Each wrapper is addressed by `KeyPath<Application, …>`, giving compile-time-checked, autocomplete-friendly access to declared state and dependencies.
- **Observation instead of `@ObservedObject` (3.0).** State wrappers dropped their stored `@ObservedObject`. They now expose a computed `app` (`Application.shared`) and call `registerObservation()` inside the `wrappedValue` getter, letting SwiftUI track reads through the Observation framework (`Application` is `@Observable`). Setters write through `Application`, which calls `notifyChange()`. This removes per-wrapper Combine machinery and works the same way across all reactive wrappers.
- **`@ObservedDependency` keeps Combine.** Because it intentionally wraps an `ObservableObject` dependency, it still uses `@ObservedObject` and projects an `ObservedObject<Value>.Wrapper`.
- **Constants are read-only by construction.** `@Constant`, `@OptionalConstant`, and `@DependencyConstant` expose only a getter and do not conform to `DynamicProperty`, signaling immutable, non-reactive access.
- **Enclosing-instance subscript for view models.** Each reactive wrapper provides the `static subscript(_enclosingInstance:wrapped:storage:)` so it can live inside an `ObservableObject` host and drive that host's `objectWillChange` when written.
- **Platform gating.** `@SyncState`/`@SecureState` are Apple-only; `@ModelState` is SwiftData-only; `@AppState`/`@StoredState`/`@FileState`/`@AppDependency` and the value slices/constants build cross-platform, with `Binding` projected values compiled only on Apple platforms.
