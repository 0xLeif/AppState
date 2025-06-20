import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif

// MARK: Application Functions

public extension Application {
    /// Provides a description of the current application state
    @MainActor
    static var description: String {
       """
       {
       \(cacheDescription)
       }
       """
    }

    /**
     This static function promotes the shared singleton instance of the Application class to a custom Application type.

     - Parameters:
        - customApplication: A custom Application subclass to be promoted to.

     - Returns: The type of the custom Application subclass.

     This function is particularly useful when your Application subclass needs to override the `didChangeExternally(notification:)` function. It allows you to extend the functionalities of the Application class and use your custom Application type throughout your application.

     Example:
     ```swift
     class CustomApplication: Application {
         override func didChangeExternally(notification: Notification) {
             super.didChangeExternally(notification: notification)

             // Update UI
             // ...

             // Example updating an ObservableObject that has SyncState inside of it.
             DispatchQueue.main.async {
                 Application.dependency(\.userSettings).objectWillChange.send()
             }

             // Example updating all SyncState in SwiftUI Views.
             DispatchQueue.main.async {
                 self.objectWillChange.send()
             }
         }
     }
     ```

     To use the `promote` function to promote the shared singleton to `CustomApplication`:

     ```swift
     Application.promote(to: CustomApplication.self)
     ```

     In this way, your custom Application subclass becomes the shared singleton instance, which you can then use throughout your application.
     */
    @MainActor
    @discardableResult
    static func promote<CustomApplication: Application>(
        to customApplication: CustomApplication.Type
    ) -> CustomApplication.Type {
        NotificationCenter.default.removeObserver(shared)

        let cache = shared.cache
        shared = customApplication.init()
        customApplication.shared = shared

        for (key, value) in cache.allValues {
            shared.cache.set(value: value, forKey: key)
            cache.remove(key)
        }

        return CustomApplication.self
    }

    /// Enables or disabled the default logging inside of Application.
    @MainActor
    @discardableResult
    static func logging(isEnabled: Bool) -> Application.Type {
        Application.isLoggingEnabled = isEnabled

        return Application.self
    }
}

// MARK: - Dependency Functions

public extension Application {
    /**
     Use this function to make sure Dependencies are intialized. If a Dependency is not loaded, it will be initialized whenever it is used next.

     - Parameter dependency: KeyPath of the Dependency to be loaded
     - Returns: `Application.self` to allow chaining.
     */
    @MainActor
    @discardableResult
    static func load<Value>(
        dependency keyPath: KeyPath<Application, Dependency<Value>>
    ) -> Application.Type {
        shared.load(dependency: keyPath)

        return Application.self
    }

