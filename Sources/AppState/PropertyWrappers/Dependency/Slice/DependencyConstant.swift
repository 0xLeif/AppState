/// A property wrapper that provides access to a specific part of the AppState's dependencies.
@propertyWrapper public struct DependencyConstant<Value, SliceValue, SliceKeyPath: KeyPath<Value, SliceValue>> {
    /// Path for accessing `Dependency` from Application.
    private let dependencyKeyPath: KeyPath<Application, Application.Dependency<Value>>

    /// Path for accessing `SliceValue` from `Value`.
    private let valueKeyPath: SliceKeyPath

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int
    private let sliceKeyPath: String

    /// Represents the current value of the `Dependency`.
    public var wrappedValue: SliceValue {
        Application.dependencySlice(
            dependencyKeyPath,
            valueKeyPath,
            fileID,
            function,
            line,
            column
        ).value
    }

    /**
     Initializes a Constant with the provided parameters. This constructor is used to create a Constant that provides access and modification to a specific part of an AppState's dependencies. It provides granular control over the AppState.

     - Parameters:
         - dependencyKeyPath: A KeyPath that points to the dependency in AppState that should be sliced.
         - valueKeyPath: A KeyPath that points to the specific part of the dependency that should be accessed.
     */
    public init(
        _ dependencyKeyPath: KeyPath<Application, Application.Dependency<Value>>,
        _ valueKeyPath: KeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) where SliceKeyPath == KeyPath<Value, SliceValue> {
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

    /**
     Initializes a Constant with the provided parameters. This constructor is used to create a Constant that provides access and modification to a specific part of an AppState's dependencies. It provides granular control over the AppState.

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
    ) where SliceKeyPath == WritableKeyPath<Value, SliceValue> {
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
