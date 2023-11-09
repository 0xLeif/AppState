import Foundation
import Combine
import SwiftUI

/// `StoredState` is a property wrapper allowing SwiftUI views to subscribe to Application's state changes in a reactive way. State is stored using `UserDefaults`. Works similar to `State` and `Published`.
@propertyWrapper public struct StoredState<Value>: DynamicProperty {
    /// Holds the singleton instance of `Application`.
    @ObservedObject private var app: Application = Application.shared

    /// Path for accessing `StoredState` from Application.
    private let keyPath: KeyPath<Application, Application.StoredState<Value>>

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int

    /// Represents the current value of the `StoredState`.
    public var wrappedValue: Value {
        get {
            Application.storedState(
                keyPath,
                fileID,
                function,
                line,
                column
            ).value
        }
        nonmutating set {
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
     Initializes the AppState with a `keyPath` for accessing `StoredState` in Application.

     - Parameter keyPath: The `KeyPath` for accessing `StoredState` in Application.
     */
    public init(
        _ keyPath: KeyPath<Application, Application.StoredState<Value>>,
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
