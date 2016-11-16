/// Prefix for internal Turf sqlite3 tables
internal let TurfTablePrefix = "__turf"
private let TurfMetadataTableName = "\(TurfTablePrefix)_metadata"
private let TurfRuntimeTableName = "\(TurfTablePrefix)_runtime"
private let TurfExtensionsTableName = "\(TurfTablePrefix)_extensions"

let SQLITE_FIRST_BIND_COLUMN = Int32(1)
let SQLITE_FIRST_COLUMN = Int32(0)
let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/**
 Wrapper around sqlite3
 */
internal final class SQLiteAdapter {
    typealias SQLStatement = OpaquePointer
    // MARK: Internal properties

    /// Connection state
    fileprivate(set) var isClosed: Bool

    /// sqlite3 pointer from `sqlite3_open`
    let db: OpaquePointer

    // MARK: Private properties

    fileprivate var beginDeferredTransactionStmt: SQLStatement!
    fileprivate var commitTransactionStmt: SQLStatement!
    fileprivate var rollbackTransactionStmt: SQLStatement!
    fileprivate var getSnapshotStmt: SQLStatement!
    fileprivate var setSnapshotStmt: SQLStatement!
    fileprivate var getExtensionDetailsStmt: SQLStatement!
    fileprivate var setExtensionDetailsStmt: SQLStatement!

    // MARK: Object lifecycle

    /**
     Open a sqlite3 connection
     - throws: SQLiteError.FailedToOpenDatabase if sqlite3_open_v2 fails
     - parameter sqliteDatabaseUrl: Path to a sqlite database (will be created if it does not exist)
     */
    init(sqliteDatabaseUrl: URL) throws {
        var internalDb: OpaquePointer? = nil
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_PRIVATECACHE

        self.isClosed = true
        let success = sqlite3_open_v2(sqliteDatabaseUrl.absoluteString, &internalDb, flags, nil).isOK
        self.db = internalDb!

        if success {
            sqlite3_busy_timeout(self.db, 0/*ms*/)
            if sqlite3_exec(db, "PRAGMA journal_mode = WAL;", nil, nil, nil).isNotOK {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }

            try createMetadataTable()
            try createRuntimeOperationsTable()
            try createExtensionsTable()
            try prepareStatements()
            self.isClosed = false
        } else {
            self.beginDeferredTransactionStmt = nil
            self.commitTransactionStmt = nil
            self.rollbackTransactionStmt = nil
            self.getSnapshotStmt = nil
            self.setSnapshotStmt = nil
            throw SQLiteError.failedToOpenDatabase
        }
    }

    deinit {
        precondition(isClosed, "sqlite connection must be closed before deinitializing")
    }

    // MARK: Internal methods

    /**
     Close the sqlite3 connection
     */
    func close() {
        guard !isClosed else { return }

        finalizePreparedStatements()
        sqlite3_close_v2(db)
        self.isClosed = true
    }

