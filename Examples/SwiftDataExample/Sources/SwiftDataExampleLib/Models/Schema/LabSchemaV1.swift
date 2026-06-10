import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - LabSchemaV1

/// Version 1 of the SwiftData Lab schema.
///
/// Defines the original three-model shape:
/// - `TodoList` owns many `TodoItem`s (cascade delete).
/// - `TodoItem` cross-references many `Tag`s (nullify on either side).
/// - `Tag.name` is unique — duplicate inserts perform an upsert.
public enum LabSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [TodoList.self, TodoItem.self, Tag.self]
    }

    // MARK: - TodoList

    /// An ordered collection of `TodoItem`s.
    ///
    /// Deleting a `TodoList` cascades to all its child `TodoItem`s.
    @Model
    public final class TodoList {
        public var title: String
        public var createdAt: Date

        /// Child items. `deleteRule: .cascade` ensures children are removed when the list is deleted.
        @Relationship(deleteRule: .cascade, inverse: \TodoItem.list)
        public var items: [TodoItem]

        public init(title: String, createdAt: Date = .now) {
            self.title = title
            self.createdAt = createdAt
            self.items = []
        }
    }

    // MARK: - TodoItem

    /// A single work item that belongs to exactly one `TodoList` and may carry many `Tag`s.
    @Model
    public final class TodoItem {
        public var title: String
        public var isDone: Bool
        public var createdAt: Date

        /// The owning list. Optional because SwiftData resolves the inverse lazily.
        public var list: TodoList?

        /// Associated tags. `deleteRule: .nullify` means deleting an item clears these references
        /// on the `Tag` side but does not delete the `Tag` models themselves.
        @Relationship(deleteRule: .nullify, inverse: \Tag.items)
        public var tags: [Tag]

        public init(title: String, isDone: Bool = false, createdAt: Date = .now) {
            self.title = title
            self.isDone = isDone
            self.createdAt = createdAt
            self.tags = []
        }
    }

    // MARK: - Tag

    /// A label that can be applied to many `TodoItem`s.
    ///
    /// `@Attribute(.unique)` on `name` means that inserting a `Tag` with a name that already
    /// exists in the store performs an **upsert**: the existing record is returned/updated rather
    /// than a duplicate being created.
    @Model
    public final class Tag {
        @Attribute(.unique)
        public var name: String

        /// The items that carry this tag. This is the inverse side of `TodoItem.tags`.
        public var items: [TodoItem]

        public init(name: String) {
            self.name = name
            self.items = []
        }
    }
}

#endif
