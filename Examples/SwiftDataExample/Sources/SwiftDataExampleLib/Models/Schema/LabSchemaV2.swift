import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - LabSchemaV2

/// Version 2 of the SwiftData Lab schema.
///
/// Adds two fields to `TodoItem` that were absent in V1:
/// - `priority` (`Int`, default `0`) — numeric priority for sort/filter.
/// - `dueDate` (`Date?`) — optional deadline for the item.
///
/// A `SchemaMigrationPlan` (`LabMigrationPlan`) provides both a lightweight migration stage
/// (V1 → V2, handled automatically by SwiftData for added-optional/default-value columns) and
/// demonstrates where a custom migration stage would be inserted.
public enum LabSchemaV2: VersionedSchema {
    // `Schema.Version` is not `Sendable` on older SDKs; this is an immutable constant, so opt out
    // of the global-actor isolation check explicitly.
    nonisolated(unsafe) public static let versionIdentifier = Schema.Version(2, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [TodoList.self, TodoItem.self, Tag.self]
    }

    // MARK: - TodoList

    /// An ordered collection of `TodoItem`s (unchanged from V1).
    @Model
    public final class TodoList {
        public var title: String
        public var createdAt: Date

        @Relationship(deleteRule: .cascade, inverse: \TodoItem.list)
        public var items: [TodoItem]

        public init(title: String, createdAt: Date = .now) {
            self.title = title
            self.createdAt = createdAt
            self.items = []
        }
    }

    // MARK: - TodoItem (V2)

    /// A single work item — now with `priority` and `dueDate` fields added in V2.
    @Model
    public final class TodoItem {
        public var title: String
        public var isDone: Bool
        public var createdAt: Date

        // MARK: V2 additions

        /// Numeric priority. Higher values indicate greater urgency. Defaults to `0`.
        public var priority: Int

        /// Optional deadline. `nil` means no due date is set.
        public var dueDate: Date?

        public var list: TodoList?

        @Relationship(deleteRule: .nullify, inverse: \Tag.items)
        public var tags: [Tag]

        public init(
            title: String,
            isDone: Bool = false,
            priority: Int = 0,
            dueDate: Date? = nil,
            createdAt: Date = .now
        ) {
            self.title = title
            self.isDone = isDone
            self.priority = priority
            self.dueDate = dueDate
            self.createdAt = createdAt
            self.tags = []
        }
    }

    // MARK: - Tag (unchanged from V1)

    @Model
    public final class Tag {
        @Attribute(.unique)
        public var name: String

        public var items: [TodoItem]

        public init(name: String) {
            self.name = name
            self.items = []
        }
    }
}

// MARK: - LabMigrationPlan

/// Describes how to migrate the SwiftData Lab schema from V1 to V2.
///
/// The V1→V2 stage is a **lightweight migration**: SwiftData can handle the addition of columns
/// that have a default value or are optional without any custom code. A custom stage is also
/// declared (commented-out body) to demonstrate where data-transformation logic would be placed.
public enum LabMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [LabSchemaV1.self, LabSchemaV2.self]
    }

    public static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    /// Lightweight migration from V1 → V2.
    ///
    /// SwiftData automatically adds `priority` (default `0`) and `dueDate` (optional `nil`)
    /// to existing rows, so no custom `willMigrate`/`didMigrate` closure is needed.
    // `MigrationStage` is not `Sendable` on older SDKs; this is an immutable constant.
    nonisolated(unsafe) private static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: LabSchemaV1.self,
        toVersion: LabSchemaV2.self
    )
}

#endif
