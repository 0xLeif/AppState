import Foundation

extension Application {
    /// The shared `FileManager` instance.
    public var fileManager: Dependency<FileManager> {
        dependency(FileManager.default)
    }

    /// `FileState` encapsulates the value within the application's scope and allows any changes to be propagated throughout the scoped area.  State is stored using `FileManager`.
    public struct FileState<Value: Codable>: MutableApplicationState {
        public static var emoji: Character { "🗄️" }

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
                    let storedValue: Value = try fileManager.in(path: path, filename: filename)

                    defer {
                        let setValue = {
                            shared.cache.set(
                                value: Application.State(
                                    type: .file,
                                    initial: storedValue,
                                    scope: scope
                                ),
                                forKey: scope.key
                            )
                        }

                        #if (!os(Linux) && !os(Windows))
                        if NSClassFromString("XCTest") == nil {
                            Task {
                                await MainActor.run {
                                    setValue()
                                }
                            }
                        } else {
                            setValue()
                        }
                        #else
                        setValue()
                        #endif
                    }

                    return storedValue
                } catch {
                    log(
                        error: error,
                        message: "\(FileState.emoji) FileState Fetching",
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
                            message: "\(FileState.emoji) FileState Deleting",
                            fileID: #fileID,
                            function: #function,
                            line: #line,
                            column: #column
                        )
                    }
                } else {
                    shared.cache.set(
                        value: Application.State(
                            type: .file,
                            initial: newValue,
                            scope: scope
                        ),
                        forKey: scope.key
                    )

                    do {
                        try fileManager.out(
                            newValue,
                            path: path,
                            filename: filename,
                            base64Encoded: isBase64Encoded
                        )
                    } catch {
                        log(
                            error: error,
                            message: "\(FileState.emoji) FileState Saving",
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

        let isBase64Encoded: Bool

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
            scope: Scope,
            isBase64Encoded: Bool
        ) {
            self.initial = initial
            self.scope = scope
            self.isBase64Encoded = isBase64Encoded
        }

        /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `FileManager`
        public mutating func reset() {
            value = initial()
        }
    }
}
