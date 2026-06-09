---
spec: application.spec.md
---

## Context

`Application` is the heart of AppState: a single, globally shared registry that centralizes state and dependency management so apps can avoid ad-hoc singletons and scattered `@EnvironmentObject` plumbing. State is defined declaratively as computed properties in `Application` extensions and accessed through property wrappers.

## Related Modules

- `property-wrappers` — the `@AppState`, `@StoredState`, `@FileState`, `@SyncState`, `@SecureState`, `@ModelState`, and slice/dependency wrappers that read and write `Application` state.
- `swiftdata` — the SwiftData `ModelContainer` dependency and `ModelState` built on top of `Application`.

## Design Decisions

- **Singleton + key paths.** State and dependencies are addressed by `KeyPath<Application, …>`, giving type-safe, autocomplete-friendly access without string keys.
- **Untracked cache + observation anchor.** Values live in a `Cache` (`@ObservationIgnored`). Because the cache is dynamically keyed, a single private anchor is read on every value access and bumped on every change, bridging the cache to the Observation framework with coarse but reliable view updates.
- **`@Observable` over `ObservableObject` (3.0).** Modernizes reactivity and works cross-platform; `NSObject` is retained so the `@objc` iCloud `didChangeExternally` hook continues to work.
- **Thread-safety via a recursive lock.** Value resolution is guarded so state can be read from any context, while mutation/observation are main-actor bound.
