---
module: swiftdata
version: 1
status: draft
files:
  - Sources/AppState/Application/Types/Dependency/Application+ModelContainer.swift
  - Sources/AppState/Application/Types/State/Application+ModelState.swift
  - Sources/AppState/PropertyWrappers/State/ModelState.swift
db_tables: []
depends_on: ["application", "property-wrappers"]
---

# SwiftData

## Purpose

This module integrates Apple's SwiftData persistence framework with AppState's dependency and state system. It lets an app register a SwiftData `ModelContainer` as a normal AppState `Dependency`, resolve its main-actor `ModelContext` anywhere, and expose collections of `@Model` objects through a dependency-injected `Application.ModelState` value and the `@ModelState` property wrapper.

`ModelContainer` is `Sendable`, so it is stored as an ordinary AppState `Dependency<ModelContainer>` rather than requiring special handling. `ModelState` reads and writes through that container's `mainContext`; SwiftData's `ModelContext` — not AppState's `Cache` — is the source of truth. Because mutations are not automatically broadcast to SwiftUI, `ModelState` is intended for view models, services, and other non-view code; reactive views should use SwiftData's own `@Query` against the AppState-provided container.

The entire module is gated behind `#if canImport(SwiftData)` and requires iOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS 1. On platforms without SwiftData (Linux, Windows) it is compiled out entirely.

## Public API

### Application — SwiftData functions

| Function | Signature | Description |
|----------|-----------|-------------|
| modelContext | `static func modelContext(_: KeyPath<Application, Dependency<ModelContainer>>, …) -> ModelContext` | Resolves the `ModelContainer` dependency and returns its `mainContext` (main-actor isolated) |
| modelContainer | `func modelContainer(_: @autoclosure () -> ModelContainer, …) -> Dependency<ModelContainer>` | Registration convenience that defines a `Dependency<ModelContainer>` with a call-site-derived id; the autoclosure is evaluated once on first access |
| modelState | `static func modelState<Model>(_: KeyPath<Application, ModelState<Model>>, …) -> ModelState<Model>` | Retrieves a defined `ModelState<Model>` by key path |
| modelState | `func modelState<Model>(container:fetchDescriptor:feature:id:) -> ModelState<Model>` | Defines a `ModelState<Model>` backed by a container dependency, scoped by `feature`/`id`, using an explicit `FetchDescriptor` |
| modelState | `func modelState<Model>(container:feature:id:) -> ModelState<Model>` | Defines a `ModelState<Model>` that fetches all models of the type (default `FetchDescriptor`) |
| modelState | `func modelState<Model>(container:fetchDescriptor:…) -> ModelState<Model>` | Defines a `ModelState<Model>` with a call-site-derived id and an explicit `FetchDescriptor` |
| modelState | `func modelState<Model>(container:…) -> ModelState<Model>` | Defines a `ModelState<Model>` with a call-site-derived id that fetches all models of the type |
| reset | `static func reset<Model>(modelState: KeyPath<Application, ModelState<Model>>, …)` | Resets a `ModelState`, deleting every model it manages |

### Application.ModelState&lt;Model: PersistentModel&gt;

A `struct` conforming to `MutableApplicationState` with `Value == [Model]` and `emoji == "🗃️"`. All members below are `@MainActor`.

| Member | Signature | Description |
|--------|-----------|-------------|
| value (get) | `var value: [Model] { get }` | Fetches models matching the state's `FetchDescriptor`; returns `[]` and logs on failure |
| value (set) | `var value: [Model] { set }` | Inserts any models in the new value that are not yet persisted (`modelContext == nil`) and saves; does not delete absent models |
| context | `var context: ModelContext` | The `mainContext` of the backing `ModelContainer` dependency |
| insert | `func insert(_ model: Model)` | Inserts a model into the context and saves |
| delete | `func delete(_ model: Model)` | Deletes a model from the context and saves |
| save | `func save()` | Persists pending changes (no-op when `context.hasChanges` is false) |
| reset | `mutating func reset()` | Fetches every model matching the `FetchDescriptor`, deletes each, and saves |

### @ModelState property wrapper

A `@propertyWrapper` (also `DynamicProperty`) initialized with a `KeyPath<Application, Application.ModelState<Model>>`.

| Member | Type | Description |
|--------|------|-------------|
| wrappedValue (get) | `[Model]` | Registers an observation dependency, then returns the backing `ModelState.value` (a fetch) |
| wrappedValue (set) | `[Model]` | Assigns through `ModelState.value` (inserts new models + saves) |
| projectedValue | `Application.ModelState<Model>` | The underlying `ModelState`, exposing `insert(_:)`, `delete(_:)`, and `save()` |

## Invariants

1. The module only exists where `canImport(SwiftData)` holds (Apple platforms at iOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS 1); it is fully compiled out elsewhere.
2. `ModelContainer` is registered as a standard `Dependency<ModelContainer>` because it is `Sendable`; the same container resolves to one shared, main-actor `mainContext`.
3. SwiftData's `ModelContext` is the single source of truth. `ModelState` never caches model values in AppState's `Cache`; every `value` read performs a live fetch.
4. All `ModelState` reads, writes, and the resolution of `modelContext`/`context` are `@MainActor` isolated.
5. `ModelState.value`'s setter inserts only models whose `modelContext == nil`; it never deletes models absent from the assigned array (use `delete(_:)` or `reset()`).
6. Saving is conditional on `context.hasChanges`; `save` is a no-op when there are no pending changes.
7. Mutations through `ModelState` are not automatically broadcast to SwiftUI; reactive views must use SwiftData's `@Query` against the AppState-provided container.

## Behavioral Examples

```
Given an Application extension defining `modelContainer` via Application.modelContainer(try! ModelContainer(for: Item.self))
When Application.modelContext(\.modelContainer) is called more than once
Then the same main-actor ModelContext (the container's mainContext) is returned each time
```

```
Given a ModelState defined as `modelState(container: \.modelContainer)`
When insert(_:) is called with a new Item and then value is read
Then the Item is persisted through the container's mainContext
And the subsequent fetch returns an array containing that Item
```

```
Given a ModelState holding several persisted models
When Application.reset(modelState: \.items) is called
Then every model matching the state's FetchDescriptor is deleted and saved
And a following read of value returns an empty array
```

## Error Cases

| Error | When | Behavior |
|-------|------|----------|
| Fetch failure | `context.fetch(...)` throws while reading `value` or during `reset()` | Error is logged via `Application.log`; `value` returns `[]` |
| Save failure | `context.save()` throws on insert/delete/save/set | Error is logged via `Application.log`; the operation otherwise completes |
| Empty result | No models match the `FetchDescriptor` | `value` returns an empty array `[]` (not an error) |
| No pending changes | `save()` invoked with `context.hasChanges == false` | No-op; nothing is written |

## Dependencies

- SwiftData (Apple) — `ModelContainer`, `ModelContext`, `FetchDescriptor`, `PersistentModel`/`@Model`.
- AppState `Application` (`application` spec) — the dependency system (`Dependency<ModelContainer>`, `Application.dependency(_:)`), `Scope`, `MutableApplicationState`, `value(keyPath:)`, `registerObservation()`, and `Application.log`.
- AppState property wrappers (`property-wrappers` spec) — the `@ModelState` wrapper composes with the wider wrapper family.
- SwiftUI / Combine — `@ModelState` conforms to `DynamicProperty` and bridges to `ObservableObjectPublisher` for view-model use.

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-06-09 | Initial spec: SwiftData ModelContainer dependency + ModelState |
