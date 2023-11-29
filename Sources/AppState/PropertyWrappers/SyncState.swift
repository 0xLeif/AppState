import Foundation
import Combine
import SwiftUI

/**
`SyncState` is a property wrapper that allows SwiftUI views to subscribe to Application's state changes in a reactive way. The state is synchronized using `NSUbiquitousKeyValueStore`, and it works similarly to `State` and `Published`.

 Changes your app writes to the key-value store object are initially held in memory, then written to disk by the system at appropriate times. If you write to the key-value store object when the user is not signed into an iCloud account, the data is stored locally until the next synchronization opportunity. When the user signs into an iCloud account, the system automatically reconciles your local, on-disk keys and values with those on the iCloud server.

 The total amount of space available in your app’s key-value store, for a given user, is 1 MB. There is a per-key value size limit of 1 MB, and a maximum of 1024 keys. If you attempt to write data that exceeds these quotas, the write attempt fails and no change is made to your iCloud key-value storage. In this scenario, the system posts the didChangeExternallyNotification notification with a change reason of NSUbiquitousKeyValueStoreQuotaViolationChange.

 - Note: The key-value store is intended for storing data that changes infrequently. As you test your devices, if the app on a device makes frequent changes to the key-value store, the system may defer the synchronization of some changes in order to minimize the number of round trips to the server. The more frequently the app make changes, the more likely the changes will be deferred and will not immediately show up on the other devices.

 The maximum length for key strings for the iCloud key-value store is 64 bytes using UTF8 encoding. Attempting to write a value to a longer key name results in a runtime error.

 To use this class, you must distribute your app through the App Store or Mac App Store, and you must request the com.apple.developer.ubiquity-kvstore-identifier entitlement in your Xcode project.

 - Warning: Avoid using this class for data that is essential to your app’s behavior when offline; instead, store such data directly into the local user defaults database.
 */
@propertyWrapper public struct SyncState<Value: Codable>: DynamicProperty {
    /// Holds the singleton instance of `Application`.
    @ObservedObject private var app: Application = Application.shared

    /// Path for accessing `SyncState` from Application.
    private let keyPath: KeyPath<Application, Application.SyncState<Value>>

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int

    /// Represents the current value of the `SyncState`.
    public var wrappedValue: Value {
        get {
            Application.syncState(
                keyPath,
                fileID,
                function,
                line,
                column
            ).value
        }
        nonmutating set {
            Application.log(
                debug: "☁️ Setting SyncState \(String(describing: keyPath)) = \(newValue)",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            var state = app.value(keyPath: keyPath)
            state.value = newValue
        }
    }

    /// A binding to the `State`'s value, which can be used with SwiftUI views.
    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    /**
     Initializes the AppState with a `keyPath` for accessing `SyncState` in Application.

     - Parameter keyPath: The `KeyPath` for accessing `SyncState` in Application.
     */
    public init(
        _ keyPath: KeyPath<Application, Application.SyncState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        self.keyPath = keyPath
        self.fileID = fileID
        self.function = function
        self.line = line
        self.column = column
    }

    /// A property wrapper's synthetic storage property. This is just for SwiftUI to mutate the `wrappedValue` and send event through `objectWillChange` publisher when the `wrappedValue` changes
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            observed[keyPath: storageKeyPath].wrappedValue
        }
        set {
            guard
                let publisher = observed.objectWillChange as? ObservableObjectPublisher
            else { return }

            publisher.send()
            observed[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}
