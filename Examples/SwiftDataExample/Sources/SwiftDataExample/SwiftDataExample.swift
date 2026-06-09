import AppState
import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - Model

/// A simple SwiftData model persisted through an AppState-provided `ModelContainer`.
///
/// The package's deployment target is macOS 14 / iOS 17 (see `Package.swift`), so no `@available`
/// annotations are needed here — SwiftData is unconditionally available.
@Model
final class TodoItem {
    var title: String
    var isDone: Bool

    init(title: String, isDone: Bool = false) {
        self.title = title
        self.isDone = isDone
    }
}

// MARK: - AppState wiring

extension Application {
    /// An in-memory `ModelContainer` registered as an AppState dependency.
    ///
    /// Using `isStoredInMemoryOnly: true` keeps the example deterministic and side-effect free,
    /// so `swift run` can double as a smoke test in CI.
    var modelContainer: Dependency<ModelContainer> {
        modelContainer(
            try! ModelContainer(
                for: TodoItem.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    /// The shared collection of `TodoItem`s, backed by the `modelContainer` dependency.
    var todos: ModelState<TodoItem> {
        modelState(container: \.modelContainer)
    }
}

// MARK: - View model / service usage

/// Demonstrates the `@ModelState` property wrapper from a view-model-style `ObservableObject`.
///
/// `@ModelState` is intended for view models, services, and other non-view code that needs
/// shared, dependency-injected access to your models. For reactive SwiftUI views, prefer
/// SwiftData's own `@Query` while sharing this same `ModelContainer` (see the README).
@MainActor
final class TodoStore: ObservableObject {
    @ModelState(\.todos) var todos: [TodoItem]

    /// Adds a todo via the projected value's explicit `insert(_:)`.
    func add(_ title: String) {
        $todos.insert(TodoItem(title: title))
    }

    /// Persists any pending changes via the projected value's `save()`.
    func save() {
        $todos.save()
    }
}

// MARK: - Entry point

@main
struct SwiftDataExample {
    // `main()` is `@MainActor` because the backing `ModelContainer.mainContext` (and therefore
    // every `ModelState` operation) is main-actor bound.
    @MainActor
    static func main() {
        // Surface AppState's internal logging so the run is easy to follow.
        Application.logging(isEnabled: true)

        print("== SwiftData + AppState example ==")

        // Start from a clean slate so repeated runs are deterministic.
        Application.reset(modelState: \.todos)
        precondition(Application.modelState(\.todos).value.isEmpty, "Expected an empty store at start")

        // 1. Insert via the property-wrapper projected value (view-model style).
        let store = TodoStore()
        store.add("Buy milk")
        print("After store.add: \(store.todos.count) todo(s)")
        precondition(store.todos.count == 1, "Expected 1 todo after store.add")

        // 2. Insert by assigning the wrapped value directly. Assignment inserts any
        //    not-yet-persisted models; it does NOT delete absent ones.
        store.todos = [TodoItem(title: "Walk the dog"), TodoItem(title: "Write code")]
        print("After assigning two more: \(store.todos.count) todo(s)")
        precondition(store.todos.count == 3, "Expected 3 todos after assignment")

        // 3. Insert directly through the application-level `ModelState`.
        Application.modelState(\.todos).insert(TodoItem(title: "Read a book"))
        print("After Application.modelState insert: \(Application.modelState(\.todos).value.count) todo(s)")
        precondition(Application.modelState(\.todos).value.count == 4, "Expected 4 todos")

        // Fetch & print the current todos.
        let current = Application.modelState(\.todos).value
        print("Current todos:")
        for todo in current {
            print("  - [\(todo.isDone ? "x" : " ")] \(todo.title)")
        }

        // 4. Mark one todo done and persist the change.
        if let first = current.first {
            first.isDone = true
            Application.modelState(\.todos).save()
            print("Marked \"\(first.title)\" as done and saved")
        }
        let doneCount = Application.modelState(\.todos).value.filter(\.isDone).count
        precondition(doneCount == 1, "Expected exactly 1 completed todo")

        // 5. Delete one todo.
        if let toDelete = Application.modelState(\.todos).value.last {
            Application.modelState(\.todos).delete(toDelete)
            print("Deleted \"\(toDelete.title)\"")
        }
        let remaining = Application.modelState(\.todos).value
        print("Remaining todos:")
        for todo in remaining {
            print("  - [\(todo.isDone ? "x" : " ")] \(todo.title)")
        }
        precondition(remaining.count == 3, "Expected 3 todos after deletion")

        // 6. Reset clears every model managed by the state.
        Application.reset(modelState: \.todos)
        precondition(Application.modelState(\.todos).value.isEmpty, "Expected an empty store after reset")
        print("Store reset; \(Application.modelState(\.todos).value.count) todo(s) remaining")

        print("== Example completed successfully ==")
        exit(0)
    }
}

#else

@main
struct SwiftDataExample {
    static func main() {
        print("SwiftData unavailable on this platform; nothing to demonstrate.")
    }
}

#endif
