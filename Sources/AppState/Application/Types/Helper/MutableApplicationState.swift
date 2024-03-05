/**
A protocol that represents a mutable application state.

This protocol defines a type, `Value`, and a mutable property, `value`, of that type. It serves as the blueprint for any type that needs to represent a mutable state within an application.
*/
public protocol MutableApplicationState {
    associatedtype Value

    static var emoji: Character { get }

    /// The actual value that this state holds. It can be both retrieved and modified.
    var value: Value { get set }
}

extension MutableApplicationState {
    static var emoji: Character { "❓" }
}
