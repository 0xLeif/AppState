#if canImport(SwiftData)
import Foundation
import SwiftData

extension Application {
    /// `ModelState` exposes the SwiftData `@Model` objects matching a `FetchDescriptor` through the
    /// application's scope. It is backed by a `ModelContainer` dependency and reads/writes through
    /// that container's main-actor `ModelContext`.
    ///
    /// Unlike the other AppState state types, `ModelState` is **not** value-backed and does not store
    /// anything in AppState's cache — SwiftData's `ModelContext` is the single source of truth.
    /// Reading ``models`` performs a live fetch; mutate the store with ``insert(_:)``,
    /// ``delete(_:)``, ``save()``, and ``deleteAll()``.
    ///
    /// - Note: Mutations are not automatically broadcast to SwiftUI. For reactive views use
    ///   SwiftData's own `@Query` together with the AppState-provided `ModelContainer`; reach for
    ///   `ModelState` (and the `@ModelState` property wrapper) from view models, services, and other
    ///   non-view code that needs shared, dependency-injected access to your models.
    public struct ModelState<Model: PersistentModel> {
        public static var emoji: Character { "🗃️" }

        /// The `KeyPath` to the `ModelContainer` dependency that backs this state.
        let containerKeyPath: KeyPath<Application, Dependency<ModelContainer>>

        /// A closure producing the `FetchDescriptor` used when reading ``models``.
        private let fetchDescriptor: () -> FetchDescriptor<Model>

        /// The scope in which this state exists.
        let scope: Scope

        /// The `ModelContext` derived from the backing `ModelContainer` dependency.
        @MainActor
        public var context: ModelContext {
            Application.dependency(containerKeyPath).mainContext
        }

        /// The models currently matching this state's `FetchDescriptor`.
        ///
        /// - Important: Reading this property performs a SwiftData **fetch on every access**. Do not
        ///   read it repeatedly in a hot path or directly inside a SwiftUI `body`; capture it once, or
        ///   use SwiftData's `@Query` for reactive views. On failure an empty array is returned and
        ///   the error is logged.
        @MainActor
        public var models: [Model] {
            do {
                return try context.fetch(fetchDescriptor())
            } catch {
                log(
                    error: error,
                    message: "\(ModelState.emoji) ModelState Fetching",
                    fileID: #fileID,
                    function: #function,
                    line: #line,
                    column: #column
                )

                return []
            }
        }

        /**
         Creates a new model state within a given scope.

         - Parameters:
            - containerKeyPath: The `KeyPath` to the `ModelContainer` dependency that backs this state.
            - fetchDescriptor: A closure producing the `FetchDescriptor` used to read the models.
            - scope: The scope in which the state exists.
         */
        init(
            containerKeyPath: KeyPath<Application, Dependency<ModelContainer>>,
            fetchDescriptor: @escaping () -> FetchDescriptor<Model>,
            scope: Scope
        ) {
            self.containerKeyPath = containerKeyPath
            self.fetchDescriptor = fetchDescriptor
            self.scope = scope
        }

        /// Inserts a model into the backing `ModelContext` and saves.
        ///
        /// - Parameter model: The model to insert.
        @MainActor
        public func insert(_ model: Model) {
            let context = context
            context.insert(model)
            save(context: context, action: "Inserting")
        }

        /// Deletes a model from the backing `ModelContext` and saves.
        ///
        /// - Parameter model: The model to delete.
        @MainActor
        public func delete(_ model: Model) {
            let context = context
            context.delete(model)
            save(context: context, action: "Deleting")
        }

        /// Persists any pending changes in the backing `ModelContext`.
        @MainActor
        public func save() {
            save(context: context, action: "Saving")
        }

        /// Deletes **every** model matching this state's `FetchDescriptor` and saves.
        ///
        /// - Warning: This permanently removes the matching objects from the persistent store. It is a
        ///   destructive operation; there is no `reset()`-style restoration of an initial value because
        ///   the store itself is the source of truth.
        @MainActor
        public func deleteAll() {
            let context = context

            do {
                try context.delete(model: Model.self, where: fetchDescriptor().predicate)
                save(context: context, action: "Deleting")
            } catch {
                log(
                    error: error,
                    message: "\(ModelState.emoji) ModelState Deleting",
                    fileID: #fileID,
                    function: #function,
                    line: #line,
                    column: #column
                )
            }
        }

        @MainActor
        private func save(context: ModelContext, action: String) {
            guard context.hasChanges else { return }

            do {
                try context.save()
            } catch {
                log(
                    error: error,
                    message: "\(ModelState.emoji) ModelState \(action)",
                    fileID: #fileID,
                    function: #function,
                    line: #line,
                    column: #column
                )
            }
        }
    }
}

