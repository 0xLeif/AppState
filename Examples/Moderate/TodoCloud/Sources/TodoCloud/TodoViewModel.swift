import AppState
import Foundation

// MARK: - TodoViewModel

/// A headless view model that drives the todo list feature.
///
/// All mutations go through `Application` state so the logic is fully exercisable
/// in unit tests without rendering any SwiftUI views.  The dependency on
/// `TodoService` is resolved through `@AppDependency` injection, which lets
/// tests substitute a deterministic mock via `Application.override(_:with:)`.
@MainActor
public final class TodoViewModel {

    // MARK: - Private State

    @AppDependency(\.todoService) private var service: TodoService

    // MARK: - Initializers

    /// Creates a new `TodoViewModel`.
    public init() {}

    // MARK: - Public Methods

    /// The current list of todo items, read directly from `Application` state.
    ///
    /// On Apple platforms this list is backed by iCloud; on other platforms
    /// it falls back to an in-memory `State<[Todo]>`.
    public var todos: [Todo] {
        #if !os(Linux) && !os(Windows)
        return Application.syncState(\.todos).value
        #else
        return Application.state(\.fallbackTodos).value
        #endif
    }

    /// Appends a new todo using `title`, then clears the input field.
    ///
    /// Does nothing when `title` (trimmed of whitespace) is empty.
    ///
    /// - Parameter title: The display text for the new item.
    public func addTodo(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let todo = Todo(
            id: service.makeID(),
            title: trimmed,
            isCompleted: false,
            createdAt: service.makeDate()
        )

        mutateTodos { todos in
            todos.append(todo)
        }

        var titleState = Application.state(\.newTodoTitle)
        titleState.value = ""
    }

    /// Toggles the completion state of the todo identified by `id`.
    ///
    /// - Parameter id: The `UUID` of the todo item to toggle.
    public func toggleTodo(id: UUID) {
        mutateTodos { todos in
            todos = todos.map { todo in
                todo.id == id ? todo.toggled() : todo
            }
        }
    }

    /// Removes the todo items at the specified index set.
    ///
    /// Designed to be called directly from a `List` `onDelete` handler.
    ///
    /// - Parameter offsets: The index set of items to remove.
    public func removeTodos(at offsets: IndexSet) {
        mutateTodos { todos in
            todos.remove(atOffsets: offsets)
        }
    }

    /// Removes a todo by its identifier.
    ///
    /// - Parameter id: The `UUID` of the todo to remove.
    public func removeTodo(id: UUID) {
        mutateTodos { todos in
            todos.removeAll { $0.id == id }
        }
    }

    // MARK: - Private Methods

    /// Applies a mutation closure to the canonical todos list, regardless of
    /// whether the backing store is `SyncState` (Apple) or plain `State` (other).
    private func mutateTodos(_ transform: (inout [Todo]) -> Void) {
        #if !os(Linux) && !os(Windows)
        var syncState = Application.syncState(\.todos)
        var current = syncState.value
        transform(&current)
        syncState.value = current
        #else
        var appState = Application.state(\.fallbackTodos)
        var current = appState.value
        transform(&current)
        appState.value = current
        #endif
    }
}

// MARK: - Application + Fallback State (Linux / watchOS <9)

extension Application {
    /// Fallback in-memory todo state for non-Apple or older watchOS targets.
    internal var fallbackTodos: State<[Todo]> {
        state(initial: [], feature: "TodoCloud", id: "fallbackTodos")
    }
}
