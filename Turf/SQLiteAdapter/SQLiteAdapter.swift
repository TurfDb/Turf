/// Prefix for internal Turf sqlite3 tables
internal let TurfTablePrefix = "_turf"

/**
 Wrapper around sqlite3
 */
internal final class SQLiteAdapter {
    // MARK: Internal properties

    /// Connection state
    private(set) var isClosed: Bool

    /// sqlite3 pointer from `sqlite3_open`
    let db: COpaquePointer

    // MARK: Object lifecycle

    /**
     Open a sqlite3 connection
     - throws: SQLiteError.FailedToOpenDatabase if sqlite3_open_v2 fails
     - parameter sqliteDatabaseUrl: Path to a sqlite database (will be created if it does not exist)
     */
    init(sqliteDatabaseUrl: NSURL) throws {
        var internalDb: COpaquePointer = nil
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_PRIVATECACHE

        let success = sqlite3_open_v2(sqliteDatabaseUrl.absoluteString, &internalDb, flags, nil).isOK
        self.db = internalDb
        self.isClosed = false

        if !success {
            self.isClosed = true
            throw SQLiteError.FailedToOpenDatabase
        }


        sqlite3_busy_timeout(self.db, 0/*off*/)
    }

    // MARK: Internal methods

    /**
     Close the sqlite3 connection
     */
    func close() {
        sqlite3_close_v2(db)
        self.isClosed = true
    }

    func beginDeferredTransaction() {

    }

    func commitTransaction() {

    }

    func rollbackTransaction() {
        
    }

    func databaseSnapshotOnCurrentSqliteTransaction() -> UInt64 {
        return 0
    }

    func setSnapshot(snapshot: UInt64) {
        
    }
}

internal extension Int32 {
    /// Compare self to SQLITE_OK
    var isOK: Bool {
        return self == SQLITE_OK
    }

    /// Compare self to SQLITE_OK
    var isNotOK: Bool {
        return self != SQLITE_OK
    }

    /// Compare self to SQLITE_DONE
    var isDone: Bool {
        return self == SQLITE_DONE
    }

    /// Compare self to SQLITE_DONE
    var isNotDone: Bool {
        return self != SQLITE_DONE
    }

    /// Compare self to SQLITE_ROW
    var hasRow: Bool {
        return self == SQLITE_ROW
    }
}
