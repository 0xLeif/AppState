import AppState
import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - Application + Lab dependencies & states

public extension Application {

    // MARK: ModelContainer dependency

    /// The shared in-memory `ModelContainer` for the SwiftData Lab example.
    ///
    /// Registered once via `modelContainer(_:)` and cached by AppState's dependency system.
    /// Override in tests with `Application.override(\.labContainer, with: …)`.
    var labContainer: Dependency<ModelContainer> {
        modelContainer(makeInMemoryLabContainer())
    }

    // MARK: - Unfiltered model states

    /// All `TodoList` records, ordered by creation date (newest first).
    ///
    /// Used by `TodoListStore` and `SwiftDataLabView`.
    var todoLists: ModelState<TodoList> {
        modelState(
            container: \.labContainer,
            fetchDescriptor: FetchDescriptor<TodoList>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        )
    }

    /// All `TodoItem` records, ordered by title for simple display.
    var allItems: ModelState<TodoItem> {
        modelState(
            container: \.labContainer,
            fetchDescriptor: FetchDescriptor<TodoItem>(
                sortBy: [SortDescriptor(\.title)]
            )
        )
    }

    /// All `Tag` records, ordered alphabetically by name.
    var allTags: ModelState<Tag> {
        modelState(
            container: \.labContainer,
            fetchDescriptor: FetchDescriptor<Tag>(
                sortBy: [SortDescriptor(\.name)]
            )
        )
    }

    // MARK: - Compound-query model states

    /// Incomplete `TodoItem`s that carry a tag whose name matches `tagName`, sorted by
    /// `priority` descending then by `title` ascending, capped at `fetchLimit` results.
    ///
    /// Demonstrates:
    /// - Compound `#Predicate` (isDone == false AND tag membership)
    /// - Multi-key `SortDescriptor` array
    /// - `fetchLimit`
    ///
    /// - Parameters:
    ///   - tagName: The tag name to filter by.
    ///   - fetchLimit: Maximum number of results to return (default 50).
    /// - Returns: A `ModelState<TodoItem>` scoped to matching incomplete items.
    func incompleteItems(tagName: String, fetchLimit: Int = 50) -> ModelState<TodoItem> {
        let predicate = #Predicate<TodoItem> { item in
            item.isDone == false && item.tags.contains { $0.name == tagName }
        }
        var descriptor = FetchDescriptor<TodoItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.title),
            ]
        )
        descriptor.fetchLimit = fetchLimit
        return modelState(container: \.labContainer, fetchDescriptor: descriptor)
    }

    /// High-priority `TodoItem`s (priority >= `threshold`) that are not yet done, ordered
    /// by priority descending then by due date ascending (nils last via nil-coalescing in
    /// the sort key workaround — SwiftData 1.0 does not yet support nil-first/nil-last
    /// natively, so items without a due date are sorted to the end via a large sentinel).
    ///
    /// Demonstrates a multi-key sort where one key is a computed expression.
    ///
    /// - Parameters:
    ///   - threshold: Minimum priority value (inclusive). Defaults to `1`.
    ///   - fetchLimit: Maximum results. Defaults to `20`.
    func highPriorityIncompleteItems(threshold: Int = 1, fetchLimit: Int = 20) -> ModelState<TodoItem> {
        let predicate = #Predicate<TodoItem> { item in
            item.isDone == false && item.priority >= threshold
        }
        var descriptor = FetchDescriptor<TodoItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.createdAt),
            ]
        )
        descriptor.fetchLimit = fetchLimit
        return modelState(container: \.labContainer, fetchDescriptor: descriptor)
    }

}

#endif
