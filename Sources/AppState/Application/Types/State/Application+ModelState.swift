#if canImport(SwiftData)
import Foundation
import SwiftData

extension Application {
    /// `ModelState` exposes a collection of SwiftData `@Model` objects through the application's
    /// scope. It is backed by a `ModelContainer` dependency and reads/writes through that
    /// container's `mainContext`.
    ///
    /// Reading ``value`` performs a fetch using the supplied `FetchDescriptor`. Mutations are
    /// persisted through the same `ModelContext`.
    ///
    /// - Note: `ModelState` does not cache results in AppState's cache — SwiftData's
    ///   `ModelContext` is the source of truth. Because mutations are not automatically broadcast
    ///   to SwiftUI, prefer SwiftData's own `@Query` for reactive views and use `ModelState`
    ///   (and the `@ModelState` property wrapper) from view models, services, and other
    ///   non-view code that needs shared, dependency-injected access to your models.
    public struct ModelState<Model: PersistentModel>: MutableApplicationState {
        public typealias Value = [Model]

        public static var emoji: Character { "🗃️" }

        /// The `KeyPath` to the `ModelContainer` dependency that backs this state.
        let containerKeyPath: KeyPath<Application, Dependency<ModelContainer>>

        /// A closure producing the `FetchDescriptor` used when reading ``value``.
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
        /// - Getting performs a fetch against the backing `ModelContext`. On failure an empty
        ///   array is returned and the error is logged.
        /// - Setting inserts any models in the new value that are not yet persisted and saves the
        ///   context. Existing models that are absent from the new value are **not** deleted; use
        ///   ``delete(_:)`` or ``reset()`` for removal.
        @MainActor
        public var value: [Model] {
            get {
                do {
                    return try context.fetch(fetchDescriptor())
                } catch {
                    Application.log(
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
            set {
                let context = context

                for model in newValue where model.modelContext == nil {
                    context.insert(model)
                }

                save(context: context, action: "Saving")
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

        /// Resets the state by deleting every model matching this state's `FetchDescriptor` and saving.
        @MainActor
        public mutating func reset() {
            let context = context

            do {
                let models = try context.fetch(fetchDescriptor())

                for model in models {
                    context.delete(model)
                }

                save(context: context, action: "Resetting")
            } catch {
                Application.log(
                    error: error,
                    message: "\(ModelState.emoji) ModelState Resetting",
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
                Application.log(
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
    /// Resets a `ModelState` instance, deleting every model it manages.
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` of the `ModelState` to reset (e.g., `\.items`).
    ///   - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
    ///   - function: The name of the declaration in which this function is called. Defaults to `#function`.
    ///   - line: The line number on which this function is called. Defaults to `#line`.
    ///   - column: The column number in which this function is called. Defaults to `#column`.
    @MainActor
    static func reset<Model>(
        modelState keyPath: KeyPath<Application, ModelState<Model>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        log(
            debug: "🗃️ Resetting ModelState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var modelState = shared.value(keyPath: keyPath)
        modelState.reset()
    }

    /**
     Retrieves a `ModelState<Model>` instance from the shared `Application` using its `KeyPath`.

     This function provides access to the `ModelState` management object itself, which is backed by
     a SwiftData `ModelContainer`. You can use this to read its `value` or perform mutations.

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