    /**
     Retrieves a state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the Dependency to be fetched
     - Returns: The requested state of type `Value`.
     */
    @MainActor
    static func dependency<Value>(
        _ keyPath: KeyPath<Application, Dependency<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Value {
        log(
            debug: "🔗 Getting Dependency \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return shared.value(keyPath: keyPath).value
    }

    /**
     Overrides the specified `Dependency` with the given value. This is particularly useful for SwiftUI Previews and Unit Tests.
     - Parameters:
        - keyPath: Key path of the dependency to be overridden.
        - value: The new value to override the current dependency.

     - Returns: A `DependencyOverride` object. You should retain this token for as long as you want your override to be effective. Once the token is deallocated or the `cancel()` method is called on it, the original dependency is restored.

     Note: If the `DependencyOverride` object gets deallocated without calling `cancel()`, it will automatically cancel the override, restoring the original dependency.
     */
    @MainActor
    static func `override`<Value>(
        _ keyPath: KeyPath<Application, Dependency<Value>>,
        with value: Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> DependencyOverride {
        let dependency = shared.value(keyPath: keyPath)

        log(
            debug: "🔗 Starting Dependency Override \(String(describing: keyPath)) with \(value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        shared.cache.set(
            value: Dependency(value, scope: dependency.scope),
            forKey: dependency.scope.key
        )

        let keyPath = String(describing: keyPath)

        return DependencyOverride {
            await log(
                debug: "🔗 Cancelling Dependency Override \(keyPath) ",
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )

            await MainActor.run {
                shared.cache.set(
                    value: dependency,
                    forKey: dependency.scope.key
                )
            }
        }
    }

    /**
     Promotes the specified `Dependency` with the given value.
     - Parameters:
        - keyPath: Key path of the dependency to be promoted.
        - value: The new value to promote the current dependency.

     - Returns: `Application.self` to allow chaining.

     Note: There is no way to undo the promotion other than re-promoting a dependency. It is advised you use `override` if you ever need to undo the change.
     */
    @MainActor
    @discardableResult
    static func promote<CustomDependency>(
        _ keyPath: KeyPath<Application, Dependency<CustomDependency>>,
        with value: CustomDependency,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Application.Type {
        let promotionOverride = override(
            keyPath,
            with: value,
            fileID,
            function,
            line,
            column
        )

        var promotions = Application.state(\.dependencyPromotions)
        promotions.value.append(promotionOverride)

        return Application.self
    }

    /**
     Retrieves a dependency for the provided `id`. If dependency is not present, it is created once using the provided closure.

     - Parameters:
        - object: The closure returning the dependency.
        - feature: The name of the feature to which the dependency belongs, default is "App".
        - id: The specific identifier for this dependency.
     - Returns: The requested dependency of type `Dependency<Value>`.
     */
    func dependency<Value>(
        _ object: () -> Value,
        feature: String = "App",
        id: String
    ) -> Dependency<Value> {
        let scope = Scope(name: feature, id: id)
        let key = scope.key

        guard let dependency = cache.get(key, as: Dependency<Value>.self) else {
            let value = object()
            let dependency = Dependency(
                value,
                scope: scope
            )

            cache.set(value: dependency, forKey: key)

            return dependency
        }

        return dependency
    }

    /// Overloaded version of `dependency(_:feature:id:)` function where id is generated from the code context.
    func dependency<Value>(
        setup: () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Dependency<Value> {
        dependency(
            setup,
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }

    /**
     Retrieves a dependency for the provided `id`. If dependency is not present, it is created once using the provided closure.

     - Parameters:
        - object: The closure returning the dependency.
        - feature: The name of the feature to which the dependency belongs, default is "App".
        - id: The specific identifier for this dependency.
     - Returns: The requested dependency of type `Dependency<Value>`.
     */
    func dependency<Value>(
        _ object: @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> Dependency<Value> {
        dependency(object, feature: feature, id: id)
    }


    /// Overloaded version of `dependency(_:feature:id:)` function where id is generated from the code context.
    func dependency<Value>(
        _ object: @autoclosure () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Dependency<Value> {
        dependency(
            object(),
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }
}

#if !os(Linux) && !os(Windows)
// MARK: - SwiftUI Preview Dependency Functions

public extension Application {
    /**
    Use in SwiftUI previews to inject mock dependencies into the content view.

     - Parameters:
        - dependencyOverrides: An array of `Application.override(_, with:)` outputs that you want to use for the preview.
        - content: A closure that returns the View you want to preview.

     - Returns: A View with the overridden dependencies applied.
     */
    @MainActor
    @ViewBuilder
    static func preview<Content: View>(
        _ dependencyOverrides: DependencyOverride...,
        content: @escaping () -> Content
    ) -> some View {
        ApplicationPreview(
            dependencyOverrides: dependencyOverrides,
            content: content
        )
    }
}
#endif

// MARK: - State Functions

public extension Application {
    /**
     Retrieves a state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
    @MainActor
    static func state<Value, ApplicationState: MutableApplicationState>(
        _ keyPath: KeyPath<Application, ApplicationState>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> ApplicationState where ApplicationState.Value == Value {
        let appState = shared.value(keyPath: keyPath)

        log(
            debug: "\(ApplicationState.emoji) Getting State \(String(describing: keyPath)) -> \(appState.value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return appState
    }

    /**
     Retrieves a state for the provided `id`. If the state is not present, it initializes a new state with the `initial` value.

     - Parameters:
        - initial: The closure that returns initial state value.
        - feature: The name of the feature to which the state belongs, default is "App".
        - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
     */
    func state<Value>(
        initial: @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> State<Value> {
        State(
            type: .state,
            initial: initial(),
            scope: Scope(name: feature, id: id)
        )
    }

    /// Overloaded version of `state(initial:feature:id:)` function where id is generated from the code context.
    func state<Value>(
        initial: @autoclosure () -> Value,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> State<Value> {
        state(
            initial: initial(),
            id: Application.codeID(
                fileID: fileID,
                function: function,
                line: line,
                column: column
            )
        )
    }
}

// MARK: - StoredState Functions

public extension Application {
    /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `UserDefaults`
    @MainActor
    static func reset<Value>(
        storedState keyPath: KeyPath<Application, StoredState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        log(
            debug: "💾 Resetting StoredState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var storedState = shared.value(keyPath: keyPath)
        storedState.reset()
    }

    /**
     Retrieves a stored state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
    @MainActor
    static func storedState<Value>(
        _ keyPath: KeyPath<Application, StoredState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> StoredState<Value> {
        let storedState = shared.value(keyPath: keyPath)

        log(
            debug: "💾 Getting StoredState \(String(describing: keyPath)) -> \(storedState.value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return storedState
    }

    /**
     Retrieves a `UserDefaults` backed state for the provided `id`. If the state is not present, it initializes a new state with the `initial` value.

     - Parameters:
        - initial: The closure that returns initial state value.
        - feature: The name of the feature to which the state belongs, default is "App".
        - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
     */
    func storedState<Value>(
        initial: @escaping @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> StoredState<Value> {
        StoredState(
            initial: initial(),
            scope: Scope(name: feature, id: id)
        )
    }

    /**
     Retrieves a `UserDefaults` backed state for the provided `id` with a default value of `nil`.

     - Parameters:
        - feature: The name of the feature to which the state belongs, default is "App".
        - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
     */
    func storedState<Value>(
        feature: String = "App",
        id: String
    ) -> StoredState<Value?> {
        storedState(
            initial: nil,
            feature: feature,
            id: id
        )
    }
}

#if !os(Linux) && !os(Windows)
// MARK: - SyncState Functions

@available(watchOS 9.0, *)
public extension Application {
    /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `iCloud`
    @MainActor
    static func reset<Value>(
        syncState keyPath: KeyPath<Application, SyncState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        log(
            debug: "☁️ Resetting SyncState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var syncState = shared.value(keyPath: keyPath)
        syncState.reset()
    }

    /**
     Retrieves a state backed by iCloud from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
    @MainActor
    static func syncState<Value: Codable & Sendable>(
        _ keyPath: KeyPath<Application, SyncState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> SyncState<Value> {
        let storedState = shared.value(keyPath: keyPath)

        log(
            debug: "☁️ Getting SyncState \(String(describing: keyPath)) -> \(storedState.value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return storedState
    }

    /**
     Retrieves an `iCloud` backed state for the provided `id`. If the state is not present, it initializes a new state with the `initial` value.

     - Parameters:
        - initial: The closure that returns initial state value.
        - feature: The name of the feature to which the state belongs, default is "App".
        - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
     */
    func syncState<Value: Codable & Sendable>(
        initial: @escaping @autoclosure () -> Value,
        feature: String = "App",
        id: String
    ) -> SyncState<Value> {
        SyncState(
            initial: initial(),
            scope: Scope(name: feature, id: id)
        )
    }

    /**
     Retrieves an `iCloud` backed state for the provided `id` with a default value of `nil`.

     - Parameters:
        - feature: The name of the feature to which the state belongs, default is "App".
        - id: The specific identifier for this state.
     - Returns: The state of type `Value`.
     */
    func syncState<Value: Codable & Sendable>(
        feature: String = "App",
        id: String
    ) -> SyncState<Value?> {
        syncState(
            initial: nil,
            feature: feature,
            id: id
        )
    }
}

// MARK: - SecureState Functions

public extension Application {
    /**
     Resets a specific SecureState of the application.

     - Parameters:
        - keyPath: A key path of the SecureState to be reset.
     */
    @MainActor
    static func reset(
        secureState keyPath: KeyPath<Application, SecureState>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        log(
            debug: "🔑 Resetting SecureState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var secureState = shared.value(keyPath: keyPath)
        secureState.reset()
    }

    /**
     Fetches a specific SecureState of the application.

     - Parameters:
        - keyPath: A key path of the SecureState to be fetched.

     - Returns: The SecureState at provided keyPath.
     */
    @MainActor
    static func secureState(
        _ keyPath: KeyPath<Application, SecureState>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> SecureState {
        let secureState = shared.value(keyPath: keyPath)

        log(
            debug: {
                #if DEBUG
                "🔑 Getting SecureState \(String(describing: keyPath)) -> \(secureState.value ?? "nil")"
                #else
                "🔑 Getting SecureState \(String(describing: keyPath))"
                #endif
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return secureState
    }

    /**
     Creates a SecureState with an initial value.

     - Parameters:
        - initial: The initial value for the SecureState (delivered lazily and autoclosed).
        - feature: The name of the feature for scoping. Default is "App".
        - id: The unique identifier for the SecureState.

     - Returns: Initialized SecureState.
    */
    func secureState(
        initial: @escaping @autoclosure () -> String?,
        feature: String = "App",
        id: String
    ) -> SecureState {
        SecureState(
            initial: initial(),
            scope: Scope(name: feature, id: id)
        )
    }

    /**
     Creates a SecureState without an initial value.

     - Parameters:
        - feature: The name of the feature for scoping. Default is "App".
        - id: The unique identifier for the SecureState.

     - Returns: Initialized SecureState with nil as initial value.
     */
    func secureState(
        feature: String = "App",
        id: String
    ) -> SecureState {
        secureState(
            initial: nil,
            feature: feature,
            id: id
        )
    }
}
#endif

// MARK: - Slice Functions

extension Application {
    /**
     This function creates a `Slice` of AppState that allows access to a specific part of the AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath pointing to the state in AppState that should be sliced.
         - valueKeyPath: A KeyPath pointing to the specific part of the state that should be accessed.
         - fileID: The identifier of the file.
         - function: The name of the declaration.
         - line: The line number on which it appears.
         - column: The column number in which it begins.

     - Returns: A Slice that allows access to a specific part of an AppState's state.
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: KeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Slice<SlicedState, Value, SliceValue, KeyPath<Value, SliceValue>> where SlicedState.Value == Value {
        let slice = Slice(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     This function creates a `Slice` of AppState that allows access and modification to a specific part of the AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath pointing to the state in AppState that should be sliced.
         - valueKeyPath: A WritableKeyPath pointing to the specific part of the state that should be accessed.
         - fileID: The identifier of the file.
         - function: The name of the declaration.
         - line: The line number on which it appears.
         - column: The column number in which it begins.

     - Returns: A Slice that allows access and modification to a specific part of an AppState's state.
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> Slice<SlicedState, Value, SliceValue, WritableKeyPath<Value, SliceValue>> where SlicedState.Value == Value {
        let slice = Slice(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     This function creates a `OptionalSlice` of AppState that allows access to a specific part of the AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath pointing to the state in AppState that should be sliced.
         - valueKeyPath: A KeyPath pointing to the specific part of the state that should be accessed.
         - fileID: The identifier of the file.
         - function: The name of the declaration.
         - line: The line number on which it appears.
         - column: The column number in which it begins.

     - Returns: A Slice that allows access to a specific part of an AppState's state.
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: KeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> OptionalSlice<SlicedState, Value, SliceValue, KeyPath<Value, SliceValue>> where SlicedState.Value == Value? {
        let slice = OptionalSlice(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                if let value = slice.value {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(value)"
                } else {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> nil"
                }
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     This function creates a `OptionalSlice` of AppState that allows access and modification to a specific part of the AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath pointing to the state in AppState that should be sliced.
         - valueKeyPath: A WritableKeyPath pointing to the specific part of the state that should be accessed.
         - fileID: The identifier of the file.
         - function: The name of the declaration.
         - line: The line number on which it appears.
         - column: The column number in which it begins.

     - Returns: A Slice that allows access and modification to a specific part of an AppState's state.
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> OptionalSlice<SlicedState, Value, SliceValue, WritableKeyPath<Value, SliceValue>> where SlicedState.Value == Value? {
        let slice = OptionalSlice(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                if let value = slice.value {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(value)"
                } else {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> nil"
                }
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     This function creates a `OptionalSliceOptionalValue` of AppState that allows access and modification to a specific part of the AppState's state. It provides granular control over the AppState.

     - Parameters:
         - stateKeyPath: A KeyPath pointing to the state in AppState that should be sliced.
         - valueKeyPath: A WritableKeyPath pointing to the specific part of the state that should be accessed.
         - fileID: The identifier of the file.
         - function: The name of the declaration.
         - line: The line number on which it appears.
         - column: The column number in which it begins.

     - Returns: A Slice that allows access and modification to a specific part of an AppState's state.
     */
    @MainActor
    public static func slice<SlicedState: MutableApplicationState, Value, SliceValue>(
        _ stateKeyPath: KeyPath<Application, SlicedState>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue?>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> OptionalSliceOptionalValue<SlicedState, Value, SliceValue, WritableKeyPath<Value, SliceValue?>> where SlicedState.Value == Value? {
        let slice = OptionalSliceOptionalValue(
            stateKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let stateKeyPathString = String(describing: stateKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                if let value = slice.value {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> \(value)"
                } else {
                    return "🍕 Getting Slice \(stateKeyPathString)\(valueKeyPathString) -> nil"
                }
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }
}

// MARK: - DependencySlice Functions

extension Application {
    /**
     This function creates a `DependencySlice` of AppState that allows access to a specific part of the AppState's dependencies. It provides granular control over the AppState.

     - Parameters:
         - dependencyKeyPath: A KeyPath pointing to the dependency in AppState that should be sliced.
         - valueKeyPath: A KeyPath pointing to the specific part of the state that should be accessed.
         - fileID: The identifier of the file.
         - function: The name of the declaration.
         - line: The line number on which it appears.
         - column: The column number in which it begins.

     - Returns: A Slice that allows access to a specific part of an AppState's state.
     */
    @MainActor
    public static func dependencySlice<Value, SliceValue>(
        _ dependencyKeyPath: KeyPath<Application, Dependency<Value>>,
        _ valueKeyPath: KeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> DependencySlice<Value, SliceValue, KeyPath<Value, SliceValue>> {
        let slice = DependencySlice(
            dependencyKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let dependencyKeyPathString = String(describing: dependencyKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🔗 Getting DependencySlice \(dependencyKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }

    /**
     This function creates a `DependencySlice` of AppState that allows access to a specific part of the AppState's dependencies. It provides granular control over the AppState.

     - Parameters:
         - dependencyKeyPath: A KeyPath pointing to the dependency in AppState that should be sliced.
         - valueKeyPath: A KeyPath pointing to the specific part of the state that should be accessed.
         - fileID: The identifier of the file.
         - function: The name of the declaration.
         - line: The line number on which it appears.
         - column: The column number in which it begins.

     - Returns: A Slice that allows access to a specific part of an AppState's state.
     */
    @MainActor
    public static func dependencySlice<Value, SliceValue>(
        _ dependencyKeyPath: KeyPath<Application, Dependency<Value>>,
        _ valueKeyPath: WritableKeyPath<Value, SliceValue>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> DependencySlice<Value, SliceValue, WritableKeyPath<Value, SliceValue>> {
        let slice = DependencySlice(
            dependencyKeyPath,
            value: valueKeyPath
        )

        log(
            debug: {
                let dependencyKeyPathString = String(describing: dependencyKeyPath)
                let valueTypeCharacterCount = String(describing: Value.self).count
                var valueKeyPathString = String(describing: valueKeyPath)

                valueKeyPathString.removeFirst(valueTypeCharacterCount + 1)

                return "🔗 Getting DependencySlice \(dependencyKeyPathString)\(valueKeyPathString) -> \(slice.value)"
            },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return slice
    }
}

// MARK: - FileState Functions

public extension Application {
    /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `FileManager`
    @MainActor
    static func reset<Value>(
        fileState keyPath: KeyPath<Application, FileState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        log(
            debug: "🗄️ Resetting FileState \(String(describing: keyPath))",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        var fileState = shared.value(keyPath: keyPath)
        fileState.reset()
    }

    /**
     Retrieves a stored state from Application instance using the provided keypath.

     - Parameter keyPath: KeyPath of the state value to be fetched
     - Returns: The requested state of type `Value`.
     */
    @MainActor
    static func fileState<Value>(
        _ keyPath: KeyPath<Application, FileState<Value>>,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) -> FileState<Value> {
        let fileState = shared.value(keyPath: keyPath)

        log(
            debug: "🗄️ Getting FileState \(String(describing: keyPath)) -> \(fileState.value)",
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )

        return fileState
    }

    /**
     Retrieves a `FileManager` backed state for the provided `path` and `filename`. If the state is not present, it initializes a new state with the `initial` value.

     - Parameters:
        - initial: The closure that returns initial state value.
        - path: The path to the directory containing the file. The default is `FileManager.defaultFileStatePath`.
        - filename: The name of the file to read.
        - isBase64Encoded: Boolean to determine if the value should be encoded as Base64. The default is `true`.
     - Returns: The state of type `Value`.
     */
    @MainActor
    func fileState<Value>(
        initial: @escaping @autoclosure () -> Value,
        path: String = FileManager.defaultFileStatePath,
        filename: String,
        isBase64Encoded: Bool = true
    ) -> FileState<Value> {
        FileState(
            initial: initial(),
            scope: Scope(name: path, id: filename),
            isBase64Encoded: isBase64Encoded
        )
    }

    /**
     Retrieves a `FileManager` backed state for the provided `path` and `filename` with a default value of `nil`.

     - Parameters:
        - path: The path to the directory containing the file. The default is `FileManager.defaultFileStatePath`.
        - filename: The name of the file to read.
        - isBase64Encoded: Boolean to determine if the value should be encoded as Base64. The default is `true`.
     - Returns: The state of type `Value`.
     */
    @MainActor
    func fileState<Value>(
        path: String = FileManager.defaultFileStatePath,
        filename: String,
        isBase64Encoded: Bool = true
    ) -> FileState<Value?> {
        fileState(
            initial: nil,
            path: path,
            filename: filename,
            isBase64Encoded: isBase64Encoded
        )
    }
}
