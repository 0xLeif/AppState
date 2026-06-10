import AppState
import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - TodoItemStore

/// View-model for the items within a single `TodoList`.
///
/// Demonstrates:
/// - Inserting items into a relationship (`list.items.append`).
/// - Attaching / creating `Tag`s on an item (exercising the many-to-many relationship).
/// - Toggling completion and adjusting priority.
/// - Running a compound-predicate filtered query via `Application.incompleteItems(tagName:)`.
@MainActor
public final class TodoItemStore: ObservableObject {

    // MARK: Properties

    /// The list whose items this store manages.
    public private(set) var list: TodoList

    /// All items (unfiltered), sourced from `Application.allItems`.
    @ModelState(\.allItems) public var allItems: [TodoItem]

    public init(list: TodoList) {
        self.list = list
    }

    // MARK: Public Interface

    /// Items that belong to this store's list, as an in-memory filter over `allItems`.
    ///
    /// - Note: SwiftData's relationship array (`list.items`) is the authoritative source;
    ///   this computed property is used for display so the list automatically reflects
    ///   relationship mutations without a separate `ModelState` per list.
    public var items: [TodoItem] {
        list.items.sorted { $0.title < $1.title }
    }

    /// Creates a new `TodoItem`, links it to this store's list, and inserts it into the context.
    ///
    /// - Parameters:
    ///   - title: The item's display title.
    ///   - priority: Numeric priority (default `0`).
    ///   - dueDate: Optional deadline (default `nil`).
    public func addItem(titled title: String, priority: Int = 0, dueDate: Date? = nil) {
        let item = TodoItem(title: title, priority: priority, dueDate: dueDate)
        list.items.append(item)
        $allItems.insert(item)
    }

    /// Removes an item from the context (also removes it from the list relationship automatically).
    ///
    /// - Parameter item: The item to delete.
    public func delete(_ item: TodoItem) {
        $allItems.delete(item)
    }

    /// Flips `item.isDone` and saves.
    ///
    /// - Parameter item: The item whose completion state should be toggled.
    public func toggleDone(_ item: TodoItem) {
        item.isDone.toggle()
        $allItems.save()
    }

    /// Assigns or creates a `Tag` with the given name and attaches it to `item`.
    ///
    /// If a `Tag` with that name already exists (unique constraint), the existing tag is
    /// reused. Otherwise a new one is inserted, which exercises the upsert-on-unique path.
    ///
    /// - Parameters:
    ///   - tagName: The tag name to attach.
    ///   - item: The item that should carry the tag.
    public func attachTag(named tagName: String, to item: TodoItem) {
        let context = $allItems.context
        let existingTag = resolveTag(named: tagName, in: context)
        guard !item.tags.contains(where: { $0.name == tagName }) else { return }
        item.tags.append(existingTag)
        $allItems.save()
    }

    /// Removes a tag from an item without deleting the tag itself (nullify behaviour).
    ///
    /// - Parameters:
    ///   - tag: The tag to detach.
    ///   - item: The item to detach from.
    public func detachTag(_ tag: Tag, from item: TodoItem) {
        item.tags.removeAll { $0.name == tag.name }
        $allItems.save()
    }

    /// Returns incomplete items tagged with `tagName`, ordered by priority then title.
    ///
    /// - Parameter tagName: The tag name to filter by.
    /// - Returns: Matching `TodoItem` models.
    public func incompleteItems(taggedWith tagName: String) -> [TodoItem] {
        Application.modelState(\.allItems)
            .models
            .filter { !$0.isDone && $0.tags.contains { $0.name == tagName } }
            .sorted {
                if $0.priority != $1.priority { return $0.priority > $1.priority }
                return $0.title < $1.title
            }
    }

    // MARK: Private Helpers

    /// Fetches an existing `Tag` by name, or creates and inserts a new one.
    ///
    /// This is the point at which SwiftData's unique-attribute upsert behaviour is exercised:
    /// if a tag with this name already lives in the store, the context returns/reuses it.
    private func resolveTag(named name: String, in context: ModelContext) -> Tag {
        let predicate = #Predicate<Tag> { $0.name == name }
        let descriptor = FetchDescriptor<Tag>(predicate: predicate)

        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let newTag = Tag(name: name)
        context.insert(newTag)
        return newTag
    }
}

#endif
