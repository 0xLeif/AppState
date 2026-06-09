#if canImport(SwiftData)
import Combine
import SwiftData
import SwiftUI

/// `ModelState` is a property wrapper that exposes a collection of SwiftData `@Model` objects from
/// the `Application`'s scope. The models are read from and written to a `ModelContainer` dependency.
///
/// Reading the wrapped value performs a fetch using the state's `FetchDescriptor`. Assigning to the
/// wrapped value inserts any new (not yet persisted) models and saves the backing context. For
/// explicit control over inserts and deletes, use the projected value, which exposes the underlying
/// ``Application/ModelState`` and its ``Application/ModelState/insert(_:)``,
/// ``Application/ModelState/delete(_:)``, and ``Application/ModelState/save()`` methods.
///
/// - Note: Mutations made through `ModelState` are not automatically broadcast to SwiftUI. For
///   reactive views, use SwiftData's `@Query` together with the AppState-provided `ModelContainer`.
///   `ModelState` is best suited to view models, services, and other non-view code.
@propertyWrapper public struct ModelState<Model: PersistentModel> {
    /// The shared `Application` instance backing this state.
    @MainActor
    private var app: Application { Application.shared }

    /// Path for accessing `ModelState` from Application.
    private let keyPath: KeyPath<Application, Application.ModelState<Model>>

    private let fileID: StaticString
    private let function: StaticString
    private let line: Int
    private let column: Int

    /// The models currently matching this state's `FetchDescriptor`.
    @MainActor
    public var wrappedValue: [Model] {
        get {
            app.registerObservation()

            return Application.modelState(
                keyPath,
                fileID,
                function,
                line,
                column
            ).value
        }
        nonmutating set {
            Application.log(
                debug: "🗃️ Setting ModelState \(String(describing: keyPath))",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            var state = app.value(keyPath: keyPath)
            state.value = newValue
        }
    }

    /// The underlying ``Application/ModelState``, exposing `insert`, `delete`, and `save`.
    @MainActor
    public var projectedValue: Application.ModelState<Model> {
        Application.modelState(
            keyPath,
            fileID,
            function,
            line,
            column
        )
    }

    /**
     Initializes the ModelState with a `keyPath` for accessing `ModelState` in Application.

     - Parameter keyPath: The `KeyPath` for accessing `ModelState` in Application.
     */
    @MainActor
    public init(
        _ keyPath: KeyPath<Application, Application.ModelState<Model>>,
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
    @MainActor
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, [Model]>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> [Model] {
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

extension ModelState: DynamicProperty { }
#endif
