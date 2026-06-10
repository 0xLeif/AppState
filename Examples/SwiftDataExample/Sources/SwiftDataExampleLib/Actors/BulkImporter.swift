import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - BulkImporter

/// A `@ModelActor` that runs heavy SwiftData insert/save loops **entirely off the main actor**.
///
/// `BulkImporter` owns its own background `ModelContext` (provided by the `@ModelActor` macro).
/// It never touches the main-actor `mainContext`, so the UI stays fully responsive — it can scroll,
/// animate, and cancel while thousands of inserts are in flight.
///
/// ### Design notes
/// - Batching (default 500 items per save) keeps memory pressure low for large counts.
/// - `Task.yield()` between batches lets the Swift concurrency scheduler service other work.
/// - `Task.isCancelled` is checked before every batch — callers can cancel via the `Task` handle.
/// - Progress is delivered through a `@Sendable` callback, which the caller can forward to `@MainActor`.
///
/// ### Usage
/// ```swift
/// let importer = BulkImporter(modelContainer: Application.dependency(\.labContainer))
/// try await importer.importItems(count: 10_000) { inserted in
///     await MainActor.run { progressCount = inserted }
/// }
/// ```
@ModelActor
public actor BulkImporter {

    // MARK: - Public API

    /// Generates and inserts `count` synthetic `TodoItem`s into an ephemeral `TodoList` in the
    /// background context, saving every `batchSize` inserts.
    ///
    /// The `onProgress` callback is invoked after each batch with the **running total** of
    /// inserted items. It is called from within the `@ModelActor` executor — marshal to
    /// `@MainActor` if you need to update UI state:
    ///
    /// ```swift
    /// try await importer.importItems(count: 10_000) { inserted in
    ///     await MainActor.run { self.progressCount = inserted }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - count: Total number of `TodoItem`s to insert. Must be > 0.
    ///   - batchSize: Number of items to insert per save round-trip. Defaults to `500`.
    ///   - listTitle: Title for the containing `TodoList`. Defaults to a timestamped name.
    ///   - onProgress: Optional `@Sendable` async closure called after each batch with the
    ///                 running inserted count. May be `nil` if progress tracking is not needed.
    public func importItems(
        count: Int,
        batchSize: Int = 500,
        listTitle: String = "Bulk Import",
        onProgress: (@Sendable (Int) async -> Void)? = nil
    ) async {
        guard count > 0 else { return }

        let effectiveBatchSize = max(1, batchSize)

        // Create the parent list entirely in the background context — never mainContext.
        let list = TodoList(title: listTitle)
        modelContext.insert(list)

        var inserted = 0

        while inserted < count {
            guard !Task.isCancelled else {
                saveContext()
                return
            }

            let batchEnd = min(inserted + effectiveBatchSize, count)

            for index in inserted ..< batchEnd {
                let item = TodoItem(
                    title: "Bulk Item \(index + 1)",
                    priority: index % 6
                )
                list.items.append(item)
                modelContext.insert(item)
            }

            saveContext()
            inserted = batchEnd

            await onProgress?(inserted)

            // Yield to the Swift concurrency scheduler so other tasks get CPU time.
            await Task.yield()
        }
    }

    // MARK: - Private Implementation

    /// Saves the background `ModelContext`, logging any failure without propagating it.
    ///
    /// SwiftData raises `NSException` (not a Swift error) for structural failures — those paths
    /// are structurally uncoverable and intentionally left to crash, matching the pattern
    /// used throughout this module's container factories.
    private func saveContext() {
        guard modelContext.hasChanges else { return }
        do {
            try modelContext.save()
        } catch {
            print("BulkImporter: background save failed — \(error)")
        }
    }
}

#endif
