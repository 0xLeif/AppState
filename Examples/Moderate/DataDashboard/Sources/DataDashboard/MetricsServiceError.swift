import Foundation

// MARK: - MetricsServiceError

/// The set of errors that can occur when fetching dashboard metrics.
public enum MetricsServiceError: Error, LocalizedError, Sendable {

    /// The remote endpoint returned no usable data.
    case noData

    /// The network layer reported a failure with an underlying cause.
    case networkFailure(underlying: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .noData:
            return "The metrics service returned no data."
        case .networkFailure(let cause):
            return "Network failure: \(cause)"
        }
    }
}
