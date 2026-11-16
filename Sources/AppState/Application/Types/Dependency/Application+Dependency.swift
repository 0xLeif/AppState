import Foundation

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
    ///
    /// The override ends when ``cancel()`` is called or when the last reference to the token is
    /// released, whichever comes first. The dependency is restored once.
    public final class DependencyOverride: Sendable {
        /// Holds the restore closure on the main actor and runs it at most once, so an explicit
        /// ``cancel()`` followed by the token's release does not restore twice.
        @MainActor
        private final class Restoration {
            private var restore: (@MainActor () -> Void)?

            init(restore: @escaping @MainActor () -> Void) {
                self.restore = restore
            }

            func run() {
                let restore = restore
                self.restore = nil
                restore?()
            }
        }

        private let restoration: Restoration

        /**
         Initializes a `DependencyOverride` instance.

         - Parameter restore: The closure that puts the overridden dependency back. It runs once,
           on the main actor.
         */
        @MainActor
        init(restore: @escaping @MainActor () -> Void) {
            self.restoration = Restoration(restore: restore)
        }

        deinit {
            let restoration = restoration

            // Released on the main thread, which is the usual case for tests and previews, the
            // dependency is back before the release returns. Elsewhere it is restored on the
            // main actor's next turn.
            #if os(WASI)
            Task { @MainActor in restoration.run() }
            #else
            if Thread.isMainThread {
                MainActor.assumeIsolated { restoration.run() }
            } else {
                Task { @MainActor in restoration.run() }
            }
            #endif
        }

        /// Cancels the override and resets the Dependency back to its value before the override.
        public func cancel() async {
            await restoration.run()
        }
    }
}
