import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

struct ExampleSQLValue: SQLiteInitializable {
    var id: UUID?
    var title: String
    var count: Int

    var values: [Any] {
        [
            id as Any,
            title,
            count
        ]
    }

    init(
        title: String,
        count: Int = 0
    ) {
        self.title = title
        self.count = count
    }

    init?(values: [String: DatabaseValue]) throws {
        guard
            let id = values["Id"]?.string,
            let title = values["Title"]?.string,
            let count = values["Count"]?.int
        else {
            throw SQLiteError.activeDatabase // TODO
        }

        self.id = UUID(uuidString: id)
        self.title = title
        self.count = Int(count)
    }
}

fileprivate extension Application {
    var database: Dependency<Database> {
        dependency {
            do {
                return try Database(path: Application.dependency(\.fileManager).temporaryDirectory.appending(path: "value_test.sqlite").path())
            } catch {
                fatalError("Couldn't make the database")
            }
        }
    }

    /*
     var table: SQLiteTable {
        ...
     }
     */

    var sqlValue: SQLiteValue<ExampleSQLValue> {
        SQLiteValue(
            database: \.database,
            readQuery: "SELECT * FROM Contact;",
            writeQuery: "INSERT INTO Contact (Id, Name, Count) VALUES (?, ?, ?);",
            deleteQuery: "DELETE FROM Contact WHERE Id = ?;",
            initial: ExampleSQLValue(title: "init"),
            scope: Scope(name: "test", id: "sql.value")
        )
    }
}

fileprivate struct ExampleValue {
    @SQLiteValue(\.sqlValue) var sqlValue
    @Slice(\.sqlValue, \.count) var count
}

fileprivate class ExampleViewModel {
    @SQLiteValue(\.sqlValue) var sqlValue
    @Slice(\.sqlValue, \.count) var count

    func testPropertyWrapper() {
        count = 27
        #if !os(Linux) && !os(Windows)
        _ = TextField(
            value: $count,
            format: .number,
            label: { Text("Count") }
        )
        #endif
    }
}

#if !os(Linux) && !os(Windows)
extension ExampleViewModel: ObservableObject { }
#endif

final class SQLiteValueTests: XCTestCase {
    func testExample() throws {
        let database = Application.dependency(\.database)

        let dropTableStatementString = "DROP TABLE Contact;"

        try? database.run(statement: dropTableStatementString)

        // Table
        let createTableString = """
        CREATE TABLE Contact(
            Id UUID PRIMARY KEY NOT NULL,
            Name VARCHAR(255) NOT NULL,
            Count INT NOT NULL
        );
        """

        try database.run(statement: createTableString)

        let storedValue = ExampleValue()

        XCTAssertEqual(storedValue.count, 0)

        storedValue.count = 1

        XCTAssertEqual(storedValue.count, 1)

        Application.logger.debug("StoredStateTests \(Application.description)")

        storedValue.count = 0

        XCTAssertEqual(storedValue.count, 0)
    }

    func testError() throws {
        var database: Database? = try Database(path: Application.dependency(\.fileManager).temporaryDirectory.appending(path: "value_testError.sqlite").path())

        XCTAssertThrowsError(try Database(path: Application.dependency(\.fileManager).temporaryDirectory.appending(path: "value_testError.sqlite").path()))

        XCTAssertNotNil(database)

        XCTAssertEqual(Application.state(\.activeDatabases).value.count, 1)

        _ = try Database(path: Application.dependency(\.fileManager).temporaryDirectory.appending(path: "value_testErrorDealloc.sqlite").path())

        XCTAssertEqual(Application.state(\.activeDatabases).value.count, 1)

        database = nil

        XCTAssertEqual(Application.state(\.activeDatabases).value.count, 0)
    }
}
