import Combine
import SwiftUI

@propertyWrapper public struct Slice<SlicedState: MutableCachedApplicationValue, Value, SliceValue>: DynamicProperty where SlicedState.Value == Value {
    /// Holds the singleton instance of `Application`.
    @ObservedObject private var app: Application = Application.shared

    /// Path for accessing `State` from Application.
    private let stateKeyPath: KeyPath<Application, SlicedState>

    /// Path for accessing `SliceValue` from `Value`.
    private let valueKeyPath: WritableKeyPath<Value, SliceValue>

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int
    private let sliceKeyPath: String

    /// Represents the current value of the `State`.
    public var wrappedValue: SliceValue {
        get {
            Application.slice(
                stateKeyPath,
                valueKeyPath,
                fileID,
                function,
                line,
                column
            ).value
        }
        nonmutating set {
            Application.log(
                debug: "🍕 Setting Slice \(sliceKeyPath) = \(newValue)",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            var state = app.value(keyPath: stateKeyPath)
            state.value[keyPath: valueKeyPath] = newValue
        }
    }

    /// A binding to the `State`'s value, which can be used with SwiftUI views.
    public var projectedValue: Binding<SliceValue> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    public init(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        self.stateKeyPath = stateKeyPath
        self.valueKeyPath = valueKeyPath
        self.fileID = fileID
        self.function = function
        self.line = line
        self.column = column

        let stateKeyPathString = String(describing: stateKeyPath)
        let valueTypeCharacterCount = String(describing: Value.self).count
        var valueKeyPathString = String(describing: valueKeyPath)

        valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

        self.sliceKeyPath = "\(stateKeyPathString)\(valueKeyPathString)"
    }

    /// A property wrapper's synthetic storage property. This is just for SwiftUI to mutate the `wrappedValue` and send event through `objectWillChange` publisher when the `wrappedValue` changes
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, SliceValue>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> SliceValue {
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
