import Cache
import Combine
import OSLog

public class Application: ObservableObject {
    static let shared: Application = Application()

    public static let logger: Logger = Logger(subsystem: "Application", category: "AppState")

    private var bag: Set<AnyCancellable>

    let cache: Cache<String, Any>

    deinit {
        bag.removeAll()
    }

    private init() {
        bag = Set()
        cache = Cache()

        consume(object: cache)
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
