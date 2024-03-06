import Foundation
import SQLite3

public enum DatabaseValue {
    case null
    case int64(Int64)
    case double(Double)
    case text(String)
    case blob(Data)

    public var isNull: Bool {
        if case .null = self {
            return true
        }

        return false
    }

    public var int: Int64? {
        guard case let .int64(int64) = self else {
            return nil
        }

        return int64
    }

    public var double: Double? {
        guard case let .double(double) = self else {
            return nil
        }

        return double
    }

    public var string: String? {
        guard case let .text(text) = self else {
            return nil
        }

        return text
    }

    public var data: Data? {
        guard case let .blob(blob) = self else {
            return nil
        }

        return blob
    }

    init(_ pointer: OpaquePointer?) throws {
        switch sqlite3_value_type(pointer) {
        case SQLITE_NULL:
            self = .null

        case SQLITE_INTEGER:
            self = .int64(sqlite3_value_int64(pointer))

        case SQLITE_FLOAT:
            self = .double(sqlite3_value_double(pointer))

        case SQLITE_TEXT:
            self = .text(String(cString: sqlite3_value_text(pointer)))

        case SQLITE_BLOB:
            guard let bytes = sqlite3_value_blob(pointer) else {
                self = .blob(Data())
                return
            }

            let count = Int(sqlite3_value_bytes(pointer))
            self = .blob(Data(bytes: bytes, count: count))

        case let type:
            throw SQLiteError.bind(.unsupportedType(type))
        }
    }

    init(_ pointer: OpaquePointer?, index: Int32) throws {
        switch sqlite3_column_type(pointer, index) {
        case SQLITE_NULL:
            self = .null

        case SQLITE_INTEGER:
            self = .int64(sqlite3_column_int64(pointer, index))

        case SQLITE_FLOAT:
            self = .double(sqlite3_column_double(pointer, index))

        case SQLITE_TEXT:
            self = .text(String(cString: sqlite3_column_text(pointer, index)))

        case SQLITE_BLOB:
            guard let bytes = sqlite3_column_blob(pointer, index) else {
                self = .blob(Data())
                return
            }

            let count = Int(sqlite3_column_bytes(pointer, index))
            self = .blob(Data(bytes: bytes, count: count))

        case let type:
            throw SQLiteError.bind(.unsupportedType(type))
        }
    }

    init(value: Any) throws {
        let mirror = Mirror(reflecting: value)

        guard mirror.children.isEmpty else {
            self = .null
            return
        }

        if let int64 = value as? Int64 {
            self = .int64(int64)
        } else if let double = value as? Double {
            self = .double(double)
        } else if let int = value as? Int {
            self = .int64(Int64(int))
        } else if let string = value as? String {
            self = .text(string)
        } else if let data = value as? Data {
            self = .blob(data)
        } else {
            throw SQLiteError.bind(.unsupportedType(value))
        }
    }

    func bind(statement: OpaquePointer?, index: Int32) {
        switch self {
        case .null:
            sqlite3_bind_null(statement, index)
        case .int64(let int64):
            sqlite3_bind_int64(statement, index, int64)
        case .double(let double):
            sqlite3_bind_double(statement, index, double)
        case .text(let string):
            sqlite3_bind_text(statement, index, string, -1, SQLITE_TRANSIENT)
        case .blob(let data):
            _ = data.withUnsafeBytes { pointer in
                sqlite3_bind_blob(
                    statement,
                    index,
                    pointer.baseAddress,
                    Int32(pointer.count),
                    SQLITE_TRANSIENT
                )
            }
        }
    }
}
