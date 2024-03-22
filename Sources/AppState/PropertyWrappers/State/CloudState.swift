#if !os(Linux) && !os(Windows)
import Foundation
import Combine
import SwiftUI

/**

 */
@available(watchOS 9.0, *)
@propertyWrapper public struct CloudState<Value: Codable & Equatable>: DynamicProperty {
    /// Holds the singleton instance of `Application`.
    @ObservedObject private var app: Application = Application.shared

    /// Path for accessing `CloudState` from Application.
    private let keyPath: KeyPath<Application, Application.CloudState<Value>>

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int

    /// Represents the current value of the `CloudState`.
    public var wrappedValue: Value {
        get {
            Application.cloudState(
                keyPath,
                fileID,
                function,
                line,
                column
            ).value
        }
        nonmutating set {
            Application.log(
                debug: "☁️ Setting CloudState \(String(describing: keyPath)) = \(newValue)",
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
     Initializes the AppState with a `keyPath` for accessing `CloudState` in Application.

     - Parameter keyPath: The `KeyPath` for accessing `CloudState` in Application.
     */
    public init(
        _ keyPath: KeyPath<Application, Application.CloudState<Value>>,
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
#endif
