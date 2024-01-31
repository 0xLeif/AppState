import Foundation

extension Application {
    /// The shared `FileManager` instance.
    public var fileManager: Dependency<FileManager> {
        dependency(FileManager.default)
    }

    /// `FileState` encapsulates the value within the application's scope and allows any changes to be propagated throughout the scoped area.  State is stored using `FileManager`.
    public struct FileState<Value: Codable>: MutableApplicationState {
        @AppDependency(\.fileManager) private var fileManager: FileManager

        /// The initial value of the state.
        private var initial: () -> Value

        /// The current state value.
        public var value: Value {
            get {
                let cachedValue = shared.cache.get(
                    scope.key,
                    as: State<Value>.self
                )

                if let cachedValue = cachedValue {
                    return cachedValue.value
                }

                do {
                    return try fileManager.in(path: path, filename: filename)
                } catch {
                    log(
                        error: error,
                        message: "🗄️ FileState Fetching",
                        fileID: #fileID,
                        function: #function,
                        line: #line,
                        column: #column
                    )

                    return initial()
                }
            }
            set {
                let mirror = Mirror(reflecting: newValue)

                if mirror.displayStyle == .optional,
                   mirror.children.isEmpty {
                    shared.cache.remove(scope.key)
                    do {
                        try fileManager.delete(path: path, filename: filename)
                    } catch {
                        log(
                            error: error,
                            message: "🗄️ FileState Deleting",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    }
                } else {
                    shared.cache.set(
                        value: Application.State(
                            type: .stored,
                            initial: newValue,
                            scope: scope
                        ),
                        forKey: scope.key
                    )

                    do {
                        try fileManager.out(newValue, path: path, filename: filename)
                    } catch {
                        log(
                            error: error,
                            message: "🗄️ FileState Saving",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    }
                }
            }
        }

        /// The scope in which this state exists.
        let scope: Scope

        var path: String { scope.name }
        var filename: String { scope.id }

        /**
         Creates a new state within a given scope initialized with the provided value.

         - Parameters:
             - value: The initial value of the state
             - scope: The scope in which the state exists
         */
        init(
            initial: @escaping @autoclosure () -> Value,
            scope: Scope
        ) {
            self.initial = initial
            self.scope = scope
        }

        /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `FileManager`
        public mutating func reset() {
            value = initial()
        }
    }
}
