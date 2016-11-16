/**
 Low level errors from SQLite3
 */
public enum SQLiteError: Error {
    /// When sqlite3_open_v2 returns something other than OK
    case failedToOpenDatabase

    /// Any error from a sqlite3 call
    case error(code: Int32, reason: String?)

    /// sqlite3_prepare_v2 failed
    case failedToPrepareStatement(Int32, String?)

    /// sqlite3_reset failed
    case failedToResetStatement(Int32, String?)

}
