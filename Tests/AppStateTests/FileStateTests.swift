import Foundation
#if !os(Linux) && !os(Windows)
import SwiftUI
#endif
import XCTest
@testable import AppState

fileprivate extension Application {
    @MainActor
    var storedValue: FileState<Int?> {
        fileState(filename: "storedValue")
    }

   @MainActor
    var storedString: FileState<String?> {
        fileState(filename: "storedString", isBase64Encoded: false)
    }
}

@MainActor
fileprivate struct ExampleStoredValue {
    @FileState(\.storedValue) var count
    @FileState(\.storedString) var storedString
}

@MainActor
fileprivate class ExampleStoringViewModel {
    @FileState(\.storedValue) var count
    @FileState(\.storedString) var storedString

    func testPropertyWrapper() {
        count = 27
        storedString = "Hello"
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
extension ExampleStoringViewModel: ObservableObject { }
#endif

final class FileStateTests: XCTestCase {
    override func setUp() async throws {
        await Application.logging(isEnabled: true)

        await MainActor.run {
            FileManager.defaultFileStatePath = "./AppStateTests"
        }
    }

    override func tearDown() async throws {
        let applicationDescription = await Application.description

        Application.logger.debug("FileStateTests \(applicationDescription)")

        await MainActor.run {
            try? Application.dependency(\.fileManager).removeItem(atPath: "./AppStateTests")
        }
    }

    @MainActor
    func testFileState() {
        XCTAssertEqual(FileManager.defaultFileStatePath, "./AppStateTests")
        XCTAssertNil(Application.fileState(\.storedValue).value)
        XCTAssertNil(Application.fileState(\.storedString).value)

        let storedValue = ExampleStoredValue()

        XCTAssertEqual(storedValue.count, nil)
        XCTAssertEqual(storedValue.storedString, nil)

        storedValue.count = 1
        storedValue.storedString = "Hello"

        XCTAssertEqual(storedValue.count, 1)
        XCTAssertEqual(storedValue.storedString, "Hello")

        Application.logger.debug("FileStateTests \(Application.description)")

        storedValue.count = nil
        storedValue.storedString = nil

        XCTAssertNil(Application.fileState(\.storedValue).value)
        XCTAssertNil(Application.fileState(\.storedString).value)
    }

    @MainActor
    func testStoringViewModel() {
        XCTAssertEqual(FileManager.defaultFileStatePath, "./AppStateTests")
        XCTAssertNil(Application.fileState(\.storedValue).value)
        XCTAssertNil(Application.fileState(\.storedString).value)

        let viewModel = ExampleStoringViewModel()

        XCTAssertEqual(viewModel.count, nil)
        XCTAssertEqual(viewModel.storedString, nil)

        viewModel.testPropertyWrapper()

        XCTAssertEqual(viewModel.count, 27)
        XCTAssertEqual(viewModel.storedString, "Hello")

        Application.reset(fileState: \.storedValue)
        Application.reset(fileState: \.storedString)

        XCTAssertNil(viewModel.count)
        XCTAssertNil(viewModel.storedString)
    }
}
