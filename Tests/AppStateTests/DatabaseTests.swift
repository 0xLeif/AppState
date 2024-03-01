import XCTest
@testable import AppState

final class DatabaseTests: XCTestCase {
    func testExample() throws {
        let database = try Database(path: Application.dependency(\.fileManager).temporaryDirectory.appending(path: "tests.sqlite").path())

        let dropTableStatementString = "DROP TABLE Contact;"

        try? database.run(statement: dropTableStatementString)

        // Table
        let createTableString = """
        CREATE TABLE Contact(
            Id INT PRIMARY KEY NOT NULL,
            Name VARCHAR(255)
        );
        """

        try database.run(statement: createTableString)

        let insertStatementString = "INSERT INTO Contact (Id, Name) VALUES (1, 'Init');"

        try database.insert(statement: insertStatementString)

        try database.insert(statement: "INSERT INTO Contact (Id, Name) VALUES (2, 'Other');")

        let queryStatementString = "SELECT * FROM Contact;"

        let queryResult = try database.query(statement: queryStatementString)

        XCTAssertEqual(queryResult.count, 2)

        XCTAssertEqual(queryResult[0]["id"]?.int, 1)
        XCTAssertEqual(queryResult[0]["name"]?.string, "Init")

        XCTAssertEqual(queryResult[1]["id"]?.int, 2)
        XCTAssertEqual(queryResult[1]["name"]?.string, "Other")

        let updateStatementString = "UPDATE Contact SET Name = 'Leif';"

        try database.run(statement: updateStatementString)

        let queryResultPostUpdate = try database.query(statement: queryStatementString)

        XCTAssertEqual(queryResultPostUpdate[0]["id"]?.int, 1)
        XCTAssertEqual(queryResultPostUpdate[0]["name"]?.string, "Leif")

        XCTAssertEqual(queryResultPostUpdate[1]["id"]?.int, 2)
        XCTAssertEqual(queryResultPostUpdate[1]["name"]?.string, "Leif")

        let deleteStatementString = "DELETE FROM Contact WHERE Id = 1;"

        try database.run(statement: deleteStatementString)

        let queryResultPostDelete = try database.query(statement: deleteStatementString)

        XCTAssertEqual(queryResultPostDelete.count, 0)

        try database.run(statement: dropTableStatementString)
    }

    func testError() throws {
        var database: Database? = try Database(path: Application.dependency(\.fileManager).temporaryDirectory.appending(path: "testError.sqlite").path())

        XCTAssertThrowsError(try Database(path: Application.dependency(\.fileManager).temporaryDirectory.appending(path: "testError.sqlite").path()))

        XCTAssertNotNil(database)

        XCTAssertEqual(Application.state(\.activeDatabases).value.count, 1)

        _ = try Database(path: Application.dependency(\.fileManager).temporaryDirectory.appending(path: "testErrorDealloc.sqlite").path())

        XCTAssertEqual(Application.state(\.activeDatabases).value.count, 1)

        database = nil

        XCTAssertEqual(Application.state(\.activeDatabases).value.count, 0)
    }
}
