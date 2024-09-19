#if os(Linux) || os(Windows)
import Foundation

/// `ApplicationLogger` is a struct that provides logging functionalities for Linux and Windows operating systems using closures.
public struct ApplicationLogger: Sendable {
    private var debugClosure: @Sendable (String) -> Void
    private var errorClosure: @Sendable (Error, String?) -> Void

    /// Initializes the `ApplicationLogger` struct with custom behaviors for each closure.
    /// - Parameters:
    ///   - debug: A closure for logging debug messages.
    ///   - debugWithClosure: A closure for logging debug messages using a closure.
    ///   - errorWithMessage: A closure for logging error messages with an optional custom message.
    ///   - errorWithString: A closure for logging error messages as strings.
    public init(
        debug: @Sendable @escaping (String) -> Void = { print($0) },
        error: @Sendable @escaping (Error, String?) -> Void = { error, message in
            if let message = message {
                print("\(message) (Error: \(error.localizedDescription))")
            } else {
                print("Error: \(error.localizedDescription)")
            }
        }
    ) {
        self.debugClosure = debug
        self.errorClosure = error
    }

    /// Prints a debug message.
    /// - Parameter message: The message to be logged.
    public func debug(_ message: String) {
        debugClosure(message)
    }

    /// Prints a debug message using a closure.
    /// - Parameter message: A closure that returns the message to be logged.
    public func debug(_ message: () -> String) {
        debug(message())
    }

    /// Logs an error message.
    /// - Parameters:
    ///   - error: The error that occurred.
    ///   - message: An optional custom message to accompany the error.
    public func error(_ error: Error, message: String? = nil) {
        errorClosure(error, message)
    }
}

#endif
