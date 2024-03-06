import Foundation
import SQLite3

extension Application {
    var activeDatabases: State<Set<String>> {
        state(initial: [])
    }
}

let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

public class Database: ObservableObject {

    @AppState(\.activeDatabases) private var activeDatabases: Set<String>

    private let lock: NSLock
    private let path: String
    private let db: OpaquePointer

    public init(path: String) throws {
        guard Application.state(\.activeDatabases).value.contains(path) == false else {
            throw SQLiteError.activeDatabase
        }

        self.lock = NSLock()
        self.path = path

        var database: OpaquePointer?

        lock.lock()
        let openResult = sqlite3_open(path, &database)
        lock.unlock()

        guard
            let database,
            openResult == SQLITE_OK
        else {
            throw SQLiteError.open(openResult)
        }

        self.db = database

        activeDatabases.insert(path)
    }

    deinit {
        lock.lock()
        sqlite3_close(db)
        activeDatabases.remove(path)
        lock.unlock()
    }

    public func run(statement: String) throws {
        var sqlStatement: OpaquePointer?

        lock.lock(); defer {
            sqlite3_finalize(sqlStatement)
            lock.unlock()
        }

        let prepareResult = sqlite3_prepare_v2(db, statement, -1, &sqlStatement, nil)

        guard prepareResult == SQLITE_OK else {
            throw SQLiteError.prepare(prepareResult)
        }

        let stepResult = sqlite3_step(sqlStatement)

        guard stepResult == SQLITE_DONE else {
            throw SQLiteError.step(stepResult)
        }
    }

    public func insert(
        statement: String,
        data: [Any] = []
    ) throws {
        var sqlStatement: OpaquePointer?

        lock.lock(); defer {
            sqlite3_finalize(sqlStatement)
            lock.unlock()
        }

        let prepareResult = sqlite3_prepare_v2(db, statement, -1, &sqlStatement, nil)

        guard prepareResult == SQLITE_OK else {
            throw SQLiteError.prepare(prepareResult)
        }

        var index: Int32 = 1
        for datum in data {
            try DatabaseValue(value: datum).bind(statement: sqlStatement, index: index)
            index += 1
        }

        let stepResult = sqlite3_step(sqlStatement)

        guard stepResult == SQLITE_DONE else {
            throw SQLiteError.step(stepResult)
        }
    }

    public func query(
        statement: String
    ) throws -> [[String: DatabaseValue]] {
        var sqlStatement: OpaquePointer?

        lock.lock(); defer {
            sqlite3_finalize(sqlStatement)
            lock.unlock()
        }

        let prepareResult = sqlite3_prepare_v2(db, statement, -1, &sqlStatement, nil)

        guard prepareResult == SQLITE_OK else {
            throw SQLiteError.prepare(prepareResult)
        }

        var queryResults: [[String: DatabaseValue]] = []

        while sqlite3_step(sqlStatement) == SQLITE_ROW {
            let columnCount = sqlite3_column_count(sqlStatement)
            var columnResult: [String: DatabaseValue] = [:]

            for column in 0 ..< columnCount {
                try columnResult[String(cString: sqlite3_column_name(sqlStatement, column)).lowercased()] = DatabaseValue(sqlStatement, index: column)
            }

            queryResults.append(columnResult)
        }

        return queryResults
    }

    public func transaction<Value>(
        _ action: (Database) throws -> Value
    ) throws -> Value {
        try run(statement: "BEGIN TRANSACTION")
        do {
            let result = try action(self)
            try run(statement: "COMMIT TRANSACTION")
            return result
        } catch {
            try run(statement: "ROLLBACK TRANSACTION")
            throw error
        }
    }
}
