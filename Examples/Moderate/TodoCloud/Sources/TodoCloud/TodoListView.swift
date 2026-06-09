#if canImport(SwiftUI)
import AppState
import SwiftUI

// MARK: - TodoListView

/// The root view of the TodoCloud example application.
///
/// Demonstrates three AppState features in a single screen:
/// - `@SyncState` for the iCloud-backed todo list (headline feature)
/// - `@AppState` for transient new-todo input text
/// - `@AppDependency` (via `TodoViewModel`) for the injectable `TodoService`
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct TodoListView: View {

    // MARK: - State

    /// The iCloud-synced list of todo items — changes propagate across devices.
    @available(watchOS 11.0, *)
    @SyncState(\.todos) private var todos: [Todo]

    /// The current text in the "add todo" field, stored as transient in-memory state.
    @AppState(\.newTodoTitle) private var newTodoTitle: String

    /// Drives all mutations; resolved through AppState dependency injection.
    @State private var viewModel = TodoViewModel()

    // MARK: - Initializers

    /// Creates the `TodoListView`.
    public init() {}

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            List {
                addTodoSection
                todoItemsSection
            }
            .navigationTitle("TodoCloud")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
        }
    }

    // MARK: - Private Views

    private var addTodoSection: some View {
        Section {
            HStack {
                TextField("New todo…", text: $newTodoTitle)
                    .onSubmit { commitNewTodo() }
            }
        } header: {
            Text("Add Item")
        }
    }

    private var todoItemsSection: some View {
        Section {
            if todos.isEmpty {
                ContentUnavailableView(
                    "No Todos",
                    systemImage: "checkmark.circle",
                    description: Text("Add your first item above.")
                )
            } else {
                ForEach(todos) { todo in
                    TodoRowView(todo: todo) {
                        viewModel.toggleTodo(id: todo.id)
                    }
                }
                .onDelete { offsets in
                    viewModel.removeTodos(at: offsets)
                }
            }
        } header: {
            Text("Items (\(todos.count))")
        }
    }

    private var addButton: some View {
        Button(action: commitNewTodo) {
            Label("Add", systemImage: "plus")
        }
        .disabled(newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Private Methods

    private func commitNewTodo() {
        viewModel.addTodo(title: newTodoTitle)
    }
}

// MARK: - TodoRowView

/// A single row in the todo list, displaying the title and a completion toggle.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
private struct TodoRowView: View {

    // MARK: - Properties

    private let todo: Todo
    private let onToggle: () -> Void

    // MARK: - Initializers

    internal init(todo: Todo, onToggle: @escaping () -> Void) {
        self.todo = todo
        self.onToggle = onToggle
    }

    // MARK: - Body

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
                    .imageScale(.large)

                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.title)
                        .strikethrough(todo.isCompleted)
                        .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                    Text(todo.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
#Preview("TodoCloud — Empty") {
    Application.preview {
        TodoListView()
    }
}
#endif
