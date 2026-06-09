import Foundation

// MARK: - TodoService

/// A service that provides infrastructure-level helpers for creating todos.
///
/// Abstracting `UUID` and `Date` generation behind a protocol keeps the
/// `TodoViewModel` fully testable without touching real system clocks or
/// random identifiers.
public protocol TodoService: Sendable {

    /// Generates a new stable identifier for a todo item.
    func makeID() -> UUID

    /// Returns the current point in time to stamp a todo's creation date.
    func makeDate() -> Date
}

// MARK: - LiveTodoService

/// The production implementation of `TodoService`.
///
/// Delegates to Foundation's `UUID()` and `Date()` so that real app builds
/// receive genuine, non-deterministic values.
public struct LiveTodoService: TodoService {

    // MARK: - Initializers

    public init() {}

    // MARK: - TodoService

    public func makeID() -> UUID {
        UUID()
    }

    public func makeDate() -> Date {
        Date()
    }
}
