#if os(Linux) || os(Windows)
/// `ApplicationLogger` is a class that provides logging functionalities for Linux and Windows operating systems.
open class ApplicationLogger {
    /// Prints a debug message.
    /// - Parameter message: The message to be logged.
    open func debug(_ message: String) {
        debug { message }
    }

    /// Prints a debug message.
    /// - Parameter message: A closure that returns the message to be logged.
    open func debug(_ message: () -> String) {
        print(message())
    }

    /// Logs an error message.
    /// - Parameters:
    ///   - error: The error that occurred.
    ///   - message: An optional custom message to accompany the error.
    open func error(_ error: Error, message: String? = nil) {
        guard let message else {
            return print("Error: \(error.localizedDescription)")
        }

        print("\(message) (Error: \(error.localizedDescription))")
    }

    /// Logs an error message.
    /// - Parameter message: The error message to be logged.
    open func error(_ message: String) {
        print("Error: \(message)")
    }
}
#endif
