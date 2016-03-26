//TODO Add some better error handling checking binds etc
internal final class SQLiteCollection {
    // MARK: Internal properties

    private(set) var allValuesInCollectionStmt: COpaquePointer = nil

    // MARK: Private properties

    private let db: COpaquePointer
    private let collectionName: String

    private var numberOfKeysInCollectionStmt: COpaquePointer = nil
    private var keysInCollectionStmt: COpaquePointer = nil
    private var valueDataForKeyStmt: COpaquePointer = nil
    private var rowIdForKeyStmt: COpaquePointer = nil
    private var insertValueDataStmt: COpaquePointer = nil
    private var updateValueDataStmt: COpaquePointer = nil
    private var removeValueStmt: COpaquePointer = nil
    private var removeAllValuesStmt: COpaquePointer = nil
    private var allKeysAndValuesStmt: COpaquePointer = nil

    // MARK: Object lifecycle

    init(db: COpaquePointer, collectionName: String) throws {
        self.db = db
        self.collectionName = collectionName
        try setUpAllValuesInCollectionStmt()
        try setUpNumberOfKeysInCollectionStmt()
        try setUpKeysInCollectionStmt()
        try setUpValueDataForKeyStmt()
        try setUpRowIdForKeyStmt()
        try setUpInsertValueDataStmt()
        try setUpUpdateValueDataStmt()
        try setUpRemoveValueInCollectionStmt()
        try setUpRemoveAllValuesInCollectionStmt()
    }

    deinit {
        sqlite3_finalize(allValuesInCollectionStmt)
        sqlite3_finalize(numberOfKeysInCollectionStmt)
        sqlite3_finalize(keysInCollectionStmt)
        sqlite3_finalize(valueDataForKeyStmt)
        sqlite3_finalize(rowIdForKeyStmt)
        sqlite3_finalize(insertValueDataStmt)
        sqlite3_finalize(updateValueDataStmt)
        sqlite3_finalize(removeValueStmt)
        sqlite3_finalize(removeAllValuesStmt)
        sqlite3_finalize(allKeysAndValuesStmt)
    }

    // MARK: Internal methods

