import AppState
import Foundation

// MARK: - Application + TodoCloud State

extension Application {

    /// The cloud-synced list of all todo items.
    ///
    /// Backed by `NSUbiquitousKeyValueStore` so changes propagate across every
    /// device signed into the same iCloud account.  Falls back to `UserDefaults`
    /// when iCloud is unavailable.
    ///
    /// - Note: Only available on Apple platforms (iCloud is not supported on Linux/Windows).
    #if !os(Linux) && !os(Windows)
    @available(watchOS 9.0, *)
    public var todos: SyncState<[Todo]> {
        syncState(initial: [], feature: "TodoCloud", id: "todos")
    }
    #endif

    /// The text currently entered in the new-todo input field.
    ///
    /// Kept as in-memory `State` because it is transient UI state that does not
    /// need to survive across launches or sync to iCloud.
    public var newTodoTitle: State<String> {
        state(initial: "", feature: "TodoCloud", id: "newTodoTitle")
    }
}

// MARK: - Application + TodoCloud Dependencies

extension Application {

    /// The injected service that generates IDs and timestamps for new todos.
    ///
    /// Override this dependency in tests with a `MockTodoService` to gain
    /// full control over identifiers and dates without affecting production code.
    public var todoService: Dependency<TodoService> {
        dependency(LiveTodoService() as TodoService, feature: "TodoCloud", id: "todoService")
    }
}
