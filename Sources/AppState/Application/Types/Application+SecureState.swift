import Security
import Foundation

extension Application {
    /// The default `Keychain` instance.
    public var keychain: Dependency<Keychain> {
        dependency(Keychain())
    }

    /// The SecureState structure provides secure and persistent key-value string storage that can be used across the application.
    public struct SecureState {
        @AppDependency(\.keychain) private var keychain: Keychain

        /// The initial value of the state.
        private var initial: () -> String?

        /// The current state value.
        /// Reading this value will return the stored string value in the keychain if it exists, otherwise, it will return the initial value.
        /// Writing a new string value to the state, it will be stored securely in the keychain. Writing `nil` will remove the corresponding key-value pair from the keychain store.
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

        /// Resets the state value to the initial value and store it in the keychain.
        public mutating func reset() {
            value = initial()
        }
    }
}
