import AppState
import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - TodoListStore

/// View-model for the top-level list of `TodoList` records.
///
/// Demonstrates using `@ModelState` from an `ObservableObject` to manage `TodoList` entities
/// through AppState's dependency-injected `ModelContainer`.
@MainActor
public final class TodoListStore: ObservableObject {

    // MARK: Properties

    /// All `TodoList` records, ordered by creation date (newest first).
    @ModelState(\.todoLists) public var lists: [TodoList]

    public init() {}

    // MARK: Public Interface

    /// Creates and inserts a new `TodoList` with the given title.
    ///
    /// - Parameter title: The display name for the new list.
    public func createList(titled title: String) {
        $lists.insert(TodoList(title: title))
    }

    /// Deletes the specified `TodoList` (cascades to its `TodoItem` children).
    ///
    /// - Parameter list: The list to remove.
    public func delete(_ list: TodoList) {
        $lists.delete(list)
    }

    /// Saves any pending context changes.
    public func save() {
        $lists.save()
    }
}

#endif
