#if os(Linux) || os(Windows)
open class ApplicationLogger {
    open func debug(
        _ message: String,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        debug(
            { message },
            fileID,
            function,
            line,
            column
        )
    }

    open func debug(
        _ message: () -> String,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        Application.log(
            debug: message,
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    open func error(
        _ error: Error,
        message: String,
        _ fileID: StaticString = #fileID,
        _ function: StaticString = #function,
        _ line: Int = #line,
        _ column: Int = #column
    ) {
        Application.log(
            error: error,
            message: message,
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }
}
#endif
