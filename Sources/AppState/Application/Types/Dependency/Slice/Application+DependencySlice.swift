extension Application {
    /// `DependencySlice` allows access and modification to a specific part of an AppState's dependencies. Supports `Dependency`.
    public struct DependencySlice<
        Value: Sendable,
        SliceValue,
        SliceKeyPath: KeyPath<Value, SliceValue>
    > {
        /// Fallback used only when this scope is no longer in the cache.
        /// Reads and writes otherwise load the `Dependency` stored under `scope.key`.
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

        /// The dependency currently stored for this slice's scope.
        ///
        /// A handle keeps the value from init only as a fallback. Writing that copy
        /// back would drop sibling fields and undo an `override` or `promote` that
        /// happened after the handle was created.
        @MainActor
        private func currentDependency() -> Dependency<Value> {
            Application.shared.cache.get(dependency.scope.key, as: Dependency<Value>.self) ?? dependency
        }
    }
}

extension Application.DependencySlice where SliceKeyPath == KeyPath<Value, SliceValue> {
    /// The current dependency value.
    @MainActor
    public var value: SliceValue {
        currentDependency().value[keyPath: keyPath]
    }
}

extension Application.DependencySlice where SliceKeyPath == WritableKeyPath<Value, SliceValue> {
    /// The current dependency value.
    @MainActor
    public var value: SliceValue {
        get { currentDependency().value[keyPath: keyPath] }
        set {
            let application = Application.shared
            var current = currentDependency()
            current.value[keyPath: keyPath] = newValue
            application.cache.set(value: current, forKey: current.scope.key)
            application.notifyChange()
            dependency = current
        }
    }
}
