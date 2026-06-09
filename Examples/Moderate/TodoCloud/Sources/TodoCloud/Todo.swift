import Foundation

// MARK: - Todo

/// A single cloud-synced todo item.
///
/// `Todo` is a value type designed to be safe across concurrency boundaries and
/// fully round-trippable through the iCloud key-value store via JSON encoding.
public struct Todo: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// The stable, unique identifier for this todo item.
    public let id: UUID

    /// The user-facing title of the todo item.
    public var title: String

    /// Whether the user has marked this item as complete.
    public var isCompleted: Bool

    /// The moment at which this todo was originally created.
    public let createdAt: Date

    // MARK: - Initializers

    /// Creates a new todo item.
    ///
    /// - Parameters:
    ///   - id: A stable unique identifier. Defaults to a new `UUID`.
    ///   - title: The display title.
    ///   - isCompleted: Initial completion state. Defaults to `false`.
    ///   - createdAt: Creation timestamp. Defaults to `Date()`.
    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    // MARK: - Public Methods

    /// Returns a copy of this todo with its completion state toggled.
    public func toggled() -> Todo {
        Todo(
            id: id,
            title: title,
            isCompleted: !isCompleted,
            createdAt: createdAt
        )
    }
}
