/**
 Low level errors from SQLite3
 */
public enum SQLiteError: ErrorType {
    /// When sqlite3_open_v2 returns something other than OK
    case FailedToOpenDatabase

    /// Any error from a sqlite3 call
    case Error(code: Int32, reason: String?)

    /// sqlite3_prepare_v2 failed
    case FailedToPrepareStatement(Int32, String?)

    /// sqlite3_reset failed
    case FailedToResetStatement(Int32, String?)

}
