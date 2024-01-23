import Cache
#if !os(Linux) && !os(Windows)
import Combine
import OSLog
#endif

/// `Application` is a class that can be observed for changes, keeping track of the states within the application.
open class Application: NSObject {
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
        log(
            debug: { message },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    /// Internal log function.
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
            "AppState/Application+Slice.swift"
        ]
        let isFileIDValue: Bool = excludedFileIDs.contains(fileID.description) == false

        guard isFileIDValue else { return }

        let debugMessage = message()
        let codeID = codeID(fileID: fileID, function: function, line: line, column: column)


        #if !os(Linux) && !os(Windows)
        logger.debug("\(debugMessage) (\(codeID))")
        #else
        print("\(debugMessage) (\(codeID))")
        #endif
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

        #if !os(Linux) && !os(Windows)
        logger.error(
            """
            \(message) Error: {
                ❌ \(error)
            } (\(codeID))
            """
        )
        #else
        print(
            """
            \(message) Error: {
                ❌ \(error)
            } (\(codeID))
            """
        )
        #endif
    }

    static var cacheDescription: String {
        shared.cache.allValues
            .map { key, value in
                "\t- \(value)"
            }
            .sorted(by: <)
            .joined(separator: "\n")
    }

    #if !os(Linux) && !os(Windows)
    /// Logger specifically for AppState
    public static let logger: Logger = Logger(subsystem: "AppState", category: "Application")
    #else
    /// Logger specifically for AppState
    public static let logger: ApplicationLogger = ApplicationLogger()
    #endif
    static var isLoggingEnabled: Bool = false

    private let lock: NSRecursiveLock

    #if !os(Linux) && !os(Windows)
    private var bag: Set<AnyCancellable> = Set()
    #endif

    /// Cache to store values
    let cache: Cache<String, Any>

    #if !os(Linux) && !os(Windows)
    deinit { bag.removeAll() }
    #endif

    /// Default init used as the default Application, but also any custom implementation of Application. You should never call this function, but instead should use `Application.promote(to: CustomApplication.self)`
    public override required init() {
        lock = NSRecursiveLock()
        cache = Cache()
        
        super.init()

        loadDefaultDependencies()

        consume(object: cache)
    }

    #if !os(Linux) && !os(Windows)
    /**
     Called when the value of one or more keys in the local key-value store changed due to incoming data pushed from iCloud.

     This notification is sent only upon a change received from iCloud; it is not sent when your app sets a value.

     The user info dictionary can contain the reason for the notification as well as a list of which values changed, as follows:
        - The value of the ``NSUbiquitousKeyValueStoreChangeReasonKey`` key, when present, indicates why the key-value store changed. Its value is one of the constants in Change Reason Values.
        - The value of the ``NSUbiquitousKeyValueStoreChangedKeysKey``, when present, is an array of strings, each the name of a key whose value changed.

     The notification object is the ``NSUbiquitousKeyValueStore`` object whose contents changed.

     Changes you make to the key-value store are saved to memory. The system then synchronizes the in-memory keys and values with the local on-disk cache, automatically and at appropriate times. For example, it synchronizes the keys when your app is put into the background, when changes are received from iCloud, and when your app makes changes to a key but does not call the synchronize() method for several seconds.

     - Note: Calling `Application.dependency(\.icloudStore).synchronize()` does not force new keys and values to be written to iCloud. Rather, it lets iCloud know that new keys and values are available to be uploaded. Do not rely on your keys and values being available on other devices immediately. The system controls when those keys and values are uploaded. The frequency of upload requests for key-value storage is limited to several per minute.
     */
    @objc @available(watchOS 9.0, *)
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
    #endif

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

    #if !os(Linux) && !os(Windows)
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
    #endif
}

#if !os(Linux) && !os(Windows)
extension Application: ObservableObject { }
#endif
