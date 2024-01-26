/// A property wrapper that provides access to a specific part of the AppState's state.
@propertyWrapper public struct OptionalConstant<SlicedState: MutableApplicationState, Value, SliceValue> where SlicedState.Value == Value? {
    /// Path for accessing `State` from Application.
    private let stateKeyPath: KeyPath<Application, SlicedState>

    /// Path for accessing `SliceValue` from `Value`.
    private let valueKeyPath: KeyPath<Value, SliceValue>?

    /// Path for accessing `SliceValue?` from `Value`.
    private let optionalValueKeyPath: KeyPath<Value, SliceValue?>?

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int
    private let sliceKeyPath: String

    /// Represents the current value of the `State`.
    public var wrappedValue: SliceValue? {
        if let valueKeyPath {
            return Application.slice(
                stateKeyPath,
                valueKeyPath,
                fileID,
                function,
                line,
                column
            ).value
        }

        guard
            let optionalValueKeyPath,
            let slicedValue = Application.slice(
                stateKeyPath,
                optionalValueKeyPath,
                fileID,
                function,
                line,
                column
            ).value
        else {
            return nil
        }

        return slicedValue
    }

    /**
     Initializes a OptionalConstant with the provided parameters. This constructor is used to create a OptionalConstant that provides access to a specific part of an AppState's state. It provides granular control over the AppState.

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
    ) {
        self.stateKeyPath = stateKeyPath
        self.valueKeyPath = valueKeyPath
        self.optionalValueKeyPath = nil
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
     Initializes a OptionalConstant with the provided parameters. This constructor is used to create a OptionalConstant that provides access to a specific part of an AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath that points to the state in AppState that should be sliced.
         - valueKeyPath: A KeyPath that points to the specific part of the state that should be accessed.
     */
    public init(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ optionalValueKeyPath: KeyPath<Value, SliceValue?>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        self.stateKeyPath = stateKeyPath
        self.valueKeyPath = nil
        self.optionalValueKeyPath = optionalValueKeyPath
        self.fileID = fileID
        self.function = function
        self.line = line
        self.column = column

        let stateKeyPathString = String(describing: stateKeyPath)
        let valueTypeCharacterCount = String(describing: Value.self).count
        var valueKeyPathString = String(describing: optionalValueKeyPath)

        valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

        self.sliceKeyPath = "\(stateKeyPathString)\(valueKeyPathString)"
    }
}
