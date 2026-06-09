---
spec: swiftdata.spec.md
---

## Test Plan

### Unit Tests

`ModelStateTests` (`Tests/AppStateTests/ModelStateTests.swift`), using an in-memory `ModelContainer` (`ModelConfiguration(isStoredInMemoryOnly: true)`) over a `TestItem` `@Model`:

- `testModelContextDependency` — `Application.modelContext(\.modelContainer)` returns the same context across calls; direct insert/save/fetch through that context round-trips.
- `testInsertAndFetchThroughApplication` — `Application.modelState(\.items)` starts empty, and `insert(_:)` followed by reading `models` returns the persisted models.
- `testPropertyWrapperReadAndProjectedInsert` — reading a `@ModelState` wrapped value reflects models inserted elsewhere, and `$items.insert(_:)` inserts and saves; works from both a value type and an `ObservableObject` view model.
- `testProjectedValueCRUD` — `$items.insert`, `$items.delete`, and `$items.save` perform create/delete/update through the projected `ModelState`.
- `testDeleteAll` — after inserting several models, `$items.deleteAll()` empties the state.
- `testFetchDescriptorSorting` — a `ModelState` configured with a sorting `FetchDescriptor` returns models in ascending order.

`setUp`/`tearDown` call `deleteAll()` on `\.items` and assert the state is empty, keeping each test isolated against the shared in-memory store.

### Integration Tests

- Reactive `@Query`-driven view updates require a real Apple target and are verified manually. CI covers compilation (Apple platforms), the unit tests above, and `-warnings-as-errors`. On Linux/Windows the module and its tests are compiled out via `#if canImport(SwiftData)`.
