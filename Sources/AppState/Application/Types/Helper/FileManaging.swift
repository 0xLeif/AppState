/// A protocol that provides methods for reading, writing, and deleting files in a type-safe, sendable manner.
public protocol FileManaging: Sendable {

    /// Reads a file from the given path and decodes its contents into the specified type.
    /// - Parameters:
    ///   - path: The directory path where the file is located. Defaults to the current directory `"."`.
    ///   - filename: The name of the file to read.
    /// - Returns: The decoded value of the file's content as the specified type.
    /// - Throws: An error if the file cannot be found or decoded.
    func `in`<Value: Decodable>(path: String, filename: String) throws -> Value

    /// Encodes and writes the given value to a file at the specified path.
    /// - Parameters:
    ///   - value: The value to encode and write to the file. It must conform to `Encodable`.
    ///   - path: The directory path where the file will be written. Defaults to the current directory `"."`.
    ///   - filename: The name of the file to write.
    ///   - base64Encoded: Whether to encode the content as Base64. Defaults to `true`.
    /// - Throws: An error if the file cannot be written.
    func `out`<Value: Encodable>(_ value: Value, path: String, filename: String, base64Encoded: Bool) throws

    /// Deletes a file at the specified path.
    /// - Parameters:
    ///   - path: The directory path where the file is located. Defaults to the current directory `"."`.
    ///   - filename: The name of the file to delete.
    /// - Throws: An error if the file cannot be deleted.
    func `delete`(path: String, filename: String) throws

    /// Removes a file or directory at the specified path.
    /// - Parameter path: The full path of the file or directory to remove.
    /// - Throws: An error if the item cannot be removed.
    func removeItem(atPath path: String) throws
}
