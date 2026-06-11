# ModelState Usage

🍎 `ModelState` lets you manage SwiftData `@Model` objects through AppState's dependency-injection model. Register a shared `ModelContainer` once; read and write models from anywhere — view models, services, or other non-view code — without threading `ModelContext` through your call stack.

> 🍎 `ModelState` requires Apple platforms with SwiftData support (iOS 17+, macOS 14+, tvOS 17+, watchOS 10+, visionOS 1+). These APIs are compiled out on Linux and Windows.

## End-to-End Example

```swift
import AppState
import SwiftData
import SwiftUI

// 1. Define the model.
@Model
final class TodoItem {
    var title: String
    var isComplete: Bool

    init(title: String, isComplete: Bool = false) {
        self.title = title
        self.isComplete = isComplete
    }
}

// 2. Register the shared container and a ModelState on Application.
private func makeModelContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: TodoItem.self)
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
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

## Registering the ModelContainer

`modelContainer(_:)` registers the container with an auto-generated identifier and evaluates the autoclosure only once. Build the container in a helper rather than inline — it makes failures explicit:

```swift
extension Application {
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }
}
```

## Defining a ModelState

With no `FetchDescriptor`, the state matches all models of the given type:

```swift
extension Application {
    var items: ModelState<Item> {
        modelState(container: \.modelContainer)
    }
}
```

Supply a `FetchDescriptor` for filtering or sorting:

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

## Reading and Mutating

**Via `@ModelState`** — read the wrapped value, mutate through `$items`:

```swift
@ModelState(\.items) var items: [Item]

func add(_ item: Item) { $items.insert(item) }
func remove(_ item: Item) { $items.delete(item) }
func persist() { $items.save() }
```

**Via `Application.modelState`** — useful in services and non-view code:

```swift
@MainActor
func syncItems() {
    let state = Application.modelState(\.items)
    let current = state.models
    state.insert(Item(title: "New"))
    state.delete(current.first!)
    state.save()
}
```

> `models` performs a live SwiftData fetch on every read. Capture the result in a local when you need it more than once.

### Projected-value API

| Method | Behavior |
| --- | --- |
| `$items.insert(_:)` | Inserts a model and saves |
| `$items.delete(_:)` | Deletes a model and saves |
| `$items.save()` | Persists pending changes |
| `$items.deleteAll()` | Deletes all models matching the `FetchDescriptor` and saves |

## Accessing the ModelContext

```swift
let context = Application.modelContext(\.modelContainer)
```

Returns the `mainContext` of the resolved `ModelContainer` — the same context used by all reads and writes.

## ModelState vs SwiftData @Query

`ModelState` mutations are **not** automatically broadcast to SwiftUI views. This is intentional.

- **Reactive views** — use `@Query`. It observes the `ModelContext` directly and refreshes the view when data changes. Share the AppState-provided container with the SwiftUI environment so views and non-view code use the same store:

  ```swift
  @main
  struct MyApp: App {
      var body: some Scene {
          WindowGroup {
              ItemsView()
          }
          .modelContainer(Application.dependency(\.modelContainer))
      }
  }

  struct ItemsView: View {
      @Query(sort: \Item.title) private var items: [Item]

      var body: some View {
          List(items) { Text($0.title) }
      }
  }
  ```

- **View models and services** — use `@ModelState` / `Application.modelState`. Ideal when `@Environment` and `@Query` aren't available, or when you need model operations outside of view code.

## Notes

- All reads and writes go through the container's `mainContext` — keep usages on the main actor.
- `ModelState` does not cache results in AppState's own cache. SwiftData's `ModelContext` is the source of truth.
- Register a single `ModelContainer` dependency and reference it from all model states and the SwiftUI environment.
