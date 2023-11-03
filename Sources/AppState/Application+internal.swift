extension Application {
    static func codeID(
        fileID: StaticString,
        function: StaticString,
        line: Int,
        column: Int
    ) -> String {
        "\(fileID)[\(function)@\(line)|\(column)]"
    }
}
