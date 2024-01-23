#if !os(Linux) && !os(Windows)
import Combine
import SwiftUI
#endif

/// A property wrapper that provides access to a specific part of the AppState's state that is optional.
@propertyWrapper public struct OptionalSlice<SlicedState: MutableApplicationState, Value, SliceValue> where SlicedState.Value == Value? {
    #if !os(Linux) && !os(Windows)
    /// Holds the singleton instance of `Application`.
    @ObservedObject private var app: Application = Application.shared
    #else
    /// Holds the singleton instance of `Application`.
    private var app: Application = Application.shared
    #endif

    /// Path for accessing `State` from Application.
    private let stateKeyPath: KeyPath<Application, SlicedState>

    /// Path for accessing `SliceValue` from `Value`.
    private let valueKeyPath: WritableKeyPath<Value, SliceValue>?

    /// Path for accessing `SliceValue?` from `Value`.
    private let optionalValueKeyPath: WritableKeyPath<Value, SliceValue?>?

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int
    private let sliceKeyPath: String

    /// Represents the current value of the `State`.
    public var wrappedValue: SliceValue? {
        get {
            if let valueKeyPath {
                return Application.slice(
                    stateKeyPath,
                    valueKeyPath,
                    fileID,
                    function,
                    line,
                    column
                ).value
            }

            guard 
                let optionalValueKeyPath,
                let slicedValue = Application.slice(
                    stateKeyPath,
                    optionalValueKeyPath,
                    fileID,
                    function,
                    line,
                    column
                ).value
            else {
                return nil
            }

            return slicedValue
        }
        nonmutating set {
            Application.log(
                debug: {
                    if let newValue {
                        return "🍕 Setting Slice \(sliceKeyPath) = \(newValue)"
                    } else {
                        return "🍕 Setting Slice \(sliceKeyPath) = nil"
                    }
                },
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            var state = app.value(keyPath: stateKeyPath)

            guard 
                let valueKeyPath,
                let newValue
            else {
                if let optionalValueKeyPath {
                    state.value?[keyPath: optionalValueKeyPath] = newValue
                }

                return
            }

            state.value?[keyPath: valueKeyPath] = newValue
        }
    }

    #if !os(Linux) && !os(Windows)
    /// A binding to the `State`'s value, which can be used with SwiftUI views.
    public var projectedValue: Binding<SliceValue?> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    #endif

    /**
     Initializes a Slice with the provided parameters. This constructor is used to create a Slice that provides access and modification to a specific part of an AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath that points to the state in AppState that should be sliced.
         - valueKeyPath: A WritableKeyPath that points to the specific part of the state that should be accessed.
     */
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
        self.optionalValueKeyPath = nil
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

    /**
     Initializes a Slice with the provided parameters. This constructor is used to create a Slice that provides access and modification to a specific part of an AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath that points to the state in AppState that should be sliced.
         - valueKeyPath: A WritableKeyPath that points to the specific part of the state that should be accessed. Must be Optional.
     */
    public init(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ optionalValueKeyPath: WritableKeyPath<Value, SliceValue?>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        self.stateKeyPath = stateKeyPath
        self.valueKeyPath = nil
        self.optionalValueKeyPath = optionalValueKeyPath
        self.fileID = fileID
        self.function = function
        self.line = line
        self.column = column

        let stateKeyPathString = String(describing: stateKeyPath)
        let valueTypeCharacterCount = String(describing: Value.self).count
        var valueKeyPathString = String(describing: valueKeyPath ?? optionalValueKeyPath)

        valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

        self.sliceKeyPath = "\(stateKeyPathString)\(valueKeyPathString)"
    }

    #if !os(Linux) && !os(Windows)
    /// A property wrapper's synthetic storage property. This is just for SwiftUI to mutate the `wrappedValue` and send event through `objectWillChange` publisher when the `wrappedValue` changes
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, SliceValue?>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> SliceValue? {
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
extension OptionalSlice: DynamicProperty { }
#endif
