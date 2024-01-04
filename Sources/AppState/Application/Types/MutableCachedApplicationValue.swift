public protocol MutableCachedApplicationValue {
    associatedtype Value

    var value: Value { get set }
}
