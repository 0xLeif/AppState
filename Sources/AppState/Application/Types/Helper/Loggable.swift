protocol Loggable {
    @MainActor
    var logValue: String { get }
}
