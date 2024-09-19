import Foundation

extension Application {
    public struct SendableFileManager: Sendable {
        public func `in`<Value: Decodable>(
            path: String = ".",
            filename: String
        ) throws -> Value {
            try FileManager.default.in(path: path, filename: filename)
        }

        public func `out`<Value: Encodable>(
            _ value: Value,
            path: String = ".",
            filename: String,
            base64Encoded: Bool = true
        ) throws {
            try FileManager.default.out(
                value,
                path: path,
                filename: filename,
                base64Encoded: base64Encoded
            )
        }

        public func `delete`(path: String = ".", filename: String) throws {
            try FileManager.default.delete(path: path, filename: filename)
        }

        public func removeItem(atPath path: String) throws {
            try FileManager.default.removeItem(atPath: path)
        }
    }

    /// The shared `FileManager` instance.
    public var fileManager: Dependency<SendableFileManager> {
        dependency(SendableFileManager())
    }

    /// `FileState` encapsulates the value within the application's scope and allows any changes to be propagated throughout the scoped area.  State is stored using `FileManager`.
    public struct FileState<Value: Codable & Sendable>: MutableApplicationState {
        public static var emoji: Character { "🗄️" }

        @AppDependency(\.fileManager) private var fileManager: SendableFileManager

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
        @MainActor
        public mutating func reset() {
            value = initial()
        }
    }
}
