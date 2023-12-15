import Foundation
import Combine
import SwiftUI

/**
 A property wrapper struct that represents secure and persistent storage for a wrapped value.

 The value is kept in the `Application`'s secure state and managed by SwiftUI's property wrapper mechanism.
 As a `DynamicProperty`, SwiftUI will update the owning view whenever the value changes.
 */
@propertyWrapper public struct SecureState: DynamicProperty {
    /// Holds the singleton instance of `Application`.
    @ObservedObject private var app: Application = Application.shared

    /// Path for accessing `SecureState` from Application.
    private let keyPath: KeyPath<Application, Application.SecureState>

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int
    
    /**
     The current value of the secure state.
     
     Reading this property returns the current value.
     Writing to the property will update the underlying value in the secure state and log the operation.
     */
    public var wrappedValue: String? {
        get {
            Application.secureState(
                keyPath,
                fileID,
                function,
                line,
                column
            ).value
        }
        nonmutating set {
            let debugMessage: String

            #if DEBUG
            debugMessage = "🔑 Setting SecureState \(String(describing: keyPath)) = \(String(describing: newValue))"
            #else
            debugMessage = "🔑 Setting SecureState \(String(describing: keyPath))"
            #endif

            Application.log(
                debug: debugMessage,
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
    public var projectedValue: Binding<String?> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    /**
     Initializes the AppState with a `keyPath` for accessing `SecureState` in Application.

     - Parameter keyPath: The `KeyPath` for accessing `SecureState` in Application.
     */
    public init(
        _ keyPath: KeyPath<Application, Application.SecureState>,
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
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, String?>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> String? {
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
