import Combine
import SwiftUI

/// `AppState` is a property wrapper allowing SwiftUI views to subscribe to Application's state changes in a reactive way. Works similar to `State` and `Published`.
@propertyWrapper public struct AppState<Value>: DynamicProperty {
    /// Holds the singleton instance of `Application`.
    @ObservedObject private var app: Application = Application.shared

    /// Path for accessing `State` from Application.
    private let keyPath: KeyPath<Application, Application.State<Value>>

    /// Represents the current value of the `State`.
    public var wrappedValue: Value {
        get {
            app.value(keyPath: keyPath).value
        }
        nonmutating set {
            let key = app.value(keyPath: keyPath).scope.key

            app.cache.set(
                value: newValue,
                forKey: key
            )
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
     Initializes the AppState with a `keyPath` for accessing `State` in Application.

     - Parameter keyPath: The `KeyPath` for accessing `State` in Application.
     */
    public init(
        _ keyPath: KeyPath<Application, Application.State<Value>>
    ) {
        self.keyPath = keyPath
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