// MARK: - ModelState Functions

public extension Application {
    /**
     Retrieves a `ModelState<Model>` instance from the shared `Application` using its `KeyPath`.

     This function provides access to the `ModelState` management object itself, which is backed by
     a SwiftData `ModelContainer`. You can use it to read its `models` or perform mutations
     (`insert`, `delete`, `save`, `deleteAll`).

     - Parameters:
       - keyPath: The `KeyPath` referencing the desired `ModelState` property (e.g., `\.items`).
       - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
       - function: The name of the declaration in which this function is called. Defaults to `#function`.
       - line: The line number on which this function is called. Defaults to `#line`.
       - column: The column number in which this function is called. Defaults to `#column`.
     - Returns: The requested `ModelState<Model>` instance.
     */
    @MainActor
    static func modelState<Model>(
        _ keyPath: KeyPath<Application, ModelState<Model>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> ModelState<Model> {
        let modelState = shared.value(keyPath: keyPath)

        log(
            debug: "🗃️ Getting ModelState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return modelState
    }

    /**
     Defines and retrieves a `ModelState<Model>` instance backed by a `ModelContainer` dependency,
     associated with a specific feature and identifier, using the supplied `FetchDescriptor`.

     - Parameters:
        - container: The `KeyPath` to the `ModelContainer` dependency that backs this state.
        - fetchDescriptor: An autoclosure providing the `FetchDescriptor` used to read the models.
        - feature: A `String` namespacing the state, often corresponding to a feature module. Defaults to "App".
        - id: A `String` uniquely identifying the state within its feature scope.
     - Returns: The `ModelState<Model>` instance.
     */
    func modelState<Model>(
        container: KeyPath<Application, Dependency<ModelContainer>>,
        fetchDescriptor: @escaping @autoclosure () -> FetchDescriptor<Model>,
        feature: String = "App",
        id: String
    ) -> ModelState<Model> {
        ModelState(
            containerKeyPath: container,
            fetchDescriptor: fetchDescriptor,
            scope: Scope(name: feature, id: id)
        )
    }

    /// Defines and retrieves a `ModelState<Model>` instance backed by a `ModelContainer` dependency,
    /// associated with a specific feature and identifier, fetching all models of the type.
    ///
    /// - Parameters:
    ///   - container: The `KeyPath` to the `ModelContainer` dependency that backs this state.
    ///   - feature: A `String` namespacing the state. Defaults to "App".
    ///   - id: A `String` uniquely identifying the state within its feature scope.
    /// - Returns: The `ModelState<Model>` instance.
    func modelState<Model>(
        container: KeyPath<Application, Dependency<ModelContainer>>,
        feature: String = "App",
        id: String
    ) -> ModelState<Model> {
        modelState(
            container: container,
            fetchDescriptor: FetchDescriptor<Model>(),
            feature: feature,
            id: id
        )
    }

    /// Defines and retrieves a `ModelState<Model>` instance with an automatically generated
    /// identifier derived from the call site's context, using the supplied `FetchDescriptor`.
    ///
    /// - Parameters:
    ///   - container: The `KeyPath` to the `ModelContainer` dependency that backs this state.
    ///   - fetchDescriptor: An autoclosure providing the `FetchDescriptor`.
    ///   - fileID: The calling file's identifier. Automatically captured.
    ///   - function: The calling function's name. Automatically captured.
    ///   - line: The line number of the call. Automatically captured.
    ///   - column: The column number of the call. Automatically captured.
    /// - Returns: The `ModelState<Model>` instance.
    func modelState<Model>(
        container: KeyPath<Application, Dependency<ModelContainer>>,
        fetchDescriptor: @escaping @autoclosure () -> FetchDescriptor<Model>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> ModelState<Model> {
        modelState(
            container: container,
            fetchDescriptor: fetchDescriptor(),
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }

    /// Defines and retrieves a `ModelState<Model>` instance with an automatically generated
    /// identifier derived from the call site's context, fetching all models of the type.
    ///
    /// - Parameters:
    ///   - container: The `KeyPath` to the `ModelContainer` dependency that backs this state.
    ///   - fileID: The calling file's identifier. Automatically captured.
    ///   - function: The calling function's name. Automatically captured.
    ///   - line: The line number of the call. Automatically captured.
    ///   - column: The column number of the call. Automatically captured.
    /// - Returns: The `ModelState<Model>` instance.
    func modelState<Model>(
        container: KeyPath<Application, Dependency<ModelContainer>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> ModelState<Model> {
        modelState(
            container: container,
            fetchDescriptor: FetchDescriptor<Model>(),
            fileID,
            function,
            line,
            column
        )
    }
}
#endif
