import AppState
import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - Model

/// A simple SwiftData model persisted through an AppState-provided `ModelContainer`.
///
/// The package's deployment target is macOS 14 / iOS 17, so SwiftData is unconditionally available.
@Model
public final class TodoItem {
    public var title: String
    public var isDone: Bool

    public init(title: String, isDone: Bool = false) {
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
    public var modelContainer: Dependency<ModelContainer> {
        modelContainer(makeInMemoryTodoContainer())
    }

    /// The shared collection of `TodoItem`s, backed by the `modelContainer` dependency.
    public var todos: ModelState<TodoItem> {
        modelState(container: \.modelContainer)
    }
}

// MARK: - Container factory

/// Builds the example's in-memory `ModelContainer`.
///
/// `ModelContainer(for:)` is a throwing initializer, but AppState's `Dependency` stores a plain
/// value, so the throw is resolved here. A failure to build an in-memory container for this static
/// schema is an unrecoverable configuration error, so it traps with a descriptive message rather
/// than using `try!`.
///
/// - Note: The `catch` is a defensive trap that cannot be exercised by tests — an in-memory
///   `ModelContainer` for `TodoItem` does not fail on supported platforms, and executing the trap
///   would terminate the test runner. It is the single deliberately-uncovered region in this
///   example.
internal func makeInMemoryTodoContainer() -> ModelContainer {
    do {
        return try ModelContainer(
            for: TodoItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Failed to create the in-memory ModelContainer: \(error)")
    }
}

// MARK: - View model / service usage

/// Demonstrates the `@ModelState` property wrapper from a view-model-style `ObservableObject`.
///
/// `@ModelState` is intended for view models, services, and other non-view code that needs
/// shared, dependency-injected access to your models. For reactive SwiftUI views, prefer
/// SwiftData's own `@Query` while sharing this same `ModelContainer` (see the README).
@MainActor
public final class TodoStore: ObservableObject {
    @ModelState(\.todos) public var todos: [TodoItem]

    public init() {}

    /// Adds a todo via the projected value's explicit `insert(_:)`.
    public func add(_ title: String) {
        $todos.insert(TodoItem(title: title))
    }

    /// Persists any pending changes via the projected value's `save()`.
    public func save() {
        $todos.save()
    }
}

#endif
