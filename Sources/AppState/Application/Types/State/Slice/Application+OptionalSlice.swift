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

extension Application.OptionalSlice where SliceKeyPath == KeyPath<Value, SliceValue> {
    /// The current state value.
    @MainActor
    public var value: SliceValue? {
        state.value?[keyPath: keyPath]
    }
}

extension Application.OptionalSlice where SliceKeyPath == WritableKeyPath<Value, SliceValue> {
    /// The current state value.
    @MainActor
    public var value: SliceValue? {
        get {
            guard let sliceState = state.value else { return nil }

            return sliceState[keyPath: keyPath]
        }
        set {
            // A `nil` write can only be stored when `SliceValue` is itself optional.
            // Otherwise nothing is written, so observers are not notified of a change that did not happen.
            guard
                var sliceState = state.value,
                let sliceValue = newValue ?? Application.nilSliceValue()
            else { return }

            sliceState[keyPath: keyPath] = sliceValue

            state.value = sliceState
        }
    }
}

extension Application {
    /// The `nil` of `SliceValue` when `SliceValue` is itself an optional type, otherwise `nil`.
    ///
    /// The slice setters use this to decide whether a `nil` write has anything to store.
    static func nilSliceValue<SliceValue>(
        _ type: SliceValue.Type = SliceValue.self
    ) -> SliceValue? {
        guard let nilType = type as? any ExpressibleByNilLiteral.Type else { return nil }

        return nilType.init(nilLiteral: ()) as? SliceValue
    }
}
