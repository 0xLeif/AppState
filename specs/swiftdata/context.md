---
spec: swiftdata.spec.md
---

## Context

This module bridges Apple's SwiftData persistence framework into AppState. Apps already use `Application` to register dependencies and scoped state by key path; the SwiftData integration extends that model so a `ModelContainer` becomes a regular dependency and collections of `@Model` objects become an `Application.ModelState` accessible through the same key-path conventions and through the `@ModelState` property wrapper.

The integration deliberately layers on top of existing primitives rather than introducing a parallel storage system: there is no new cache, no new persistence path, and no string keys. SwiftData's `ModelContext` remains the source of truth.

## Related Modules

- `application` — provides the dependency system (`Dependency<ModelContainer>`, `Application.dependency`), `Scope`, `MutableApplicationState`, observation hooks, and logging that this module builds on.
- `property-wrappers` — the `@ModelState` wrapper sits alongside `@AppState`, `@StoredState`, `@SyncState`, `@SecureState`, and `@FileState`.

## Design Decisions

- **`ModelContainer` as a plain dependency.** `ModelContainer` is `Sendable`, so it is registered with the ordinary `Application.dependency` machinery via the `modelContainer(_:)` convenience instead of a bespoke storage type.
- **`ModelContext` is the source of truth.** `ModelState` does not store model values in AppState's `Cache`. Every `value` read performs a live `FetchDescriptor` fetch and every mutation writes straight to the container's `mainContext`, avoiding cache/store divergence.
- **Main-actor isolation.** SwiftData's `mainContext` is main-actor bound, so `modelContext`, `ModelState.context`, and all reads/writes are `@MainActor`.
- **Not auto-reactive.** Mutations are not broadcast to SwiftUI. The wrapper registers an observation dependency on read for view-model ergonomics, but reactive views are expected to use SwiftData's `@Query` against the AppState-provided container. `ModelState` targets view models, services, and non-view code that needs shared, dependency-injected model access.
- **Compiled out off-Apple.** Everything is wrapped in `#if canImport(SwiftData)` so Linux and Windows builds are unaffected.
