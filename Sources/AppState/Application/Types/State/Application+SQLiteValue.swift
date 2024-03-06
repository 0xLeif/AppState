import Foundation

public protocol SQLiteInitializable: Codable {
    var values: [Any] { get }

    init?(values: [String: DatabaseValue]) throws
}

extension Application {
    public struct SQLiteValue<Value: SQLiteInitializable>: MutableApplicationState {
        public static var emoji: Character { "🪶" }

        private let database: Database

        private let readQuery: String
        private let writeQuery: String
        private let deleteQuery: String

        /// The initial value of the state.
        private var initial: () -> Value

        /// The current state value.
        public var value: Value {
            get {
//                let cachedValue = shared.cache.get(
//                    scope.key,
//                    as: State<Value>.self
//                )
//
//                if let cachedValue = cachedValue {
//                    return cachedValue.value
//                }

                let queryResult: [[String: DatabaseValue]]

                do {
                    queryResult = try database.query(statement: deleteQuery)
                } catch {
                    // log
                    return initial()
                }

                guard let values = queryResult.first else {
                    // log
                    return initial()
                }

                do {
                    guard let storedValue = try Value(values: values) else {
                        // log
                        return initial()
                    }

                    return storedValue
                } catch {
                    // log
                    return initial()
                }
            }
            set {
                let mirror = Mirror(reflecting: newValue)

                if mirror.displayStyle == .optional,
                   mirror.children.isEmpty {
                    shared.cache.remove(scope.key)
                    do {
//                        try DatabaseValue(value: id).bind(statement: <#T##OpaquePointer?#>, index: <#T##Int32#>)

                        try database.run(statement: deleteQuery)
                    } catch {
                        // log
                    }
                } else {
                    shared.cache.set(
                        value: Application.State(
                            type: .stored,
                            initial: newValue,
                            scope: scope
                        ),
                        forKey: scope.key
                    )

                    do {
                        try database.insert(statement: writeQuery, data: newValue.values)
                    } catch {
                        // log
                        print(error.localizedDescription)
                    }
                }
            }
        }

        /// The scope in which this state exists.
        let scope: Scope

        /**
         Creates a new state within a given scope initialized with the provided value.

         - Parameters:
             - value: The initial value of the state
             - scope: The scope in which the state exists
         */
        init(
            database: KeyPath<Application, Dependency<Database>>,
            readQuery: String,
            writeQuery: String,
            deleteQuery: String,
            initial: @escaping @autoclosure () -> Value,
            scope: Scope
        ) {
            self.database = Application.dependency(database)
            self.readQuery = readQuery
            self.writeQuery = writeQuery
            self.deleteQuery = deleteQuery
            self.initial = initial
            self.scope = scope
        }

        /// Resets the value to the inital value. If the inital value was `nil`, then the value will be removed from the SQLite database.
        public mutating func reset() {
            value = initial()
        }

        public mutating func delete() {
            shared.cache.remove(scope.key)
            do {
                try database.run(statement: deleteQuery)
            } catch {
                // log
            }
        }
    }
}
