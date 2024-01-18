extension Application {
    /**
     `Scope` represents a specific context in your application, defined by a name and an id. It's mainly used to maintain a specific state or behavior in your application.

     For example, it could be used to scope a state to a particular screen or user interaction flow.
    */
    public struct Scope {
        /// The name of the scope context
        public let name: String

        /// The specific id for this scope context
        public let id: String

        /// Key computed property which builds a unique key for a given scope by combining `name` and `id` separated by "/"
        public var key: String {
            "\(name)/\(id)"
        }
    }
}
