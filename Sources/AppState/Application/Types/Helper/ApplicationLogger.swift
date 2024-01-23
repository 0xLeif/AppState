#if os(Linux) || os(Windows)
open class ApplicationLogger {
    open func debug(_ message: String) {
        debug { message }
    }

    open func debug(_ message: () -> String) {
        print(message())
    }

    open func error(_ error: Error, message: String? = nil) {
        guard let message else {
            return print("Error: \(error.localizedDescription)")
        }

        print("\(message) (Error: \(error.localizedDescription))")
    }

    open func error(_ message: String) {
        print("Error: \(message)")
    }
}
#endif
