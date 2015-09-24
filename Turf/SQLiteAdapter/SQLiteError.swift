/**
 Low level errors from SQLite3
 */
public enum SQLiteError: ErrorType {
    /// When sqlite3_open_v2 returns something other than OK
    case FailedToOpenDatabase

    /// Any error from a sqlite3 call
    case Error(code: Int32, reason: String?)
}
