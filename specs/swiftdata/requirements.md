---
spec: swiftdata.spec.md
---

## User Stories

- As a developer, I want to register a SwiftData `ModelContainer` as an AppState dependency and resolve its `ModelContext` anywhere, including in view models and services.
- As a developer, I want to define a collection of `@Model` objects once on an `Application` extension and access it by key path through `@ModelState`.
- As a developer, I want to insert, delete, fetch, save, and reset persisted models through a simple, dependency-injected API.
- As a developer, I want a custom `FetchDescriptor` (filtering/sorting) to shape what a `ModelState` exposes.

## Acceptance Criteria

- `Application.modelContext(\.container)` returns the backing container's `mainContext`, and repeated calls return the same context.
- Reading `ModelState.value` performs a live fetch using the state's `FetchDescriptor`; an empty result returns `[]`.
- `insert(_:)`, `delete(_:)`, `save()`, and assigning `value` persist through the container's `mainContext`.
- `Application.reset(modelState:)` deletes every model matching the `FetchDescriptor` and saves, after which `value` is empty.
- A `ModelState` configured with a sorting `FetchDescriptor` returns models in the specified order.

## Constraints

- Available only where `canImport(SwiftData)` holds; minimum platforms iOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS 1.
- `ModelContext` access and all `ModelState` reads/writes are `@MainActor` isolated.
- `ModelContainer` must be `Sendable` (it is) to register as an AppState dependency.

## Out of Scope

- Automatic broadcasting of model mutations to SwiftUI (use SwiftData's `@Query` for reactive views).
- Caching of fetched model values in AppState's `Cache` (the `ModelContext` is the source of truth).
- Deleting models absent from an assigned `value` array (the setter only inserts new models; use `delete(_:)`/`reset()`).
