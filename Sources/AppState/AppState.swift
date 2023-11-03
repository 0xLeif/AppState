import Combine
import SwiftUI

@propertyWrapper public struct AppState<Value>: DynamicProperty {
    @ObservedObject private var app: Application = Application.shared

    private let keyPath: KeyPath<Application, Application.State<Value>>

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

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    public init(
        _ keyPath: KeyPath<Application, Application.State<Value>>
    ) {
        self.keyPath = keyPath
    }

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
