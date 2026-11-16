import Cache
import Foundation
import Observation
#if canImport(OSLog)
import OSLog
#endif

/// `Application` is a class that can be observed for changes, keeping track of the states within the application.
@Observable
open class Application: NSObject {
    /// Singleton shared instance of `Application`
    @MainActor
    static var shared: Application = Application()

    #if canImport(OSLog)
    /// Logger specifically for AppState
    public var logger: Dependency<Logger> {
        dependency(Logger(subsystem: "AppState", category: "Application"))
    }
    #else
    /// Logger specifically for AppState
    public var logger: Dependency<ApplicationLogger> {
        dependency(ApplicationLogger())
    }
    #endif

    @MainActor
    static var isLoggingEnabled: Bool = false

    /// A recursive lock to ensure thread-safe access to shared resources within the Application instance.
    @ObservationIgnored
    let lock: NSRecursiveLock

    /// The underlying cache used to store all state and dependency values.
    @ObservationIgnored
    let cache: Cache<String, Any>

    /// Observation anchor that bridges cache changes to the Observation framework.
    ///
    /// State and dependency values live in the untracked ``cache``. Reading this anchor (via
    /// ``registerObservation()``) registers the current Observation tracking scope — e.g. a SwiftUI
    /// view body — as dependent on AppState, and mutating it (via ``notifyChange()``) tells those
    /// observers to update.
    ///
    /// Delivery is cross-platform: every AppState mutation path calls ``notifyChange()`` directly.
    /// There is no Combine/`ObservableObject` bridge involved in Observation delivery.
    ///
    /// Thread-safety: every mutation funnels through ``notifyChange()``, which AppState only invokes
    /// from its main-actor setters (and from `@MainActor` hooks such as
    /// ``didChangeExternally(notification:)``). Reads occur on the main actor (SwiftUI bodies and the
    /// `@MainActor` property wrappers). The mutation itself is applied through the synthesized
    /// `@Observable` registrar, which is `Sendable` and internally synchronized.
    private var changeAnchor: Int = 0

    /// Whether this instance is registered for the iCloud key-value store's external-change
    /// notification. `promote(to:)` reads it to register the promoted instance in its place.
    @ObservationIgnored
    var isObservingExternalChanges: Bool = false

    /// One live override of a dependency: what the dependency was before it.
    struct LiveDependencyOverride {
        let id: UUID
        var previous: Any
    }

    /// The live overrides of each dependency, oldest first, by the key of the dependency's scope.
    ///
    /// Overrides of one dependency can end in any order. Each remembers what it replaced, so the
    /// one that ends hands that on to the next newer override, and only the newest writes the cache.
    @ObservationIgnored
    var liveDependencyOverrides: [String: [LiveDependencyOverride]] = [:]

    /// Ends the override `id` of the dependency stored under `key`.
    ///
    /// The newest override puts back what it replaced. An older one leaves the dependency alone
    /// and passes what it replaced to the override that came after it.
    @MainActor
    func endDependencyOverride(id: UUID, key: String) {
        guard
            var overrides = liveDependencyOverrides[key],
            let index = overrides.firstIndex(where: { $0.id == id })
        else { return }

        let ended = overrides.remove(at: index)

        if index == overrides.count {
            cache.set(value: ended.previous, forKey: key)
        } else {
            overrides[index].previous = ended.previous
        }

        liveDependencyOverrides[key] = overrides.isEmpty ? nil : overrides
    }

    /// Keys of file states whose unreadable file has already been reported to
    /// ``didFailToPersist(_:)``. A view reads its state on every render, so without this an
    /// unreadable file would be reported on each one. A key leaves the set when that state is next
    /// read or written successfully.
    @ObservationIgnored
    var reportedReadFailures: Set<String> = []

    /// Initializes a new instance of `Application`.
    ///
    /// This initializer is used for the default `Application.shared` instance and any custom `Application` subclasses.
    /// You should typically not call this directly. To use a custom application subclass, call `Application.promote(to: CustomApplication.self)`
    /// early in your application's lifecycle.
    ///
    /// - Parameter setup: A closure that is called after the Application instance is initialized, allowing for custom setup logic.
    ///                  This can be used, for example, to register custom dependencies or perform initial state configuration.
    public required init(
        setup: (Application) -> Void = { _ in }
    ) {
        lock = NSRecursiveLock()
        cache = Cache()

        super.init()

        setup(self)
        loadDefaultDependencies()
    }

    /// Registers the current Observation tracking scope (such as a SwiftUI view body) as dependent on
    /// AppState. The property wrappers call this when reading their value so that SwiftUI views update
    /// when the underlying state or dependencies change.
    ///
    /// The discarded read of ``changeAnchor`` is intentional and load-bearing: the synthesized
    /// `@Observable` getter calls the observation registrar's `access`, which is what records the
    /// dependency. Do not remove it.
    func registerObservation() {
        _ = changeAnchor
    }

    /// Notifies observers (such as SwiftUI views) that an AppState value changed.
    ///
    /// AppState's own setters call this automatically. Call it yourself when you mutate state outside
    /// of those setters — for example from a `didChangeExternally(notification:)` override that reacts
    /// to incoming iCloud changes. See ``changeAnchor`` for the thread-safety invariant.
    ///
    /// - Important: This must be called on the main thread. SwiftUI tracks `changeAnchor` from view
    ///   bodies, so publishing a change from a background thread both races the mutation and trips the
    ///   "Publishing changes from background threads is not supported" runtime warning. `Application` is
    ///   not `Sendable`, so the change cannot be hopped to the main thread on the caller's behalf — the
    ///   invariant is instead asserted here so off-main misuse surfaces in debug and CI. `Application`'s
    ///   setters and the `@MainActor` `didChangeExternally(notification:)` override already satisfy it.
    ///
    ///   Callers must not wrap this in an unconditional `DispatchQueue.main.async` hop: asynchronous
    ///   delivery would break the synchronous `withObservationTracking` contract that AppState and
    ///   SwiftUI rely on when already on the main thread.
    public func notifyChange() {
        #if !os(WASI)
        assert(Thread.isMainThread, "Application.notifyChange() must be called on the main thread.")
        #endif

        changeAnchor &+= 1
    }

    /// Called when AppState could not read, write, or delete a persisted value.
    ///
    /// A ``FileState`` whose file cannot be decoded, written or deleted reports here, and so does a
    /// ``StoredState`` or `SyncState` value that cannot be encoded. A `FileState` that was never
    /// written is not a failure and is not reported.
    ///
    /// An unreadable file is reported once, not on every read. It is reported again only after
    /// that state has been read or written successfully in between. Every failed write or delete
    /// is reported.
    ///
    /// The default implementation does nothing. AppState logs the failure as before when logging is
    /// enabled, whether or not this method is overridden. Override it in an `Application` subclass
    /// that you install with ``promote(to:)`` to tell the user, retry, or record the error:
    ///
    /// ```swift
    /// final class MyApplication: Application {
    ///     override func didFailToPersist(_ failure: PersistenceFailure) {
    ///         analytics.record(failure.error, key: failure.key)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter failure: Which state failed, during which operation, and the underlying error.
    @MainActor
    open func didFailToPersist(_ failure: PersistenceFailure) {}

    #if canImport(Security)
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
        load(dependency: \.logger)
        load(dependency: \.userDefaults)
        load(dependency: \.fileManager)
    }
}
