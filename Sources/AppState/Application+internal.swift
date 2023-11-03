extension Application {
    /// Generates a specific identifier string for given code context
    ///
    /// - Parameters:
    ///     - fileID: The file identifier of the code, generally provided by `#fileID` directive.
    ///     - function: The function name of the code, generally provided by `#function` directive.
    ///     - line: The line number of the code, generally provided by `#line` directive.
    ///     - column: The column number of the code, generally provided by `#column` directive.
    /// - Returns: A string representing the specific location and context of the code. The format is `<fileID>[<function>@<line>|<column>]`.
    static func codeID(
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
    ) -> String {
        "\(fileID)[\(function)@\(line)|\(column)]"
    }
}
