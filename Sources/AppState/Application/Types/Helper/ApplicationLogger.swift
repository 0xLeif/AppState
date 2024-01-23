#if os(Linux) || os(Windows)
open class ApplicationLogger {
    open func debug(
        _ message: String,
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
    ) {
        debug(
            { message },
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    open func debug(
        _ message: () -> String,
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
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
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
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
