public enum SQLiteError: Error {
    public enum BindingError: Error {
        case unsupportedType(Any)
    }

    case activeDatabase
    case bind(BindingError)
    case open(Int32)
    case prepare(Int32)
    case step(Int32)
}
