---
spec: property-wrappers.spec.md
---

## User Stories

- As a developer, I want to declare `@AppState(\.keyPath)` in a SwiftUI view and have the view re-render automatically when the underlying `Application` value changes.
- As a developer, I want a `Binding` projected value (`$value`) so I can wire shared state directly to SwiftUI controls.
- As a developer, I want persisted variants (`@StoredState`, `@FileState`, `@SyncState`, `@SecureState`) that behave like `@AppState` but write through to `UserDefaults`, the file system, iCloud, or the Keychain.
- As a developer, I want to slice a sub-value of a larger state (`@Slice`, `@OptionalSlice`) or expose it read-only (`@Constant`, `@OptionalConstant`).
- As a developer, I want to resolve injected dependencies (`@AppDependency`, `@ObservedDependency`) and slice them (`@DependencySlice`, `@DependencyConstant`).
- As a developer, I want to read (read-only) and mutate SwiftData models from non-view code via `@ModelState`, with `insert`/`delete`/`save`/`deleteAll` on its projected value (the wrapped value cannot be assigned).
- As a developer, I want these wrappers to work inside an `ObservableObject` view model and drive its `objectWillChange`.

## Acceptance Criteria

- Each wrapper is constructed from a `KeyPath<Application, …>` and resolves all values through `Application.shared`; it stores no copy of the value.
- Reading `wrappedValue` of a reactive wrapper calls `Application.shared.registerObservation()`, registering an Observation dependency so SwiftUI re-renders on change.
- Mutating `wrappedValue` writes through `Application` (`app.value(keyPath:)`), which triggers `notifyChange()`; `@Constant`, `@OptionalConstant`, and `@DependencyConstant` expose no setter.
- On Apple platforms, reactive wrappers conform to `DynamicProperty` and provide a `Binding` projected value whose get/set round-trip through `wrappedValue`.
- The enclosing-instance subscript sends the host's `objectWillChange` only when its publisher is an `ObservableObjectPublisher`, then writes through.

## Constraints

- `@SyncState` and `@SecureState` compile only on Apple platforms (`!os(Linux) && !os(Windows)`); `@SyncState` is additionally `@available(watchOS 9.0, *)`.
- `@ModelState` compiles only where `canImport(SwiftData)`.
- `@AppState`, `@StoredState`, `@FileState`, `@AppDependency`, and the value slices/constants build cross-platform; their `Binding` projected values and enclosing-instance subscripts are compiled only on Apple platforms.
- `@StoredState`/`@FileState`/`@SyncState` require `Value: Codable & Sendable`; dependency wrappers require `Value` (and `SliceValue`) `Sendable`; `@ModelState` requires `Model: PersistentModel`.
- All `wrappedValue` access and mutation is `@MainActor` isolated.

## Out of Scope

- The storage mechanics themselves (UserDefaults/file/iCloud/Keychain encoding, cache, observation anchor) — owned by the `application` module.
- SwiftData `ModelContainer` setup and `Application.ModelState` internals — owned by the `swiftdata` spec.
- Automatic broadcast of `@ModelState` mutations to SwiftUI (use `@Query` for reactive views).

### REQ-property-wrappers-001

A writable DependencySlice of a struct value SHALL write the mutated field back onto the dependency stored in Application, and a later read SHALL show that write. A held slice SHALL read and write the dependency currently in the cache, keeping sibling fields written after the handle was created.

Acceptance Criteria

- A struct write through Application.dependencySlice or @DependencySlice stays visible on the stored dependency.
- A held DependencySlice does not restore sibling fields or a dependency captured when the handle was created.

### REQ-property-wrappers-002

A write through the enclosing-instance subscript of @AppState, @StoredState, @FileState, @SecureState, @SyncState, @Slice or @OptionalSlice SHALL be stored whatever the type of the host's objectWillChange. The host's publisher SHALL be sent before the write when it is an ObservableObjectPublisher.

Acceptance Criteria

- A host that declares objectWillChange as a PassthroughSubject reads back the value it wrote through @AppState.
- A host with the synthesized publisher still receives objectWillChange once per write.

