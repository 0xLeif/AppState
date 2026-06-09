import Foundation

// MARK: - Note

/// A single user note that can be synced across devices via iCloud.
///
/// `Note` is a value type designed to round-trip safely through the
/// iCloud key-value store via JSON encoding. Its `Sendable` conformance
/// makes it safe to pass across concurrency boundaries.
public struct Note: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// The stable, unique identifier for this note.
    public let id: UUID

    /// The user-visible body text of the note.
    public var text: String

    /// The moment at which this note was originally created.
    public let createdAt: Date

    // MARK: - Initializers

    /// Creates a new note.
    ///
    /// - Parameters:
    ///   - id: A stable unique identifier. Defaults to a new `UUID`.
    ///   - text: The body text of the note.
    ///   - createdAt: Creation timestamp. Defaults to `Date()`.
    public init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}