    /**
     Create a new table called `name`.
     */
    static func createCollectionTableNamed(name: String, db: COpaquePointer) throws {
        if sqlite3_exec(db,
            "CREATE TABLE IF NOT EXISTS `\(name)` (" +
                "    `key` TEXT NOT NULL UNIQUE," +
                "    `valueData` BLOB," +
                "    `schemaVersion` INTEGER DEFAULT 0" +
            ");",
            nil, nil, nil).isNotOK {
                throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    /**
     Drop a collection table.
     */
    static func dropCollectionTableNamed(name: String, db: COpaquePointer) throws {
        if sqlite3_exec(db,
            "DROP TABLE IF EXISTS \(name);",
            nil, nil, nil).isNotOK {
                throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    /**
     - returns: Count of user collections in the database.
     */
    static func numberOfCollections(db: COpaquePointer) -> UInt {
        var stmt: COpaquePointer = nil

        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, "SELECT COUNT(name) FROM sqlite_master where type='table' AND name NOT LIKE ?;", -1, &stmt, nil).isOK else {
            return 0
        }

        let notLikeTableNameIndex = SQLITE_FIRST_BIND_COLUMN
        let numberOfCollectionsIndex = SQLITE_FIRST_COLUMN

        sqlite3_bind_text(stmt, notLikeTableNameIndex, "\(TurfTablePrefix)%", -1, SQLITE_TRANSIENT)

        var numberOfCollections: UInt = 0
        if sqlite3_step(stmt).hasRow {
            numberOfCollections = UInt(sqlite3_column_int64(stmt, numberOfCollectionsIndex))
        }

        return numberOfCollections
    }

    /**
     - returns: Names of each user collection in the database.
     */
    static func collectionNames(db db: COpaquePointer) -> [String] {
        var stmt: COpaquePointer = nil

        defer { sqlite3_reset(stmt) }
        guard sqlite3_prepare_v2(db, "SELECT name, type FROM sqlite_master WHERE type='table' AND name NOT LIKE ?;", -1, &stmt, nil).isOK else {
            return []
        }


        let notLikeTableNameIndex = SQLITE_FIRST_BIND_COLUMN
        let nameColumnIndex = SQLITE_FIRST_COLUMN

        sqlite3_bind_text(stmt, notLikeTableNameIndex, "\(TurfTablePrefix)%", -1, SQLITE_TRANSIENT)

        var collectionNames = [String]()
        var result = sqlite3_step(stmt)

        while(result.hasRow) {
            if let name = String.fromCString(UnsafePointer(sqlite3_column_text(stmt, nameColumnIndex))) {
                collectionNames.append(name)
            }
            result = sqlite3_step(stmt)
        }
        
        return collectionNames
    }

    /**
     - returns: Number of keys in `collection`.
     */
    func numberOfKeysInCollection() -> UInt {
        defer { sqlite3_reset(numberOfKeysInCollectionStmt) }

        let numberOfKeysIndex = SQLITE_FIRST_COLUMN

        var numberOfKeys: UInt = 0
        if sqlite3_step(numberOfKeysInCollectionStmt).hasRow {
            numberOfKeys =  UInt(sqlite3_column_int64(numberOfKeysInCollectionStmt, numberOfKeysIndex))
        }

        return numberOfKeys
    }

    /**
     - returns: All keys in `collection`.
     */
    func keysInCollection() -> [String] {
        defer { sqlite3_reset(keysInCollectionStmt) }

        let keyColumnIndex = SQLITE_FIRST_COLUMN

        var keys = [String]()
        var result = sqlite3_step(keysInCollectionStmt)

        while(result.hasRow) {
            if let key = String.fromCString(UnsafePointer(sqlite3_column_text(keysInCollectionStmt, keyColumnIndex))) {
                keys.append(key)
            }
            result = sqlite3_step(keysInCollectionStmt)
        }
        
        return keys
    }

    func enumerateKeySchemaVersionAndValueDataInCollection(enumerate: (String, UInt64, NSData) -> Bool) {
        defer { sqlite3_reset(allKeysAndValuesStmt) }

        let keyColumnIndex = SQLITE_FIRST_COLUMN
        let schemaVersionColumnIndex = SQLITE_FIRST_COLUMN + 1
        let valueDataColumnIndex = SQLITE_FIRST_COLUMN + 2

        var result = sqlite3_step(keysInCollectionStmt)

        while(result.hasRow) {
            if let key = String.fromCString(UnsafePointer(sqlite3_column_text(keysInCollectionStmt, keyColumnIndex))) {
                let bytes = sqlite3_column_blob(valueDataForKeyStmt, valueDataColumnIndex)
                let bytesLength = Int(sqlite3_column_bytes(valueDataForKeyStmt, valueDataColumnIndex))
                let valueData = NSData(bytes: bytes, length: bytesLength)

                let schemaVersion = UInt64(sqlite3_column_int64(valueDataForKeyStmt, schemaVersionColumnIndex))

                if !enumerate(key, schemaVersion, valueData) {
                    break
                }
            }
            result = sqlite3_step(keysInCollectionStmt)
        }
    }

    /**
     - parameter key: Primary key of the value.
     - parameter collection: Collection name.
     - returns: Serialized value and schema version of the persisted value.
     */
    func valueDataForKey(key: String) -> (valueData: NSData, schemaVersion: UInt64)? {
        defer { sqlite3_reset(valueDataForKeyStmt) }

        let keyIndex = SQLITE_FIRST_BIND_COLUMN
        let valueDataColumnIndex = SQLITE_FIRST_COLUMN
        let schemaVersionColumnIndex = SQLITE_FIRST_COLUMN + 1

        sqlite3_bind_text(valueDataForKeyStmt, keyIndex, key, -1, SQLITE_TRANSIENT)

        if sqlite3_step(valueDataForKeyStmt).hasRow {
            let bytes = sqlite3_column_blob(valueDataForKeyStmt, valueDataColumnIndex)
            let bytesLength = Int(sqlite3_column_bytes(valueDataForKeyStmt, valueDataColumnIndex))
            let valueData = NSData(bytes: bytes, length: bytesLength)

            let schemaVersion = UInt64(sqlite3_column_int64(valueDataForKeyStmt, schemaVersionColumnIndex))
            return (valueData: valueData, schemaVersion: schemaVersion)
        }

        return nil
    }

    /**
     - parameter key: Primary key.
     - parameter collection: Collection name.
     - returns: Internal sqlite rowid column value.
     */
    func rowIdForKey(key: String) -> Int64? {
        defer { sqlite3_reset(rowIdForKeyStmt) }

        let keyIndex = SQLITE_FIRST_BIND_COLUMN
        let rowIdIndex = SQLITE_FIRST_COLUMN

        sqlite3_bind_text(rowIdForKeyStmt, keyIndex, key, -1, SQLITE_TRANSIENT)

        var rowId: Int64? = nil
        if sqlite3_step(rowIdForKeyStmt).hasRow {
            rowId = sqlite3_column_int64(rowIdForKeyStmt, rowIdIndex)
        }

        return rowId
    }

    /**
     Set valueData for key and record the schema version of the data to support migrations.
     - parameter valueData: Serialized value bytes.
     - parameter valueSchemaVersion: Schema version of the valueData.
     - parameter key: Primary key.
     - paramter collection: Collection name.
     - returns: The row id and type of upsert operation (.Insert or .Update).
     */
    func setValueData(valueData: NSData, valueSchemaVersion: UInt64, forKey key: String) throws -> SQLiteRowChangeType {

        var stmt: COpaquePointer = nil

        if let rowId = rowIdForKey(key) {
            defer { sqlite3_reset(updateValueDataStmt) }

            let dataIndex = SQLITE_FIRST_BIND_COLUMN
            let schemaVersionIndex = SQLITE_FIRST_BIND_COLUMN + 1
            let keyIndex = SQLITE_FIRST_BIND_COLUMN + 2

            sqlite3_bind_blob(updateValueDataStmt, dataIndex, valueData.bytes, Int32(valueData.length), nil)
            sqlite3_bind_int64(updateValueDataStmt, schemaVersionIndex, Int64(valueSchemaVersion))
            sqlite3_bind_text(updateValueDataStmt, keyIndex, key, -1, SQLITE_TRANSIENT)

            if sqlite3_step(updateValueDataStmt).isNotDone {
                throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
            } else {
                return .Update(rowId: rowId)
            }
        } else {
            defer { sqlite3_reset(insertValueDataStmt) }

            let keyIndex = SQLITE_FIRST_BIND_COLUMN
            let dataIndex = SQLITE_FIRST_BIND_COLUMN + 1
            let schemaVersionIndex = SQLITE_FIRST_BIND_COLUMN + 2

            sqlite3_bind_blob(insertValueDataStmt, dataIndex, valueData.bytes, Int32(valueData.length), nil)
            sqlite3_bind_int64(insertValueDataStmt, schemaVersionIndex, Int64(valueSchemaVersion))
            sqlite3_bind_text(insertValueDataStmt, keyIndex, key, -1, SQLITE_TRANSIENT)

            if sqlite3_step(insertValueDataStmt).isNotDone {
                throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
            } else {
                return .Insert(rowId: sqlite3_last_insert_rowid(db))
            }
        }
    }

    func removeValueWithKey(key: String) throws {
        defer { sqlite3_reset(removeAllValuesStmt) }

        let keyIndex = SQLITE_FIRST_BIND_COLUMN
        sqlite3_bind_text(insertValueDataStmt, keyIndex, key, -1, SQLITE_TRANSIENT)

        if sqlite3_step(removeAllValuesStmt).isNotDone {
            throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    func removeAllValues() throws {
        defer { sqlite3_reset(removeAllValuesStmt) }
        if sqlite3_step(removeAllValuesStmt).isNotDone {
            throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    // MARK: Private methods

    private func setUpAllValuesInCollectionStmt() throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "SELECT valueData, schemaVersion FROM `\(collectionName)`", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        self.allValuesInCollectionStmt = stmt
    }

    private func setUpRemoveValueInCollectionStmt() throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "DELETE FROM `\(collectionName)` WHERE key=?;", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        self.removeValueStmt = stmt
    }

    private func setUpRemoveAllValuesInCollectionStmt() throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "DELETE FROM `\(collectionName)`;", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        self.removeAllValuesStmt = stmt
    }

    private func setUpNumberOfKeysInCollectionStmt() throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "SELECT COUNT(key) FROM `\(collectionName)`", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }
        self.numberOfKeysInCollectionStmt = stmt
    }

    private func setUpKeysInCollectionStmt() throws {
        var stmt: COpaquePointer = nil

        defer { sqlite3_reset(stmt) }
        guard sqlite3_prepare_v2(db, "SELECT key FROM `\(collectionName)`", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }
        self.keysInCollectionStmt = stmt
    }

    private func setUpValueDataForKeyStmt() throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "SELECT valueData, schemaVersion FROM `\(collectionName)` WHERE key=? LIMIT 1", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        self.valueDataForKeyStmt = stmt
    }

    private func setUpRowIdForKeyStmt() throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "SELECT rowid FROM `\(collectionName)` WHERE key=?;", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        self.rowIdForKeyStmt = stmt
    }

    private func setUpInsertValueDataStmt() throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "INSERT INTO `\(collectionName)` (`key`,`valueData`, `schemaVersion`) VALUES (?,?,?);", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        self.insertValueDataStmt = stmt
    }

    private func setUpUpdateValueDataStmt() throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "UPDATE `\(collectionName)` SET `valueData`=?,`schemaVersion`=? WHERE key=?;", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }
        
        self.updateValueDataStmt = stmt
    }

    private func setUpAllKeysAndValuesStmt() throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "SELECT key, valueData, schemaVersion FROM `\(collectionName)`", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        self.allKeysAndValuesStmt = stmt
    }
}
