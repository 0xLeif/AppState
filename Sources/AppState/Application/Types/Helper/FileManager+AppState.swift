import Foundation

extension FileManager {
    enum FileError: String, LocalizedError {
        case invalidStringFromData = "String could not be converted into Data."

        var errorDescription: String? { rawValue }
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
        let data = try data(
            path: path,
            filename: filename
        )

        return try JSONDecoder().decode(Value.self, from: data)
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

    /// Write a string to a file
    ///
    /// - Parameters:
    ///   - string: The string to write to the file.
    ///   - path: The path to the directory where the file should be written. The default is `.`, which means the current working directory.
    ///   - filename: The name of the file to write.
    ///   - using: The String.Encoding to encode the string with. The default is `.utf8`.
    ///   - base64Encoded: A Boolean value indicating whether the data should be Base64-encoded before writing to the file. The default is `true`.
    /// - Throws: If there's an error writing the data to the file.
    func out(
        string: String,
        path: String = ".",
        filename: String,
        using stringEncoding: String.Encoding = .utf8,
        base64Encoded: Bool = true
    ) throws {
        guard let data = string.data(using: stringEncoding) else {
            throw FileError.invalidStringFromData
        }

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
        #if !os(Linux) && !os(Windows)
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
