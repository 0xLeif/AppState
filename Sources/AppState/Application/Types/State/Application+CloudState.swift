#if !os(Linux) && !os(Windows)
import Foundation
import SwiftUI

extension Application {
    struct ExternalChange {
        var modificationDate: Date
        var attributeModificationDate: Date
        var hasCompletedChange: Bool

        init(
            modificationDate: Date,
            attributeModificationDate: Date
        ) {
            self.modificationDate = modificationDate
            self.attributeModificationDate = attributeModificationDate
            self.hasCompletedChange = false
        }
    }

    var icloudDocumentStore: Dependency<CloudStateStore> {
        dependency(CloudStateStore())
    }

    var initialFetches: State<Set<String>> {
        state(initial: [])
    }

    var externalChanges: State<[String: ExternalChange]> {
        state(initial: [:])
    }

    /// `CloudDocumentState` ...
    public struct CloudState<Value: Codable & Equatable>: MutableApplicationState {
        public static var emoji: Character { "☁️" }

        @ObservedObject private var viewModel: CloudStateViewModel<Value>

        /// The initial value of the state.
        private var initial: () -> Value

        /// The current state value.
        public var value: Value {
            get {
                let cachedValue = shared.cache.get(
                    scope.key,
                    as: State<Value>.self
                )

                if shared.initialFetches.value.contains(scope.key) == false {
                    viewModel.getValue(cachedValue: cachedValue?.value)
                } else if
                    let externalChange = shared.value(keyPath: \.externalChanges).value[scope.key],
                    externalChange.hasCompletedChange == false
                {
                    viewModel.getValue(cachedValue: cachedValue?.value)
                }

                if let cachedValue {
                    return cachedValue.value
                }

                return initial()
            }
            set {
                let mirror = Mirror(reflecting: newValue)

                if mirror.displayStyle == .optional,
                   mirror.children.isEmpty {
                    shared.cache.remove(scope.key)

                    viewModel.removeValue()
                } else {
                    shared.cache.set(
                        value: Application.State(
                            type: .cloud,
                            initial: newValue,
                            scope: scope
                        ),
                        forKey: scope.key
                    )

                    viewModel.setValue(newValue: newValue)
                }
            }
        }

        /// The scope in which this state exists.
        let scope: Scope

        let isBase64Encoded: Bool

        var path: String { scope.name }
        var filename: String { scope.id }

        /**
         Creates a new state within a given scope initialized with the provided value.

         - Parameters:
         - value: The initial value of the state
         - scope: The scope in which the state exists
         */
        init(
            initial: @escaping @autoclosure () -> Value,
            scope: Scope,
            isBase64Encoded: Bool
        ) {
            self.initial = initial
            self.scope = scope
            self.isBase64Encoded = isBase64Encoded
            self.viewModel = CloudStateViewModel(scope: scope)
        }

        /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from `FileManager`
        public mutating func reset() {
            value = initial()
        }
    }
}
#endif
