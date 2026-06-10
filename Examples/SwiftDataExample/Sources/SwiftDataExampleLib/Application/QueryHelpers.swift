import AppState
import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - Public query helper functions

/// Returns matching incomplete `TodoItem`s tagged with `tagName`, sorted by priority
/// descending then title ascending, capped at `fetchLimit`.
///
/// This free function builds and executes the compound query directly against the shared
/// lab `ModelContainer`'s `mainContext`, making it callable from tests and call-sites that
/// do not have direct access to the `Application` instance methods.
///
/// - Parameters:
///   - tagName: The tag name to filter by.
///   - fetchLimit: Maximum number of results. Defaults to `50`.
/// - Returns: Matching `TodoItem` models.
@MainActor
public func fetchIncompleteItems(tagName: String, fetchLimit: Int = 50) -> [TodoItem] {
    let context = Application.modelContext(\.labContainer)
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
    return (try? context.fetch(descriptor)) ?? []
}

/// Returns high-priority incomplete `TodoItem`s where `priority >= threshold`.
///
/// - Parameters:
///   - threshold: Minimum priority (inclusive). Defaults to `1`.
///   - fetchLimit: Maximum results. Defaults to `20`.
/// - Returns: Matching `TodoItem` models.
@MainActor
public func fetchHighPriorityIncompleteItems(threshold: Int = 1, fetchLimit: Int = 20) -> [TodoItem] {
    let context = Application.modelContext(\.labContainer)
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
    return (try? context.fetch(descriptor)) ?? []
}

#endif
