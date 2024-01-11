extension Application {
    /// `OptionalSlice` allows access and modification to a specific part of an AppState's state. Supports `State`, `SyncState`, and `StorageState`.
    public struct OptionalSlice<
        SlicedState: MutableApplicationState,
        Value,
        SliceValue,
        SliceKeyPath: KeyPath<Value, SliceValue>
    > where SlicedState.Value == Value? {
        /// A private backing storage for the value.
        private var state: SlicedState
        private let keyPath: SliceKeyPath

        init(
            _ stateKeyPath: KeyPath<Application, SlicedState>,
            value valueKeyPath: SliceKeyPath
        ) {
            self.state = shared.value(keyPath: stateKeyPath)
            self.keyPath = valueKeyPath
        }
    }
}

extension Application.OptionalSlice where SliceKeyPath == KeyPath<Value, SliceValue> {
    /// The current state value.
    public var value: SliceValue? {
        state.value?[keyPath: keyPath]
    }
}

extension Application.OptionalSlice where SliceKeyPath == WritableKeyPath<Value, SliceValue> {
    /// The current state value.
    public var value: SliceValue? {
        get { state.value?[keyPath: keyPath] }
        set {
            guard var sliceState = state.value else {
                return
            }

            if let newValue {
                sliceState[keyPath: keyPath] = newValue
            }

            state.value = sliceState
        }
    }
}
