extension Application {
    struct Scope {
        let name: String
        let id: String

        var key: String {
            "\(name)/\(id)"
        }
    }
}
