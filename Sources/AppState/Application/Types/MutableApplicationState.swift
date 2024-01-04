public protocol MutableApplicationState {
    associatedtype Value

    var value: Value { get set }
}
