import XCTest
@testable import AppState

final class FileManagerExtensionTests: XCTestCase {
    func testWriteAndReadCodable() throws {
        let path = "./FileManagerTests"
        let filename = "test.json"
        let text = "Hello"

        try FileManager.default.out(text, path: path, filename: filename, base64Encoded: false)
        let readText: String = try FileManager.default.in(path: path, filename: filename)
        XCTAssertEqual(readText, text)

        try FileManager.default.delete(path: path, filename: filename)
        try FileManager.default.removeItem(atPath: path)
    }

    func testWriteAndReadData() throws {
        let path = "./FileManagerTestsData"
        let filename = "data.txt"
        let data = Data("Data".utf8)

        try FileManager.default.out(data: data, path: path, filename: filename, base64Encoded: true)
        let readData = try FileManager.default.data(path: path, filename: filename)
        XCTAssertEqual(readData, data)

        try FileManager.default.delete(path: path, filename: filename)
        try FileManager.default.removeItem(atPath: path)
    }
}
