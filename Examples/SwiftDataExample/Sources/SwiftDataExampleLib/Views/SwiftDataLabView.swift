import AppState
import Foundation

#if canImport(SwiftData) && canImport(SwiftUI)
import SwiftData
import SwiftUI

// MARK: - SwiftDataLabView

/// The public root view for the SwiftData Lab example.
///
/// Host apps present this view directly after injecting the `labContainer` dependency (or
/// accepting the default in-memory container). It demonstrates:
/// - `TodoList` creation and cascade-delete.
/// - Item insertion with priority and due-date.
/// - Tag attachment and many-to-many display.
/// - Filtered compound-query results.
///
/// ```swift
/// // In a host SwiftUI app:
/// SwiftDataLabView()
/// ```
public struct SwiftDataLabView: View {

    // MARK: Properties

    @StateObject private var listStore = TodoListStore()
    @State private var newListTitle: String = ""
    @State private var selectedList: TodoList?
    @State private var filterTagName: String = ""

    // MARK: Initialiser

    public init() {}

    // MARK: Body

    public var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .navigationTitle("SwiftData Lab")
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        List(selection: $selectedList) {
            newListInputRow
            ForEach(listStore.lists, id: \.persistentModelID) { list in
                NavigationLink(value: list) {
                    TodoListRowView(list: list)
                }
            }
            .onDelete { offsets in
                offsets.map { listStore.lists[$0] }.forEach { listStore.delete($0) }
            }
        }
        .navigationTitle("Lists")
    }

    private var newListInputRow: some View {
        HStack {
            TextField("New list…", text: $newListTitle)
                .onSubmit { commitNewList() }
            Button(action: commitNewList) {
                Image(systemName: "plus.circle.fill")
            }
            .disabled(newListTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if let list = selectedList {
            TodoItemListView(list: list, filterTagName: $filterTagName)
        } else {
            ContentUnavailableView(
                "Select a List",
                systemImage: "checklist",
                description: Text("Choose a list from the sidebar or create a new one.")
            )
        }
    }

    // MARK: - Actions

    private func commitNewList() {
        let trimmed = newListTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        listStore.createList(titled: trimmed)
        newListTitle = ""
    }
}

// MARK: - TodoListRowView

/// A compact row displaying a `TodoList`'s title and item count.
public struct TodoListRowView: View {

    // MARK: Properties

    public let list: TodoList

    // MARK: Initialiser

    public init(list: TodoList) {
        self.list = list
    }

    // MARK: Body

    public var body: some View {
        HStack {
            Text(list.title)
            Spacer()
            Text("\(list.items.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - TodoItemListView

/// Detail view showing items in a `TodoList` with add/delete/tag/filter controls.
public struct TodoItemListView: View {

    // MARK: Properties

    @StateObject private var store: TodoItemStore
    @Binding public var filterTagName: String
    @State private var newItemTitle: String = ""
    @State private var newItemPriority: Int = 0
    @State private var newTagInput: String = ""
    @State private var selectedItemForTagging: TodoItem?

    // MARK: Initialiser

    public init(list: TodoList, filterTagName: Binding<String>) {
        _store = StateObject(wrappedValue: TodoItemStore(list: list))
        _filterTagName = filterTagName
    }

    // MARK: Body

    public var body: some View {
        List {
            addItemSection
            filterSection
            itemsSection
        }
        .navigationTitle(store.list.title)
        .sheet(item: $selectedItemForTagging) { item in
            TagEditorView(item: item, store: store)
        }
    }

    // MARK: - Sections

    private var addItemSection: some View {
        Section("Add Item") {
            HStack {
                TextField("Title…", text: $newItemTitle)
                    .onSubmit { commitNewItem() }
                Stepper("P\(newItemPriority)", value: $newItemPriority, in: 0...5)
                    .fixedSize()
                Button("Add", action: commitNewItem)
                    .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var filterSection: some View {
        Section("Filter by Tag") {
            HStack {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
                TextField("Tag name…", text: $filterTagName)
                if !filterTagName.isEmpty {
                    Button(action: { filterTagName = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            if !filterTagName.isEmpty {
                let filtered = store.incompleteItems(taggedWith: filterTagName)
                if filtered.isEmpty {
                    Text("No incomplete items tagged \"\(filterTagName)\"")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(filtered, id: \.persistentModelID) { item in
                        TodoItemRowView(item: item) {
                            store.toggleDone(item)
                        }
                    }
                }
            }
        }
    }

    private var itemsSection: some View {
        Section("Items (\(store.items.count))") {
            ForEach(store.items, id: \.persistentModelID) { item in
                TodoItemRowView(item: item) {
                    store.toggleDone(item)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        selectedItemForTagging = item
                    } label: {
                        Label("Tag", systemImage: "tag")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        store.delete(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func commitNewItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addItem(titled: trimmed, priority: newItemPriority)
        newItemTitle = ""
        newItemPriority = 0
    }
}

// MARK: - TodoItemRowView

/// A single row displaying a `TodoItem`'s completion, title, priority, and tags.
public struct TodoItemRowView: View {

    // MARK: Properties

    public let item: TodoItem
    public let onToggle: () -> Void

    // MARK: Initialiser

    public init(item: TodoItem, onToggle: @escaping () -> Void) {
        self.item = item
        self.onToggle = onToggle
    }

    // MARK: Body

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .strikethrough(item.isDone)
                        .foregroundStyle(item.isDone ? .secondary : .primary)
                    Spacer()
                    if item.priority > 0 {
                        priorityBadge
                    }
                }
                if !item.tags.isEmpty {
                    tagChips
                }
                if let due = item.dueDate {
                    Text(due, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Sub-views

    private var priorityBadge: some View {
        Text("P\(item.priority)")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.15))
            .foregroundStyle(priorityColor)
            .clipShape(Capsule())
    }

    private var tagChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(item.tags.sorted { $0.name < $1.name }, id: \.persistentModelID) { tag in
                    Text(tag.name)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var priorityColor: Color {
        switch item.priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        case 2: return .blue
        default: return .gray
        }
    }
}

// MARK: - TagEditorView

/// A sheet for attaching and detaching tags on a `TodoItem`.
public struct TagEditorView: View {

    // MARK: Properties

    public let item: TodoItem
    public let store: TodoItemStore

    @State private var newTagName: String = ""
    @Environment(\.dismiss) private var dismiss

    // MARK: Initialiser

    public init(item: TodoItem, store: TodoItemStore) {
        self.item = item
        self.store = store
    }

    // MARK: Body

    public var body: some View {
        NavigationStack {
            List {
                Section("Current Tags") {
                    if item.tags.isEmpty {
                        Text("No tags yet")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(item.tags.sorted { $0.name < $1.name }, id: \.persistentModelID) { tag in
                            HStack {
                                Text(tag.name)
                                Spacer()
                                Button(role: .destructive) {
                                    store.detachTag(tag, from: item)
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Add Tag") {
                    HStack {
                        TextField("Tag name…", text: $newTagName)
                            .onSubmit { commitTag() }
                        Button("Attach", action: commitTag)
                            .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Tags for \"\(item.title)\"")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Actions

    private func commitTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.attachTag(named: trimmed, to: item)
        newTagName = ""
    }
}

#endif
