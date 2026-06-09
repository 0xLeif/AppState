# ModelState Usage

🍎 `ModelState` is a component of the **AppState** library that lets you manage SwiftData `@Model` objects through the application's scope. It injects a shared SwiftData `ModelContainer` as a dependency and reads from and writes to that container's `ModelContext`, giving view models, services, and other non-view code shared, dependency-injected access to your models.

> 🍎 `ModelState` and the SwiftData `ModelContainer` dependency are specific to Apple platforms, as they rely on Apple's SwiftData framework.

## Key Features

- **Dependency-Injected Models**: Register a shared `ModelContainer` once and access its models anywhere in your app.
- **Main-Actor `ModelContext`**: Retrieve the container's `mainContext` from any code, including view models and services that have no access to SwiftUI's `@Environment`.
- **CRUD Convenience**: Read, insert, delete, save, and delete-all SwiftData models through a small, focused API.
- **SwiftData as the Source of Truth**: `ModelState` does not cache results in AppState's cache — SwiftData's `ModelContext` remains the single source of truth.

## Requirements & Availability

SwiftData features require newer platform versions than AppState's base requirements. All `ModelState` and `ModelContainer` APIs are gated behind `#if canImport(SwiftData)` and the following availability:

- **iOS**: 17.0+
- **macOS**: 14.0+
- **tvOS**: 17.0+
- **watchOS**: 10.0+
- **visionOS**: 1.0+

On platforms or OS versions where SwiftData is unavailable, these APIs are not compiled in.

## Registering the ModelContainer Dependency

SwiftData's `ModelContainer` is `Sendable`, so it can be stored as a regular AppState `Dependency`. Define one on an `Application` extension using the `modelContainer(_:)` convenience, which registers the container with an automatically generated identifier and evaluates the autoclosure only once. Build the container through a helper that handles failures explicitly rather than force-trying:

```swift
import AppState
import SwiftData

private func makeModelContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: Item.self)
    } catch {
        fatalError("Failed to create the ModelContainer: \(error)")
    }
}

extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## Accessing the ModelContext

Once a `ModelContainer` dependency is defined, you can access the shared, main-actor bound `ModelContext` anywhere in your app:

```swift
let context = Application.modelContext(\.modelContainer)
```

This returns the `mainContext` of the resolved `ModelContainer`, so the same context is shared throughout your app.

## Defining a ModelState

Define a `ModelState` by extending the `Application` object and pointing it at the `ModelContainer` dependency that backs it. With no `FetchDescriptor`, the state matches all models of the given type:

```swift
import AppState
import SwiftData

extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

You can also provide a custom `FetchDescriptor` (for filtering or sorting) and an explicit `id`:

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(
            container: \.modelContainer,
            fetchDescriptor: FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\.title)]
            ),
            id: "items"
        )
    }
}
```

## The @ModelState Property Wrapper

The `@ModelState` property wrapper exposes a read-only collection of models from the `Application`'s scope. Mutate through the projected value (`$items`):

```swift
import AppState
import SwiftData

@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func addItem(title: String) {
        $items.insert(Item(title: title))
    }
}
```

- **Reading** the wrapped value performs a fetch using the state's `FetchDescriptor`. The wrapped value is a read-only `[Model]` — you cannot assign to it.
- **Mutating** is done through the projected value: `$items.insert(...)`, `$items.delete(...)`, `$items.save()`, and `$items.deleteAll()`.

> ⚠️ Reading the wrapped value performs a live SwiftData fetch on **every** read. Avoid reading it repeatedly in hot paths — capture the result in a local instead.

### CRUD via the Projected Value

The projected value (`$items`) exposes the underlying `Application.ModelState<Item>`, giving you explicit control over inserts, deletes, and saves:

```swift
@MainActor
final class ItemsViewModel: ObservableObject {
    @ModelState(\.items) var items: [Item]

    func add(_ item: Item) {
        $items.insert(item)
    }

    func remove(_ item: Item) {
        $items.delete(item)
    }

