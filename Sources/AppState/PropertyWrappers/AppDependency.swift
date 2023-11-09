import Combine

/// The `@AppDependency` property wrapper is a feature provided by AppState, intended to simplify dependency handling throughout your application. It makes it easy to access, share, and manage dependencies in a neat and Swift idiomatic way.
@propertyWrapper public struct AppDependency<Value> {
    /// Path for accessing `Dependency` from Application.
    private let keyPath: KeyPath<Application, Application.Dependency<Value>>

    /// Represents the current value of the `Dependency`.
    public var wrappedValue: Value {
        Application.dependency(keyPath)
    }

    /**
     Initializes the AppDependency with a `keyPath` for accessing `Dependency` in Application.

     - Parameter keyPath: The `KeyPath` for accessing `Dependency` in Application.
     */
    public init(
        _ keyPath: KeyPath<Application, Application.Dependency<Value>>
    ) {
        self.keyPath = keyPath
    }
}
