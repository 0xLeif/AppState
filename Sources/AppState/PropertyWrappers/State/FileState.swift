import Foundation
#if !os(Linux) && !os(Windows)
import Combine
import SwiftUI
#endif

/// `FileState` is a property wrapper allowing SwiftUI views to subscribe to Application's state changes in a reactive way. State is stored using `FileManager`. Works similar to `State` and `Published`.
@propertyWrapper public struct FileState<Value: Codable> {
    #if !os(Linux) && !os(Windows)
    /// Holds the singleton instance of `Application`.
    @ObservedObject private var app: Application = Application.shared
    #else
    /// Holds the singleton instance of `Application`.
    private var app: Application = Application.shared
    #endif

    /// Path for accessing `FileState` from Application.
    private let keyPath: KeyPath<Application, Application.FileState<Value>>

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int

    /// Represents the current value of the `FileState`.
    public var wrappedValue: Value {
        get {
            Application.fileState(
                keyPath,
                fileID,
                function,
                line,
                column
            ).value
        }
        nonmutating set {
            Application.log(
                debug: "🗄️ Setting FileState \(String(describing: keyPath)) = \(newValue)",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            var state = app.value(keyPath: keyPath)
            state.value = newValue
        }
    }

    #if !os(Linux) && !os(Windows)
    /// A binding to the `State`'s value, which can be used with SwiftUI views.
    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    #endif

    /**
     Initializes the AppState with a `keyPath` for accessing `FileState` in Application.

     - Parameter keyPath: The `KeyPath` for accessing `FileState` in Application.
     */
    public init(
        _ keyPath: KeyPath<Application, Application.FileState<Value>>,
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

    #if !os(Linux) && !os(Windows)
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
    #endif
}

#if !os(Linux) && !os(Windows)
extension FileState: DynamicProperty { }
#endif
