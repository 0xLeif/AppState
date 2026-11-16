import Foundation

extension FileManager {
    /// Gets the documentDirectory from FileManager and appends "/App". Otherwise if it can not get the documents directory is will return "~/App". This variable can be set to whatever path you want to be the default.
    @MainActor
    public static var defaultFileStatePath: String = {
        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return "~/App"
        }

        return fileStatePath(inDocumentsDirectory: path)
    }()

    /// The "App" directory inside `documentsDirectory`, as a plain file path.
    ///
    /// The path is not percent-encoded. It is later passed to `URL(filePath:)`, which takes its
    /// argument literally, so an encoded space would name a directory that does not exist.
    static func fileStatePath(inDocumentsDirectory documentsDirectory: URL) -> String {
        #if canImport(Security)
        if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            return documentsDirectory.appending(path: "App").path(percentEncoded: false)
        } else {
            return "\(documentsDirectory.path)/App"
        }
        #else
        return "\(documentsDirectory.path)/App"
        #endif
    }

    /// Creates a directory at the specified path.
    ///
    /// - Parameters:
    ///   - path: The path at which to create the directory.
    /// - Throws: An error if the directory could not be created.
    func createDirectory(path: String) throws {
        try createDirectory(atPath: path, withIntermediateDirectories: true)
    }

    /// Read a file's data as the type `Value`
    ///
    /// - Parameters:
    ///   - path: The path to the directory containing the file. The default is `.`, which means the current working directory.
    ///   - filename: The name of the file to read.
    /// - Returns: The file's data decoded as an instance of `Value`.
    /// - Throws: If there's an error reading the file or decoding its data.
    func `in`<Value: Decodable>(
        path: String = ".",
        filename: String
    ) throws -> Value {
        let directoryURL: URL = url(filePath: path)
        let fileData = try Data(
            contentsOf: directoryURL.appendingPathComponent(filename)
        )

        guard let base64DecodedData = Data(base64Encoded: fileData) else {
            return try JSONDecoder().decode(Value.self, from: fileData)
        }

        do {
            return try JSONDecoder().decode(Value.self, from: base64DecodedData)
        } catch {
            // A file written without Base64 can still be valid Base64: `true`, `null`, `1234`.
            // Its Base64 reading is not JSON, so read the bytes as they are.
            guard let value = try? JSONDecoder().decode(Value.self, from: fileData) else {
                throw error
            }

            return value
        }
    }

    /// Read a file's data
    ///
    /// - Parameters:
    ///   - path: The path to the directory containing the file. The default is `.`, which means the current working directory.
    ///   - filename: The name of the file to read.
    /// - Returns: The file's data.
    /// - Throws: If there's an error reading the file.
    func data(
        path: String = ".",
        filename: String
    ) throws -> Data {
        let directoryURL: URL = url(filePath: path)

        let fileData = try Data(
            contentsOf: directoryURL.appendingPathComponent(filename)
        )

        guard let base64DecodedData = Data(base64Encoded: fileData) else {
            return fileData
        }

        return base64DecodedData
    }

    /// Write data to a file using a JSONEncoder
    ///
    /// - Parameters:
    ///   - value: The data to write to the file. It must conform to the `Encodable` protocol.
    ///   - path: The path to the directory where the file should be written. The default is `.`, which means the current working directory.
    ///   - filename: The name of the file to write.
    ///   - base64Encoded: A Boolean value indicating whether the data should be Base64-encoded before writing to the file. The default is `true`.
    /// - Throws: If there's an error writing the data to the file.
    func out<Value: Encodable>(
        _ value: Value,
        path: String = ".",
        filename: String,
        base64Encoded: Bool = true
    ) throws {
        let data = try JSONEncoder().encode(value)

        try out(
            data: data,
            path: path,
            filename: filename,
            base64Encoded: base64Encoded
        )
    }

    /// Write data to a file
    ///
    /// - Parameters:
    ///   - value: The data to write to the file.
    ///   - path: The path to the directory where the file should be written. The default is `.`, which means the current working directory.
    ///   - filename: The name of the file to write.
    ///   - base64Encoded: A Boolean value indicating whether the data should be Base64-encoded before writing to the file. The default is `true`.
    /// - Throws: If there's an error writing the data to the file.
    func out(
        data: Data,
        path: String = ".",
        filename: String,
        base64Encoded: Bool = true
    ) throws {
        let directoryURL: URL = url(filePath: path)

        var data = data

        if base64Encoded {
            data = data.base64EncodedData()
        }

        if fileExists(atPath: path) == false {
            try createDirectory(path: path)
        }

        try data.write(
            to: directoryURL.appendingPathComponent(filename)
        )
    }

    /// Delete a file
    ///
    /// - Parameters:
    ///   - path: The path to the directory containing the file. The default is `.`, which means the current working directory.
    ///   - filename: The name of the file to delete.
    /// - Throws: If there's an error deleting the file.
    func delete(
        path: String = ".",
        filename: String
    ) throws {
        let directoryURL: URL = url(filePath: path)

        try removeItem(
            at: directoryURL.appendingPathComponent(filename)
        )
    }

    func url(filePath: String) -> URL {
        #if canImport(Security)
        if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            return URL(filePath: filePath)
        } else {
            return URL(fileURLWithPath: filePath)
        }
        #else
        return URL(fileURLWithPath: filePath)
        #endif
    }
}
