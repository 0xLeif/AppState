extension Application {
    /// `OptionalSliceOptionalValue` allows access and modification to a specific part of an AppState's state. Supports `State`, `SyncState`, and `StorageState`.
    public struct OptionalSliceOptionalValue<
        SlicedState: MutableApplicationState,
        Value,
        SliceValue,
        SliceKeyPath: KeyPath<Value, SliceValue?>
    > where SlicedState.Value == Value? {
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

extension Application.OptionalSliceOptionalValue where SliceKeyPath == KeyPath<Value, SliceValue?> {
    /// The current state value.
    @MainActor
    public var value: SliceValue? {
        state.value?[keyPath: keyPath]
    }
}

extension Application.OptionalSliceOptionalValue where SliceKeyPath == WritableKeyPath<Value, SliceValue?> {
    /// The current state value.
    @MainActor
    public var value: SliceValue? {
        get {
            guard let sliceState = state.value else { return nil }

            return sliceState[keyPath: keyPath]
        }
        set {
            guard var sliceState = state.value else { return }

            sliceState[keyPath: keyPath] = newValue

            state.value = sliceState
        }
    }
}
