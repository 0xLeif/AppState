import Security
import Foundation

extension Application {
    public var keychain: Dependency<Keychain> {
        dependency(Keychain())
    }

    public struct SecureState {
        @AppDependency(\.keychain) private var keychain: Keychain

        /// The initial value of the state.
        private var initial: () -> String?

        /// The current state value.
        public var value: String? {
            get {
                guard
                    let storedValue = keychain.get(scope.key, as: String.self)
                else { return initial() }

                return storedValue
            }
            set {
                guard let newValue else {
                    return keychain.remove(scope.key)
                }

                keychain.set(value: newValue, forKey: scope.key)
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
            initial: @escaping @autoclosure () -> String?,
            scope: Scope
        ) {
            self.initial = initial
            self.scope = scope
        }

        public mutating func reset() {
            value = initial()
        }
    }
}
