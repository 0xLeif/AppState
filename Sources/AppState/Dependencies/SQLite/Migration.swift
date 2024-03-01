public struct Migration {
    public let version: Int
    public let action: (Database) throws -> Void

    public init(version: Int, action: @escaping (Database) throws -> Void) {
        self.version = version
        self.action = action
    }
}