    /**
     SQL: BEGIN DEFERRED TRANSACTION;
     */
    func beginDeferredTransaction() throws {
        sqlite3_reset(beginDeferredTransactionStmt)
        if sqlite3_step(beginDeferredTransactionStmt).isNotDone {
            Logger.log(error: "Could not begin transaction - SQLite error")
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_reset(beginDeferredTransactionStmt)
    }

    /**
     SQL: COMMIT TRANSACTION;
     */
    func commitTransaction() throws {
        sqlite3_reset(self.commitTransactionStmt)
        if sqlite3_step(commitTransactionStmt).isNotDone {
            Logger.log(error: "Could not commit transaction - SQLite error")
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_reset(beginDeferredTransactionStmt)
    }

    /**
     SQL: ROLLBACK TRANSACTION;
     */
    func rollbackTransaction() throws {
        sqlite3_reset(beginDeferredTransactionStmt)
        if sqlite3_step(rollbackTransactionStmt).isNotDone {
            Logger.log(error: "Could not rollback transaction - SQLite error")
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    /**
     Fetch current transaction's snapshot number from the runtime table
     - warning: Error handling yet to come
     */
    func databaseSnapshotOnCurrentSqliteTransaction() -> UInt64 {
        defer { sqlite3_reset(getSnapshotStmt) }
        guard sqlite3_step(getSnapshotStmt).hasRow else { return 0 }

        return UInt64(sqlite3_column_int64(getSnapshotStmt, SQLITE_FIRST_COLUMN))
    }

    /**
     Set snapshot number in the runtime table
     */
    func setSnapshot(_ snapshot: UInt64) throws {
        sqlite3_bind_int64(setSnapshotStmt, SQLITE_FIRST_BIND_COLUMN, Int64(snapshot))
        if sqlite3_step(setSnapshotStmt).isNotDone {
            Logger.log(error: "Could not set snapshot - SQLite error")
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_reset(setSnapshotStmt)
    }

    /**
     Each installed extension gets a row in a turf metadata table for extensions tracking versions and extension data.
     - returns: Extension's version, turf version in case the extension is potentially refactored and a blob of data that could be associated with the extension's installation.
     */
    func getDetailsForExtensionWithName(_ name: String) -> ExistingExtensionInstallation? {
        defer { sqlite3_reset(getExtensionDetailsStmt) }

        let nameIndex = SQLITE_FIRST_BIND_COLUMN
        sqlite3_bind_text(getExtensionDetailsStmt, nameIndex, name, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(getExtensionDetailsStmt).hasRow else { return nil }

        let versionIndex = SQLITE_FIRST_COLUMN
        let dataIndex = SQLITE_FIRST_COLUMN + 1
        let turfVersionIndex = SQLITE_FIRST_COLUMN + 2

        let version = UInt64(sqlite3_column_int64(getExtensionDetailsStmt, versionIndex))

        let data: Data
        if let bytes = sqlite3_column_blob(getExtensionDetailsStmt, dataIndex){
            let bytesLength = Int(sqlite3_column_bytes(getExtensionDetailsStmt, dataIndex))
            data = Data(bytes: bytes, count: bytesLength)
        } else {
            data = Data()
        }

        let turfVersion = UInt64(sqlite3_column_int64(getExtensionDetailsStmt, turfVersionIndex))

        return ExistingExtensionInstallation(version: version, turfVersion: turfVersion, data: data)
    }

    func setDetailsForExtension(name: String, version: UInt64, turfVersion: UInt64, data: Data) {
        defer { sqlite3_reset(setExtensionDetailsStmt) }

        let nameIndex = SQLITE_FIRST_BIND_COLUMN
        let versionIndex = SQLITE_FIRST_BIND_COLUMN + 1
        let dataIndex = SQLITE_FIRST_BIND_COLUMN + 2
        let turfVersionIndex = SQLITE_FIRST_BIND_COLUMN + 3

        sqlite3_bind_text(setExtensionDetailsStmt, nameIndex, name, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(setExtensionDetailsStmt, versionIndex, Int64(version))
        sqlite3_bind_blob(setExtensionDetailsStmt, dataIndex, (data as NSData).bytes, Int32(data.count), nil)
        sqlite3_bind_int64(setExtensionDetailsStmt, turfVersionIndex, Int64(turfVersion))
        if sqlite3_step(setExtensionDetailsStmt).isNotDone {
            print("ERROR: Could not set extension details")
            print(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
    }

    // MARK: Private methods

    fileprivate func prepareStatements() throws {
        var beginDeferredTransactionStmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, "BEGIN TRANSACTION;",  -1, &beginDeferredTransactionStmt, nil).isNotOK {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.beginDeferredTransactionStmt = beginDeferredTransactionStmt

        var commitTransactionStmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, "COMMIT TRANSACTION;",  -1, &commitTransactionStmt, nil).isNotOK {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.commitTransactionStmt = commitTransactionStmt

        var rollbackTransactionStmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, "ROLLBACK TRANSACTION;",  -1, &rollbackTransactionStmt, nil).isNotOK {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.rollbackTransactionStmt = rollbackTransactionStmt

        var getSnapshotStmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, "SELECT snapshot FROM `\(TurfRuntimeTableName)` WHERE key=1;",  -1, &getSnapshotStmt, nil).isNotOK {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.getSnapshotStmt = getSnapshotStmt

        var setSnapshotStmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO `\(TurfRuntimeTableName)` (key, snapshot) VALUES (1, ?);",  -1, &setSnapshotStmt, nil).isNotOK {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.setSnapshotStmt = setSnapshotStmt

        var getExtensionDetailsStmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, "SELECT version, data, turfVersion FROM `\(TurfExtensionsTableName)` WHERE name=?;",  -1, &getExtensionDetailsStmt, nil).isNotOK {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.getExtensionDetailsStmt = getExtensionDetailsStmt

        var setExtensionDetailsStmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO `\(TurfExtensionsTableName)` (name, version, data, turfVersion) VALUES (?, ?, ?, 0);",  -1, &setExtensionDetailsStmt, nil).isNotOK {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.setExtensionDetailsStmt = setExtensionDetailsStmt
    }

    fileprivate func finalizePreparedStatements() {
        if let stmt = beginDeferredTransactionStmt {
            sqlite3_finalize(stmt)
        }
        if let stmt = commitTransactionStmt {
            sqlite3_finalize(stmt)
        }
        if let stmt = rollbackTransactionStmt {
            sqlite3_finalize(stmt)
        }
        if let stmt = getSnapshotStmt {
            sqlite3_finalize(stmt)
        }
        if let stmt = setSnapshotStmt {
            sqlite3_finalize(stmt)
        }
        if let stmt = getExtensionDetailsStmt {
            sqlite3_finalize(stmt)
        }
        if let stmt = setExtensionDetailsStmt {
            sqlite3_finalize(stmt)
        }
    }

    fileprivate func createMetadataTable() throws {
        if sqlite3_exec(db,
            "CREATE TABLE IF NOT EXISTS `\(TurfMetadataTableName)` (schemaVersion INTEGER NOT NULL DEFAULT '(1)' );", nil, nil, nil).isNotOK {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    fileprivate func createExtensionsTable() throws {
        let sql = "CREATE TABLE IF NOT EXISTS `\(TurfExtensionsTableName)` (" +
                  "name TEXT NOT NULL UNIQUE," +
                  "version INTEGER NOT NULL DEFAULT '(0)'," +
                  "data BLOB," +
                  "turfVersion INTEGER NOT NULL DEFAULT '(0)'," +
                  "PRIMARY KEY(name)" +
                  ");"
        if sqlite3_exec(db,
            sql, nil, nil, nil).isNotOK {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    fileprivate func createRuntimeOperationsTable() throws {
        if sqlite3_exec(db,
            "CREATE TABLE IF NOT EXISTS `\(TurfRuntimeTableName)`" +
                "(key INTEGER NOT NULL UNIQUE," +
                "snapshot INTEGER NOT NULL DEFAULT '(0)'" +
            ");", nil, nil, nil).isNotOK {
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
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

///http://ericasadun.com/2014/07/04/swift-my-love-for-postfix-printing/
postfix operator ***
postfix func *** <T>(object : T) -> T {
    if let i = object as? Int32 {
        switch i {
        case SQLITE_ERROR: print("SQLITE_ERROR")
        case SQLITE_OK: print("SQLITE_OK")
        case SQLITE_DONE: print("SQLITE_DONE")
        case SQLITE_ROW: print("SQLITE_ROW")
        case SQLITE_MISUSE: print("SQLITE_MISUSE")
        case SQLITE_BUSY: print("SQLITE_BUSY")
        case SQLITE_LOCKED: print("SQLITE_LOCKED")
        default: print("#AnotherOne \(i)")
        }
    } else {
        print(object)
    }
    return object
}
