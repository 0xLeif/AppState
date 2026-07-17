#if canImport(Combine)
import Combine
import SwiftUI
#endif

/// `AppState` is a property wrapper allowing SwiftUI views to subscribe to Application's state changes in a reactive way. Works similar to `State` and `Published`.
@propertyWrapper public struct AppState<Value, ApplicationState: MutableApplicationState> where ApplicationState.Value == Value {
    /// The shared `Application` instance backing this state.
    @MainActor
    private var app: Application { Application.shared }

    /// Path for accessing `State` from Application.
    private let keyPath: KeyPath<Application, ApplicationState>

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int

    /// Represents the current value of the `State`.
    @MainActor
    public var wrappedValue: Value {
        get {
            // `Application.state(_:)` registers the current Observation scope, so reading through it
            // is enough — no separate `registerObservation()` call is needed here.
            Application.state(
                keyPath,
                fileID,
                function,
                line,
                column
            ).value
        }
        nonmutating set {
            Application.log(
                debug: "\(ApplicationState.emoji) Setting State \(String(describing: keyPath)) = \(newValue)",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
            
            var state = app.value(keyPath: keyPath)
            state.value = newValue
        }
    }

    #if canImport(Combine)
    /// A binding to the `State`'s value, which can be used with SwiftUI views.
    @MainActor
    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    #endif

    /**
     Initializes the AppState with a `keyPath` for accessing `State` in Application.

     - Parameter keyPath: The `KeyPath` for accessing `State` in Application.
     */
    @MainActor
    public init(
        _ keyPath: KeyPath<Application, ApplicationState>,
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

    #if canImport(Combine)
    /// A property wrapper's synthetic storage property. This is just for SwiftUI to mutate the `wrappedValue` and send event through `objectWillChange` publisher when the `wrappedValue` changes
    @MainActor
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
    #endif
}

#if canImport(Combine)
extension AppState: DynamicProperty { }
#endif
