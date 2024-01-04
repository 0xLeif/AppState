extension Application {
    /// TODO: ...
    public struct Slice<SlicedState: MutableCachedApplicationValue, Value, SliceValue> where SlicedState.Value == Value {
        /// A private backing storage for the value.
        private var state: SlicedState
        private let keyPath: WritableKeyPath<Value, SliceValue>

        /// The current state value.
        public var value: SliceValue {
            get { state.value[keyPath: keyPath] }
            set { state.value[keyPath: keyPath] = newValue }
        }

        init(
            _ stateKeyPath: KeyPath<Application, SlicedState>,
            value valueKeyPath: WritableKeyPath<Value, SliceValue>
        ) {
            self.state = shared.value(keyPath: stateKeyPath)
            self.keyPath = valueKeyPath
        }
    }
}