    func persistPendingChanges() {
        $items.save()
    }
}
```

## Reading and Mutating via Application.modelState

You can also work with the `ModelState` directly through the `Application` type, without a property wrapper. This is convenient in services and other non-view code:

```swift
@MainActor
func loadAndAppend() {
    let state = Application.modelState(\.items)

    // Read the current models (performs a fetch on every access).
    let current = state.models

    // Access the backing ModelContext directly if needed.
    let context = state.context

    // Insert, delete, and save.
    state.insert(Item(title: "New item"))
    state.delete(current.first!)
    state.save()
}
```

> ⚠️ `models` performs a live SwiftData fetch on **every** read. Capture it in a local when you need to use the result more than once instead of reading it repeatedly.

The returned `ModelState` exposes:

- `models`: a **read-only** property returning the models currently matching the state's `FetchDescriptor`. Every read performs a fresh fetch; there is no setter.
- `context`: the backing main-actor `ModelContext`.
- `insert(_:)`: inserts a model and saves.
- `delete(_:)`: deletes a model and saves.
- `save()`: persists any pending changes in the context.
- `deleteAll()`: deletes every model matching the state's `FetchDescriptor` and saves.

## Deleting All Models

To delete every model managed by a `ModelState`, use `deleteAll()`:

```swift
Application.modelState(\.items).deleteAll()
```

This fetches every model matching the state's `FetchDescriptor`, deletes it, and saves the context.

## When to Use ModelState vs SwiftData @Query

Mutations made through `ModelState` and `@ModelState` are **not** automatically broadcast to SwiftUI. This is an intentional design choice:

- **Use SwiftData's own `@Query` for reactive views.** `@Query` observes the `ModelContext` and automatically refreshes your view when the underlying data changes. Combine it with the AppState-provided `ModelContainer` so your views and your non-view code share the same container:

  ```swift
  import SwiftData
  import SwiftUI

  struct ItemsView: View {
      @Query(sort: \Item.title) private var items: [Item]

      var body: some View {
          List(items) { item in
              Text(item.title)
          }
      }
  }

  // Inject the shared container into the SwiftUI environment.
  @main
  struct MyApp: App {
      var body: some Scene {
          WindowGroup {
              ItemsView()
          }
          .modelContainer(Application.dependency(\.modelContainer))
      }
  }
  ```

- **Use `ModelState` / `@ModelState` for view models, services, and other non-view code** that needs shared, dependency-injected access to your models. It is ideal where SwiftUI's `@Environment` and `@Query` are not available, or where you want to perform model operations outside of view code.

Also note that the models collection is read-only — you cannot assign to it. Use `insert(_:)`, `delete(_:)`, or `deleteAll()` to mutate the underlying store.

## End-to-End Example

The following example shows a complete flow: a `@Model`, the `Application` extensions registering the container and the model state, and a view model that uses `@ModelState`.

```swift
import AppState
import SwiftData
import SwiftUI

// 1. Define the SwiftData model.
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Register the shared ModelContainer and a ModelState on Application.
private func makeModelContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: TodoItem.self)
    } catch {
        fatalError("Failed to create the ModelContainer: \(error)")
    }
}

extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }

    var todoItems: ModelState<TodoItem> {
        modelState(
            container: \.modelContainer,
            fetchDescriptor: FetchDescriptor<TodoItem>(
                sortBy: [SortDescriptor(\.title)]
            ),
            id: "todoItems"
        )
    }
}

// 3. Use @ModelState from a view model.
@MainActor
final class TodoListViewModel: ObservableObject {
    @ModelState(\.todoItems) var todoItems: [TodoItem]

    func add(title: String) {
        $todoItems.insert(TodoItem(title: title))
    }

    func toggle(_ item: TodoItem) {
        item.isComplete.toggle()
        $todoItems.save()
    }

    func remove(_ item: TodoItem) {
        $todoItems.delete(item)
    }

    func clearAll() {
        $todoItems.deleteAll()
    }
}
```

For a reactive list bound to the same data, drive the view with SwiftData's `@Query` while keeping mutations in the view model, as shown in the [When to Use ModelState vs SwiftData @Query](#when-to-use-modelstate-vs-swiftdata-query) section above.

## Best Practices

- **Reactive Views Use `@Query`**: Reserve SwiftData's `@Query` for views that need to update automatically, and share the AppState-provided `ModelContainer` with them.
- **Non-View Code Uses `ModelState`**: Use `@ModelState` and `Application.modelState` in view models, services, and background logic that need shared model access.
- **Explicit Mutation**: The models collection is read-only; use `insert(_:)`, `delete(_:)`, or `deleteAll()` to change the underlying store.
- **One Shared Container**: Register a single `ModelContainer` dependency and reference it from your model states and SwiftUI environment so everything reads and writes the same store.

## Conclusion

`ModelState` brings SwiftData into the **AppState** dependency-injection model, letting you share a single `ModelContainer` across your app and work with `@Model` objects from view models and services. For reactive UI, pair it with SwiftData's `@Query` and the same shared container.
