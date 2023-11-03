import Cache
import Combine
import OSLog

/// `Application` is a class that can be observed for changes, keeping track of the states within the application.
public class Application: ObservableObject {
    /// Singleton shared instance of `Application`
    static let shared: Application = Application()

    /**
     Generates a specific identifier string for given code context

     - Parameters:
         - fileID: The file identifier of the code, generally provided by `#fileID` directive.
         - function: The function name of the code, generally provided by `#function` directive.
         - line: The line number of the code, generally provided by `#line` directive.
         - column: The column number of the code, generally provided by `#column` directive.
     - Returns: A string representing the specific location and context of the code. The format is `<fileID>[<function>@<line>|<column>]`.
     */
    static func codeID(
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
    ) -> String {
        "\(fileID)[\(function)@\(line)|\(column)]"
    }

    /// Logger specifically for AppState
    public static let logger: Logger = Logger(subsystem: "AppState", category: "Application")

    private let lock: NSLock
    private var bag: Set<AnyCancellable>

    /// Cache to store values
    let cache: Cache<String, Any>

    deinit { bag.removeAll() }

    private init() {
        lock = NSLock()
        bag = Set()
        cache = Cache()

        consume(object: cache)
    }

    /// Returns value for the provided keyPath. This method is thread safe
    ///
    /// - Parameter keyPath: KeyPath of the value to be fetched
    func value<Value>(keyPath: KeyPath<Application, Value>) -> Value {
        lock.lock(); defer { lock.unlock() }

        return self[keyPath: keyPath]
    }

    /// Consumes changes in the provided ObservableObject and sends updates before the object will change.
    ///
    /// - Parameter object: The ObservableObject to observe
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
