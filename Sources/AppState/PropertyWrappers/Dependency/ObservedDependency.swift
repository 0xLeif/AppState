#if !os(Linux) && !os(Windows)
import SwiftUI

/// The `@ObservedDependency` property wrapper is a feature provided by AppState, intended to simplify dependency handling throughout your application. It makes it easy to access, share, and manage dependencies in a neat and Swift idiomatic way. It works the same as `@AppDependency`, but comes with the power of the `@ObservedObject` property wrapper.
@propertyWrapper public struct ObservedDependency<Value>: DynamicProperty where Value: ObservableObject {
    /// Path for accessing `ObservedDependency` from Application.
    private let keyPath: KeyPath<Application, Application.Dependency<Value>>

    @ObservedObject private var observedObject: Value

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int

    /// Represents the current value of the `ObservedDependency`.
    public var wrappedValue: Value {
        Application.log(
            debug: "🔗 Getting ObservedDependency \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return observedObject
    }

    /// A binding to the `ObservedDependency`'s value, which can be used with SwiftUI views.
    public var projectedValue: ObservedObject<Value>.Wrapper {
        Application.log(
            debug: "🔗 Getting ObservedDependency \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return $observedObject
    }

    /**
     Initializes the ObservedDependency.

     - Parameter keyPath: The `KeyPath` for accessing `Dependency` in Application.
     */
    public init(
        _ keyPath: KeyPath<Application, Application.Dependency<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        self.keyPath = keyPath
        self.fileID = fileID
        self.function = function
        self.line = line
        self.column = column

        self.observedObject = Application.dependency(
            keyPath,
            fileID,
            function,
            line,
            column
        )
    }
}
#endif
