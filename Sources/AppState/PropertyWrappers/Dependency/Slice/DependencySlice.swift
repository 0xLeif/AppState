#if !os(Linux) && !os(Windows)
import Combine
import SwiftUI
#endif

/// A property wrapper that provides access to a specific part of the AppState's dependencies.
@propertyWrapper public struct DependencySlice<Value, SliceValue> {
    #if !os(Linux) && !os(Windows)
    /// Holds the singleton instance of `Application`.
    @ObservedObject private var app: Application = Application.shared
    #else
    /// Holds the singleton instance of `Application`.
    private var app: Application = Application.shared
    #endif

    /// Path for accessing `Dependency` from Application.
    private let dependencyKeyPath: KeyPath<Application, Application.Dependency<Value>>

    /// Path for accessing `SliceValue` from `Value`.
    private let valueKeyPath: WritableKeyPath<Value, SliceValue>

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int
    private let sliceKeyPath: String

    /// Represents the current value of the `Dependency`.
    public var wrappedValue: SliceValue {
        get {
            Application.dependencySlice(
                dependencyKeyPath,
                valueKeyPath,
                fileID,
                function,
                line,
                column
            ).value
        }
        nonmutating set {
            Application.log(
                debug: "🔗 Setting DependencySlice \(sliceKeyPath) = \(newValue)",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            var dependency = app.value(keyPath: dependencyKeyPath)
            #if !os(Linux) && !os(Windows)
            Application.shared.objectWillChange.send()
            #endif
            dependency.value[keyPath: valueKeyPath] = newValue
        }
    }

    #if !os(Linux) && !os(Windows)
    /// A binding to the `Dependency`'s value, which can be used with SwiftUI views.
    public var projectedValue: Binding<SliceValue> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    #endif

    /**
     Initializes a DependencySlice with the provided parameters. This constructor is used to create a DependencySlice that provides access and modification to a specific part of an AppState's dependencies. It provides granular control over the AppState.

     - Parameters:
         - dependencyKeyPath: A KeyPath that points to the dependency in AppState that should be sliced.
         - valueKeyPath: A WritableKeyPath that points to the specific part of the state that should be accessed.
     */
    public init(
        _ dependencyKeyPath: KeyPath<Application, Application.Dependency<Value>>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        self.dependencyKeyPath = dependencyKeyPath
        self.valueKeyPath = valueKeyPath
        self.fileID = fileID
        self.function = function
        self.line = line
        self.column = column

        let dependencyKeyPathString = String(describing: dependencyKeyPath)
        let valueTypeCharacterCount = String(describing: Value.self).count
        var valueKeyPathString = String(describing: valueKeyPath)

        valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

        self.sliceKeyPath = "\(dependencyKeyPathString)\(valueKeyPathString)"
    }
}

#if !os(Linux) && !os(Windows)
extension DependencySlice: DynamicProperty { }
#endif
