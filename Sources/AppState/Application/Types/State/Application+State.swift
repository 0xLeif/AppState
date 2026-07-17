import Foundation

extension Application {
    /// `State` encapsulates the value within the application's scope and allows any changes to be propagated throughout the scoped area.
    public struct State<Value: Sendable>: Sendable, MutableApplicationState, Loggable {
        /// Values that are available in the cache.
        enum StateType {
            case state
            case stored
            case file
        }

        public static var emoji: Character {
            #if canImport(OSLog)
            return "🔄"
            #else
            return "📦"
            #endif
        }

        private let type: StateType

        /// A private backing storage for the value.
        private var _value: Value

        /// The initial value of the state.
        private let initial: Value

        /// The current state value.
        ///
        /// - Note: **Issue #151 — Linux `_arrayForceCast` crash.**
        ///   The `shared.cache.get(scope.key, as: State<Value>.self)` call below performs
        ///   an `Any → State<Value>` dynamic cast inside `Dictionary+Cacheable.swift:18`
        ///   (`self[key] as? Item`). On Linux, when `Value` is a collection type such as
        ///   `[Element]`, the Swift runtime's `swift_dynamicCast` path invokes
        ///   `_arrayForceCast` for the generic parameter, which crashes with a
        ///   `swift_dynamicCastFailure`. This is a known Swift-on-Linux stdlib/runtime
        ///   limitation (SR-4049 / swift#40956) affecting `as?` casts from `Any` to
        ///   generic structs whose generic parameters are array types. A clean fix requires
        ///   either: (a) replacing `Cache<String, Any>` with a type-index keyed store so
        ///   `Any` is never the concrete container value type, or (b) filing a Cache library
        ///   issue to store a type-erased wrapper that avoids the metatype dereference during
        ///   cast. Until then, `State<[T]>` and `FileState<[T]?>` will crash on Linux when
        ///   their value is read after being evicted from the in-memory cache.
        @MainActor
        public var value: Value {
            get {
                guard
                    let state = shared.cache.get(
                        scope.key,
                        as: State<Value>.self
                    )
                else {
                    defer {
                        let setValue = {
                            shared.cache.set(
                                value: Application.State(
                                    type: .state,
                                    initial: _value,
                                    scope: scope
                                ),
                                forKey: scope.key
                            )
                        }
                        #if canImport(ObjectiveC)
                        if NSClassFromString("XCTest") == nil {
                            Task { @MainActor in
                                setValue()
                            }
                        } else {
                            setValue()
                        }
                        #else
                        setValue()
                        #endif
                    }
                    return _value
                }
                return state._value
            }
            set {
                _value = newValue
                shared.cache.set(
                    value: Application.State(
                        type: .state,
                        initial: newValue,
                        scope: scope
                    ),
                    forKey: scope.key
                )
                shared.notifyChange()
            }
        }

        /// The scope in which this state exists.
        let scope: Scope

        /**
         Creates a new state within a given scope initialized with the provided value.

         - Parameters:
             - value: The initial value of the state
             - scope: The scope in which the state exists
         */
        init(
            type: StateType,
            initial: @autoclosure () -> Value,
            scope: Scope
        ) {
            self.type = type
            let initialValue = initial()
            self._value = initialValue
            self.initial = initialValue
            self.scope = scope
        }

        /// Resets the value to the initial value.
        @MainActor
        public mutating func reset() {
            value = initial
        }

        @MainActor
        public var logValue: String {
            switch type {
            case .state:    return "State<\(Value.self)>(\(value)) (\(scope.key))"
            case .stored:   return "StoredState<\(Value.self)>(\(value)) (\(scope.key))"
            case .file:     return "FileState<\(Value.self)>(\(value)) (\(scope.key))"
            }
        }
    }
}
