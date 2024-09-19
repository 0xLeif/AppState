extension Application {
    @MainActor
    static var cacheDescription: String {
        shared.cache.allValues
            .map { key, value in
                "\t- \(value)"
            }
            .sorted(by: <)
            .joined(separator: "\n")
    }
    
    /**
     Generates a specific identifier string for given code context

     - Parameters:
         - fileID: The file identifier of the code, generally provided by `#fileID` directive.
         - function: The function name of the code, generally provided by `#function` directive.
         - line: The line number of the code, generally provided by `#line` directive.
         - column: The column number of the code, generally provided by `#column` directive.
     - Returns: A string representing the specific location and context of the code. The format is `<fileID>[<function>@<line>|<column>]`.
     */
    static func codeID(
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
    ) -> String {
        "\(fileID)[\(function)@\(line)|\(column)]"
    }

    /// Internal log function.
    @MainActor
    static func log(
        debug message: String,
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
    ) {
        log(
            debug: { message },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    /// Internal log function.
    @MainActor
    static func log(
        debug message: () -> String,
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
    ) {
        guard isLoggingEnabled else { return }

        let excludedFileIDs: [String] = [
            "AppState/Application+StoredState.swift",
            "AppState/Application+SyncState.swift",
            "AppState/Application+SecureState.swift",
            "AppState/Application+Slice.swift",
            "AppState/Application+FileState.swift",
        ]
        let isFileIDValue: Bool = excludedFileIDs.contains(fileID.description) == false

        guard isFileIDValue else { return }

        let debugMessage = message()
        let codeID = codeID(fileID: fileID, function: function, line: line, column: column)

        logger.debug("\(debugMessage) (\(codeID))")
    }

    /// Internal log function.
    @MainActor
    static func log(
        error: Error,
        message: String,
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
    ) {
        guard isLoggingEnabled else { return }

        let codeID = codeID(fileID: fileID, function: function, line: line, column: column)

        logger.error(
            """
            \(message) Error: {
                ❌ \(error)
            } (\(codeID))
            """
        )
    }

    /// Returns value for the provided keyPath. This method is thread safe
    ///
    /// - Parameter keyPath: KeyPath of the value to be fetched
    func value<Value>(keyPath: KeyPath<Application, Value>) -> Value {
        lock.lock(); defer { lock.unlock() }

        return self[keyPath: keyPath]
    }

    /**
     Use this function to make sure Dependencies are intialized. If a Dependency is not loaded, it will be initialized whenever it is used next.

     - Parameter dependency: KeyPath of the Dependency to be loaded
     */
    func load<Value>(
        dependency keyPath: KeyPath<Application, Dependency<Value>>
    ) {
        _ = value(keyPath: keyPath)
    }
}
