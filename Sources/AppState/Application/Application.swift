import Cache
import Combine
import OSLog

/// `Application` is a class that can be observed for changes, keeping track of the states within the application.
open class Application: NSObject, ObservableObject {
    /// Singleton shared instance of `Application`
    static var shared: Application = Application()

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
    static func log(
        debug message: String,
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
    ) {
        guard isLoggingEnabled else { return }

        let excludedFileIDs: [String] = [
            "AppState/Application+StoredState.swift",
            "AppState/Application+SyncState.swift",
            "AppState/Application+SecureState.swift"
        ]
        let isFileIDValue: Bool = excludedFileIDs.contains(fileID.description) == false

        guard isFileIDValue else { return }

        let codeID = codeID(fileID: fileID, function: function, line: line, column: column)

        logger.debug("\(message) (\(codeID))")
    }

    /// Internal log function.
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

    /// Logger specifically for AppState
    public static let logger: Logger = Logger(subsystem: "AppState", category: "Application")
    static var isLoggingEnabled: Bool = false

    private let lock: NSLock
    private var bag: Set<AnyCancellable>

    /// Cache to store values
    let cache: Cache<String, Any>

    deinit { bag.removeAll() }

    public override required init() {
        lock = NSLock()
        bag = Set()
        cache = Cache()
        
        super.init()

        loadDefaultDependencies()

        consume(object: cache)
    }

    @objc @available(iOS 15.0, watchOS 9.0, macOS 11.0, tvOS 15.0, *)
    open func didChangeExternally(notification: Notification) {
        Application.log(
            debug: """
                    ☁️ SyncState was changed externally {
                        \(dump(notification))
                    }
                    """,
            fileID: #fileID,
            function: #function,
            line: #line,
            column: #column
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

    /// Loads the default dependencies for use in Application.
    private func loadDefaultDependencies() {
        load(dependency: \.userDefaults)
    }

    /// Consumes changes in the provided ObservableObject and sends updates before the object will change.
    ///
    /// - Parameter object: The ObservableObject to observe
    private func consume<Object: ObservableObject>(
        object: Object
    ) where ObjectWillChangePublisher == ObservableObjectPublisher {
        bag.insert(
            object.objectWillChange.sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] _ in
                    self?.objectWillChange.send()
                }
            )
        )
    }
}
