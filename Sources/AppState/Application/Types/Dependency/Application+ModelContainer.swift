#if canImport(SwiftData)
import Foundation
import SwiftData

public extension Application {
    /// Retrieves the `ModelContext` associated with a `ModelContainer` dependency.
    ///
    /// SwiftData's `ModelContainer` is `Sendable` and can therefore be stored as a regular
    /// AppState `Dependency`. Define one on an `Application` extension just like any other
    /// dependency:
    ///
    /// ```swift
    /// extension Application {
    ///     var modelContainer: Dependency<ModelContainer> {
    ///         dependency(
    ///             try! ModelContainer(for: Item.self)
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// You can then access the shared, main-actor bound `ModelContext` anywhere in your app
    /// (including view models and services that have no access to SwiftUI's `@Environment`):
    ///
    /// ```swift
    /// let context = Application.modelContext(\.modelContainer)
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` referencing a `Dependency<ModelContainer>` defined on `Application`.
    ///   - fileID: The identifier of the file in which this function is called. Defaults to `#fileID`.
    ///   - function: The name of the declaration in which this function is called. Defaults to `#function`.
    ///   - line: The line number on which this function is called. Defaults to `#line`.
    ///   - column: The column number in which this function is called. Defaults to `#column`.
    /// - Returns: The `mainContext` of the resolved `ModelContainer`.
    @MainActor
    static func modelContext(
        _ keyPath: KeyPath<Application, Dependency<ModelContainer>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> ModelContext {
        let container = dependency(keyPath, fileID, function, line, column)

        log(
            debug: "🗃️ Getting ModelContext from \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return container.mainContext
    }

    /// Defines and retrieves a `Dependency<ModelContainer>` from an autoclosure.
    ///
    /// This is a convenience for registering a `ModelContainer` as a dependency with an
    /// automatically generated identifier derived from the call site. The autoclosure is
    /// evaluated only once, the first time the dependency is accessed.
    ///
    /// ```swift
    /// extension Application {
    ///     var modelContainer: Dependency<ModelContainer> {
    ///         modelContainer(
    ///             try! ModelContainer(for: Item.self)
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - container: An autoclosure that creates and returns the `ModelContainer`. Evaluated only if not cached.
    ///   - fileID: The calling file's identifier. Automatically captured.
    ///   - function: The calling function's name. Automatically captured.
    ///   - line: The line number of the call. Automatically captured.
    ///   - column: The column number of the call. Automatically captured.
    /// - Returns: The `Dependency<ModelContainer>` instance.
    func modelContainer(
        _ container: @autoclosure () -> ModelContainer,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Dependency<ModelContainer> {
        dependency(
            container(),
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }
}
#endif
