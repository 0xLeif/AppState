#if os(Linux) || os(Windows)
open class ApplicationLogger {
    open func debug(_ message: String) {
        debug { message }
    }

    open func debug(_ message: () -> String) {
        print(message())
    }

    open func error(_ error: Error, message: String) {
        print("\(message) (Error: \(error.localizedDescription))")
    }
}
#endif
