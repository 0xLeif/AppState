import Cache
#if !os(Linux) && !os(Windows)
import Combine
import OSLog
#else
import Foundation
#endif

/// `Application` is a class that can be observed for changes, keeping track of the states within the application.
open class Application: NSObject {
    /// Singleton shared instance of `Application`
    @MainActor
    static var shared: Application = Application()

    #if !os(Linux) && !os(Windows)
    /// Logger specifically for AppState
    public static let logger: Logger = Logger(subsystem: "AppState", category: "Application")
    #else
    /// Logger specifically for AppState
    public static var logger: ApplicationLogger = ApplicationLogger()
    #endif

    @MainActor
    static var isLoggingEnabled: Bool = false

    let lock: NSRecursiveLock

    /// Cache to store values
    let cache: Cache<String, Any>

    #if !os(Linux) && !os(Windows)
    private var bag: Set<AnyCancellable> = Set()

    deinit { bag.removeAll() }
    #endif

    /// Default init used as the default Application, but also any custom implementation of Application. You should never call this function, but instead should use `Application.promote(to: CustomApplication.self)`.
    public required init(
        setup: (Application) -> Void = { _ in }
    ) {
        lock = NSRecursiveLock()
        cache = Cache()

        super.init()

        setup(self)
        loadDefaultDependencies()

        #if !os(Linux) && !os(Windows)
        consume(object: cache)
        #endif
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
    @MainActor
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

    /// Loads the default dependencies for use in Application.
    private func loadDefaultDependencies() {
        load(dependency: \.userDefaults)
        load(dependency: \.fileManager)
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
