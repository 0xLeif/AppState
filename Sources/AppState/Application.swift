import Cache
import Combine
import OSLog

public class Application: ObservableObject {
    static let shared: Application = Application()

    public static let logger: Logger = Logger(subsystem: "Application", category: "AppState")

    private let lock: NSLock
    private var bag: Set<AnyCancellable>

    let cache: Cache<String, Any>

    deinit {
        bag.removeAll()
    }

    private init() {
        lock = NSLock()
        bag = Set()
        cache = Cache()

        consume(object: cache)
    }

    func value<Value>(keyPath: KeyPath<Application, Value>) -> Value {
        lock.lock(); defer { lock.unlock() }

        return self[keyPath: keyPath]
    }

    private func consume<Object: ObservableObject>(
        object: Object
    ) where ObjectWillChangePublisher == ObservableObjectPublisher {
        bag.insert(
            object.objectWillChange.sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] _ in
                    self?.objectWillChange.send()
                }
            )
        )
    }
}
