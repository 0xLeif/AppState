extension Application {
    /// `DependencySlice` allows access and modification to a specific part of an AppState's dependencies. Supports `Dependency`.
    public struct DependencySlice<
        Value: Sendable,
        SliceValue,
        SliceKeyPath: KeyPath<Value, SliceValue>
    > {
        /// A private backing storage for the dependency.
        private var dependency: Dependency<Value>
        private let keyPath: SliceKeyPath

        @MainActor
        init(
            _ stateKeyPath: KeyPath<Application, Dependency<Value>>,
            value valueKeyPath: SliceKeyPath
        ) {
            self.dependency = shared.value(keyPath: stateKeyPath)
            self.keyPath = valueKeyPath
        }
    }
}

extension Application.DependencySlice where SliceKeyPath == KeyPath<Value, SliceValue> {
    /// The current dependency value.
    @MainActor
    public var value: SliceValue {
        dependency.value[keyPath: keyPath]
    }
}

extension Application.DependencySlice where SliceKeyPath == WritableKeyPath<Value, SliceValue> {
    /// The current dependency value.
    @MainActor
    public var value: SliceValue {
        get { dependency.value[keyPath: keyPath] }
        set {
            #if !os(Linux) && !os(Windows)
            Application.shared.objectWillChange.send()
            #endif
            dependency.value[keyPath: keyPath] = newValue
        }
    }
}
