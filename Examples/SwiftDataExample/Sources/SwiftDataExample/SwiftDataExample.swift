import AppState
import Foundation
import SwiftDataExampleLib

#if canImport(SwiftData)
import SwiftData

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
        Application.modelState(\.todos).deleteAll()
        precondition(Application.modelState(\.todos).models.isEmpty, "Expected an empty store at start")

        // 1. Insert via the property-wrapper projected value (view-model style).
        let store = TodoStore()
        store.add("Buy milk")
        print("After store.add: \(store.todos.count) todo(s)")
        precondition(store.todos.count == 1, "Expected 1 todo after store.add")

        // 2. Insert more through the view model (its projected-value `insert`).
        store.add("Walk the dog")
        store.add("Write code")
        print("After two more inserts: \(store.todos.count) todo(s)")
        precondition(store.todos.count == 3, "Expected 3 todos")

        // 3. Insert directly through the application-level `ModelState`.
        Application.modelState(\.todos).insert(TodoItem(title: "Read a book"))
        print("After Application.modelState insert: \(Application.modelState(\.todos).models.count) todo(s)")
        precondition(Application.modelState(\.todos).models.count == 4, "Expected 4 todos")

        // Fetch & print the current todos.
        let current = Application.modelState(\.todos).models
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
        let doneCount = Application.modelState(\.todos).models.filter(\.isDone).count
        precondition(doneCount == 1, "Expected exactly 1 completed todo")

        // 5. Delete one todo.
        if let toDelete = Application.modelState(\.todos).models.last {
            Application.modelState(\.todos).delete(toDelete)
            print("Deleted \"\(toDelete.title)\"")
        }
        let remaining = Application.modelState(\.todos).models
        print("Remaining todos:")
        for todo in remaining {
            print("  - [\(todo.isDone ? "x" : " ")] \(todo.title)")
        }
        precondition(remaining.count == 3, "Expected 3 todos after deletion")

        // 6. deleteAll() removes every model managed by the state.
        Application.modelState(\.todos).deleteAll()
        precondition(Application.modelState(\.todos).models.isEmpty, "Expected an empty store after deleteAll")
        print("Store cleared; \(Application.modelState(\.todos).models.count) todo(s) remaining")

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
