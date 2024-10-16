extension Application {
    var dependencyPromotions: State<[DependencyOverride]> {
        state(initial: [])
    }

    /// `Dependency` struct encapsulates dependencies used throughout the app.
    public struct Dependency<Value: Sendable>: Sendable, Loggable {
        /// The dependency value.
        var value: Value

        /// The scope in which this state exists.
        let scope: Scope

        /**
         Initializes a new dependency within a given scope with an initial value.

         A Dependency allows for defining services or shared objects across the app. It is designed to be read-only and can only be changed by re-initializing it, ensuring thread-safety in your app.

         - Parameters:
            - value: The initial value of the dependency.
            - scope: The scope in which the dependency exists.
         */
        init(
            _ value: Value,
            scope: Scope
        ) {
            self.value = value
            self.scope = scope
        }

        public var logValue: String {
            "Dependency<\(Value.self)>(\(value)) (\(scope.key))"
        }
    }

    /// `DependencyOverride` provides a handle to revert a dependency override operation.
    public final class DependencyOverride: Sendable {
        /// Closure to be invoked when the dependency override is cancelled. This closure typically contains logic to revert the overrides on the dependency.
        private let cancelOverride: @Sendable () async -> Void

        /**
         Initializes a `DependencyOverride` instance.

         - Parameter cancelOverride: The closure to be invoked when the
           dependency override is cancelled.
         */
        init(cancelOverride: @Sendable @escaping () async -> Void) {
            self.cancelOverride = cancelOverride
        }

        /// Cancels the override and resets the Dependency back to its value before the override.
        public func cancel() async {
            await cancelOverride()
        }
    }
}
