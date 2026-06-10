import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - Container Factories

/// Builds an in-memory `ModelContainer` using the current (V2) schema, with no migration plan.
///
/// This is the standard container for the lab's live functionality. The `catch`/`fatalError`
/// path is a **defensive, structurally-uncoverable branch** — an in-memory container for this
/// static schema cannot fail on supported platforms, and executing the trap would terminate the
/// process. It is the single deliberately-uncovered region in this module.
///
/// - Returns: A freshly created in-memory `ModelContainer` for V2 models.
public func makeInMemoryLabContainer() -> ModelContainer {
    do {
        return try ModelContainer(
            for: TodoList.self, TodoItem.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Failed to create the in-memory lab ModelContainer: \(error)")
    }
}

/// Builds an in-memory `ModelContainer` using the **V1 schema**.
///
/// This factory is exposed for tests that need to verify the migration plan by starting from
/// a V1 store, inserting V1 records, and then migrating to V2.
///
/// - Returns: A freshly created in-memory `ModelContainer` for V1 models.
public func makeInMemoryV1Container() -> ModelContainer {
    do {
        return try ModelContainer(
            for: LabSchemaV1.TodoList.self,
                LabSchemaV1.TodoItem.self,
                LabSchemaV1.Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Failed to create the in-memory V1 ModelContainer: \(error)")
    }
}

/// Builds an in-memory `ModelContainer` driven by `LabMigrationPlan` (V1 → V2).
///
/// SwiftData applies lightweight migration automatically when the container is opened.
/// Because the migration is lightweight (additive columns with defaults), no on-disk store
/// is required — in-memory mode is sufficient for exercising the migration path.
///
/// - Returns: A freshly created in-memory `ModelContainer` backed by `LabMigrationPlan`.
public func makeInMemoryMigratedContainer() -> ModelContainer {
    do {
        return try ModelContainer(
            for: TodoList.self, TodoItem.self, Tag.self,
            migrationPlan: LabMigrationPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Failed to create the in-memory migrated ModelContainer: \(error)")
    }
}

#endif
