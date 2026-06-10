import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - Current-schema type aliases

/// The canonical `TodoList` model used throughout the library.
///
/// Points to the V2 definition, which is the current (latest) schema version.
public typealias TodoList = LabSchemaV2.TodoList

/// The canonical `TodoItem` model used throughout the library.
///
/// Points to the V2 definition, which includes `priority` and `dueDate`.
public typealias TodoItem = LabSchemaV2.TodoItem

/// The canonical `Tag` model used throughout the library.
public typealias Tag = LabSchemaV2.Tag

#endif
