# SwiftData + AppState Example

A small, self-contained SwiftPM executable that demonstrates AppState's SwiftData
integration. It shows how to register a SwiftData `ModelContainer` as an AppState
`Dependency`, expose a collection of `@Model` objects as an `Application.ModelState`,
and read/write that collection from both application-level call sites and the
`@ModelState` property wrapper.

## What it shows

- Registering an in-memory `ModelContainer` as an AppState dependency:
  `Application.modelContainer`.
- Exposing a `ModelState<TodoItem>` collection: `Application.todos`.
- Inserting models three different ways:
  - the `@ModelState` projected value: `$todos.insert(...)`
  - assigning the wrapped value: `todos = [...]`
  - the application-level state: `Application.modelState(\.todos).insert(...)`
- Fetching (`Application.modelState(\.todos).value`), updating + `save()`,
  `delete(_:)`, and clearing everything with `Application.reset(modelState: \.todos)`.
- Using `@ModelState` from a view-model-style `ObservableObject` (`TodoStore`).

Every step asserts the expected count with `precondition(...)`, so `swift run`
doubles as a smoke test. The example uses an in-memory store, so it is deterministic
and leaves nothing behind.

## Requirements

- macOS 14+ (SwiftData)
- Xcode 16+ / a Swift 6 toolchain

SwiftData only builds on Apple platforms, which is why this lives in a nested package
rather than the root `AppState` package.

## Running

```sh
cd Examples/SwiftDataExample
swift run
```

You should see the todos being inserted, updated, deleted, and finally reset, ending
with `== Example completed successfully ==` and a `0` exit code.

## Recommended reactive pattern for SwiftUI

`@ModelState` is intended for view models, services, and other non-view code that
needs shared, dependency-injected access to your models. Its mutations are **not**
automatically broadcast to SwiftUI. For reactive views, use SwiftData's own `@Query`
while sharing the AppState-provided `ModelContainer`:

```swift
import AppState
import SwiftData
import SwiftUI

@main
struct TodoApp: App {
    var body: some Scene {
        WindowGroup {
            TodoListView()
        }
        // Share the same container AppState manages, so @Query and @ModelState
        // read and write through one source of truth.
        .modelContainer(Application.dependency(\.modelContainer))
    }
}

struct TodoListView: View {
    // @Query drives the reactive view.
    @Query private var todos: [TodoItem]

    // A view model using @ModelState for shared, non-view logic.
    @StateObject private var store = TodoStore()

    var body: some View {
        List(todos) { todo in
            Text(todo.title)
        }
        .toolbar {
            Button("Add") { store.add("New todo") }
        }
    }
}
```

In short: use `@Query` for reactive views, and `@ModelState` (or
`Application.modelState(_:)`) for view models and services.
