/// A property wrapper that provides access to a specific part of the AppState's state.
@propertyWrapper public struct Constant<SlicedState: MutableApplicationState, Value, SliceValue, SliceKeyPath: KeyPath<Value, SliceValue>> where SlicedState.Value == Value {
    /// Path for accessing `State` from Application.
    private let stateKeyPath: KeyPath<Application, SlicedState>

    /// Path for accessing `SliceValue` from `Value`.
    private let valueKeyPath: SliceKeyPath

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int
    private let sliceKeyPath: String

    /// Represents the current value of the `State`.
    public var wrappedValue: SliceValue {
        Application.slice(
            stateKeyPath,
            valueKeyPath,
            fileID,
            function,
            line,
            column
        ).value
    }

    /**
     Initializes a Constant with the provided parameters. This constructor is used to create a Constant that provides access to a specific part of an AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath that points to the state in AppState that should be sliced.
         - valueKeyPath: A KeyPath that points to the specific part of the state that should be accessed.
     */
    public init(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: KeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) where SliceKeyPath == KeyPath<Value, SliceValue> {
        self.stateKeyPath = stateKeyPath
        self.valueKeyPath = valueKeyPath
        self.fileID = fileID
        self.function = function
        self.line = line
        self.column = column

        let stateKeyPathString = String(describing: stateKeyPath)
        let valueTypeCharacterCount = String(describing: Value.self).count
        var valueKeyPathString = String(describing: valueKeyPath)

        valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

        self.sliceKeyPath = "\(stateKeyPathString)\(valueKeyPathString)"
    }

    /**
     Initializes a Constant with the provided parameters. This constructor is used to create a Constant that provides access to a specific part of an AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath that points to the state in AppState that should be sliced.
         - valueKeyPath: A WritableKeyPath that points to the specific part of the state that should be accessed.
     */
    public init(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) where SliceKeyPath == WritableKeyPath<Value, SliceValue> {
        self.stateKeyPath = stateKeyPath
        self.valueKeyPath = valueKeyPath
        self.fileID = fileID
        self.function = function
        self.line = line
        self.column = column

        let stateKeyPathString = String(describing: stateKeyPath)
        let valueTypeCharacterCount = String(describing: Value.self).count
        var valueKeyPathString = String(describing: valueKeyPath)

        valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

        self.sliceKeyPath = "\(stateKeyPathString)\(valueKeyPathString)"
    }
}
