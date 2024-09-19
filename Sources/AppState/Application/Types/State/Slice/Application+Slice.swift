extension Application {
    /// `Slice` allows access and modification to a specific part of an AppState's state. Supports `State`, `SyncState`, and `StorageState`.
    public struct Slice<
        SlicedState: MutableApplicationState,
        Value,
        SliceValue,
        SliceKeyPath: KeyPath<Value, SliceValue>
    > where SlicedState.Value == Value {
        /// A private backing storage for the value.
        private var state: SlicedState
        private let keyPath: SliceKeyPath

        @MainActor
        init(
            _ stateKeyPath: KeyPath<Application, SlicedState>,
            value valueKeyPath: SliceKeyPath
        ) {
            self.state = shared.value(keyPath: stateKeyPath)
            self.keyPath = valueKeyPath
        }
    }
}

extension Application.Slice where SliceKeyPath == KeyPath<Value, SliceValue> {
    /// The current state value.
    @MainActor
    public var value: SliceValue {
        state.value[keyPath: keyPath]
    }
}

extension Application.Slice where SliceKeyPath == WritableKeyPath<Value, SliceValue> {
    /// The current state value.
    @MainActor
    public var value: SliceValue {
        get { state.value[keyPath: keyPath] }
        set { state.value[keyPath: keyPath] = newValue }
    }
}
