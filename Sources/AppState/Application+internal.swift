extension Application {
    static func codeID(
        fileID: StaticString,
        function: StaticString,
        line: StaticBigInt,
        column: StaticBigInt
    ) -> String {
        "\(fileID)[\(function)@\(line)|\(column)]"
    }

    func value<Value>(keyPath: KeyPath<Application, Value>) -> Value {
        self[keyPath: keyPath]
    }
}
