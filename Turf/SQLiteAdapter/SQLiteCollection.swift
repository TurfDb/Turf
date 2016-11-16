//TODO Add some better error handling checking binds etc
internal final class SQLiteCollection {
    // MARK: Internal properties

    fileprivate(set) var allValuesInCollectionStmt: OpaquePointer? = nil

    // MARK: Private properties

    fileprivate let db: OpaquePointer
    fileprivate let collectionName: String

    fileprivate var numberOfKeysInCollectionStmt: OpaquePointer? = nil
    fileprivate var numberOfKeysAtVersionInCollectionStmt: OpaquePointer? = nil
    fileprivate var keysInCollectionStmt: OpaquePointer? = nil
    fileprivate var valueDataForKeyStmt: OpaquePointer? = nil
    fileprivate var rowIdForKeyStmt: OpaquePointer? = nil
    fileprivate var insertValueDataStmt: OpaquePointer? = nil
    fileprivate var updateValueDataStmt: OpaquePointer? = nil
    fileprivate var removeValueStmt: OpaquePointer? = nil
    fileprivate var removeAllValuesStmt: OpaquePointer? = nil
    fileprivate var allKeysAndValuesStmt: OpaquePointer? = nil

    // MARK: Object lifecycle

    init(db: OpaquePointer, collectionName: String) throws {
        self.db = db
        self.collectionName = collectionName
        try setUpAllValuesInCollectionStmt()
        try setUpNumberOfKeysInCollectionStmt()
        try setUpNumberOfKeysAtVersionInCollectionStmt()
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
        sqlite3_finalize(numberOfKeysAtVersionInCollectionStmt)
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
    static func createCollectionTableNamed(_ name: String, db: OpaquePointer) throws {
        if sqlite3_exec(db,
            "CREATE TABLE IF NOT EXISTS `\(name)` (" +
                "    key TEXT NOT NULL UNIQUE," +
                "    valueData BLOB," +
                "    schemaVersion INTEGER DEFAULT 0" +
            ");" +
            "CREATE INDEX IF NOT EXISTS `\(name)_schemaVersion_idx` ON \(name) (schemaVersion);",
            nil, nil, nil).isNotOK {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    /**
     Drop a collection table.
     */
    static func dropCollectionTableNamed(_ name: String, db: OpaquePointer) throws {
        if sqlite3_exec(db,
            "DROP TABLE IF EXISTS `\(name)`;",
            nil, nil, nil).isNotOK {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    /**
     Drop all collection tables, leaving only Turf tables
     - returns: Names of dropped tables
     */
    static func dropAllCollectionTables(db: OpaquePointer) throws -> [String] {
        let collectionTableNames = collectionNames(db: db)
        for name in collectionTableNames {
            try dropCollectionTableNamed(name, db: db)
        }

        return collectionTableNames
    }

    /**
     - returns: Count of user collections in the database.
     */
    static func numberOfCollections(_ db: OpaquePointer) -> UInt {
        var stmt: OpaquePointer? = nil

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
    static func collectionNames(db: OpaquePointer) -> [String] {
        var stmt: OpaquePointer? = nil

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
            if let name = String(validatingUTF8: UnsafePointer(sqlite3_column_text(stmt, nameColumnIndex))) {
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
     - returns: Number of keys in `collection`.
     */
    func numberOfKeysInCollectionAtSchemaVersion(_ schemaVersion: UInt64) -> UInt {
        defer { sqlite3_reset(numberOfKeysAtVersionInCollectionStmt) }

        let schemaVersionIndex = SQLITE_FIRST_BIND_COLUMN
        let numberOfKeysIndex = SQLITE_FIRST_COLUMN

        sqlite3_bind_int64(numberOfKeysAtVersionInCollectionStmt, schemaVersionIndex, Int64(schemaVersion))

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
            if let key = String(validatingUTF8: UnsafePointer(sqlite3_column_text(keysInCollectionStmt, keyColumnIndex))) {
                keys.append(key)
            }
            result = sqlite3_step(keysInCollectionStmt)
        }
        
        return keys
    }

    func enumerateKeySchemaVersionAndValueDataInCollection(_ enumerate: (String, UInt64, Data) -> Bool) {
        defer { sqlite3_reset(allKeysAndValuesStmt) }

        let keyColumnIndex = SQLITE_FIRST_COLUMN
        let schemaVersionColumnIndex = SQLITE_FIRST_COLUMN + 1
        let valueDataColumnIndex = SQLITE_FIRST_COLUMN + 2

        var result = sqlite3_step(keysInCollectionStmt)

        while(result.hasRow) {
            if let key = String(validatingUTF8: UnsafePointer(sqlite3_column_text(keysInCollectionStmt, keyColumnIndex))) {

                let valueData: Data
                if let bytes = sqlite3_column_blob(valueDataForKeyStmt, valueDataColumnIndex){
                    let bytesLength = Int(sqlite3_column_bytes(valueDataForKeyStmt, valueDataColumnIndex))
                    valueData = Data(bytes: bytes, count: bytesLength)
                } else {
                    valueData = Data()
                }

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
    func valueDataForKey(_ key: String) -> (valueData: Data, schemaVersion: UInt64)? {
        defer { sqlite3_reset(valueDataForKeyStmt) }

        let keyIndex = SQLITE_FIRST_BIND_COLUMN
        let valueDataColumnIndex = SQLITE_FIRST_COLUMN
        let schemaVersionColumnIndex = SQLITE_FIRST_COLUMN + 1

        sqlite3_bind_text(valueDataForKeyStmt, keyIndex, key, -1, SQLITE_TRANSIENT)

        if sqlite3_step(valueDataForKeyStmt).hasRow {
            let valueData: Data
            if let bytes = sqlite3_column_blob(valueDataForKeyStmt, valueDataColumnIndex){
                let bytesLength = Int(sqlite3_column_bytes(valueDataForKeyStmt, valueDataColumnIndex))
                valueData = Data(bytes: bytes, count: bytesLength)
            } else {
                valueData = Data()
            }

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
    func rowIdForKey(_ key: String) -> Int64? {
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
    func setValueData(_ valueData: Data, valueSchemaVersion: UInt64, forKey key: String) throws -> SQLiteRowChangeType {

        var stmt: OpaquePointer? = nil

        if let rowId = rowIdForKey(key) {
            defer { sqlite3_reset(updateValueDataStmt) }

            let dataIndex = SQLITE_FIRST_BIND_COLUMN
            let schemaVersionIndex = SQLITE_FIRST_BIND_COLUMN + 1
            let keyIndex = SQLITE_FIRST_BIND_COLUMN + 2

            sqlite3_bind_blob(updateValueDataStmt, dataIndex, (valueData as NSData).bytes, Int32(valueData.count), nil)
            sqlite3_bind_int64(updateValueDataStmt, schemaVersionIndex, Int64(valueSchemaVersion))
            sqlite3_bind_text(updateValueDataStmt, keyIndex, key, -1, SQLITE_TRANSIENT)

            if sqlite3_step(updateValueDataStmt).isNotDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            } else {
                return .update(rowId: rowId)
            }
        } else {
            defer { sqlite3_reset(insertValueDataStmt) }

            let keyIndex = SQLITE_FIRST_BIND_COLUMN
            let dataIndex = SQLITE_FIRST_BIND_COLUMN + 1
            let schemaVersionIndex = SQLITE_FIRST_BIND_COLUMN + 2

            sqlite3_bind_blob(insertValueDataStmt, dataIndex, (valueData as NSData).bytes, Int32(valueData.count), nil)
            sqlite3_bind_int64(insertValueDataStmt, schemaVersionIndex, Int64(valueSchemaVersion))
            sqlite3_bind_text(insertValueDataStmt, keyIndex, key, -1, SQLITE_TRANSIENT)

            if sqlite3_step(insertValueDataStmt).isNotDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            } else {
                return .insert(rowId: sqlite3_last_insert_rowid(db))
            }
        }
    }

    func removeValueWithKey(_ key: String) throws {
        defer { sqlite3_reset(removeAllValuesStmt) }

        let keyIndex = SQLITE_FIRST_BIND_COLUMN
        sqlite3_bind_text(insertValueDataStmt, keyIndex, key, -1, SQLITE_TRANSIENT)

        if sqlite3_step(removeAllValuesStmt).isNotDone {
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    func removeAllValues() throws {
        defer { sqlite3_reset(removeAllValuesStmt) }
        if sqlite3_step(removeAllValuesStmt).isNotDone {
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    // MARK: Private methods

    fileprivate func setUpAllValuesInCollectionStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "SELECT valueData, schemaVersion FROM `\(collectionName)`", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        self.allValuesInCollectionStmt = stmt
    }

    fileprivate func setUpRemoveValueInCollectionStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "DELETE FROM `\(collectionName)` WHERE key=?;", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        self.removeValueStmt = stmt
    }

    fileprivate func setUpRemoveAllValuesInCollectionStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "DELETE FROM `\(collectionName)`;", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        self.removeAllValuesStmt = stmt
    }

    fileprivate func setUpNumberOfKeysInCollectionStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "SELECT COUNT(key) FROM `\(collectionName)`", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.numberOfKeysInCollectionStmt = stmt
    }

    fileprivate func setUpNumberOfKeysAtVersionInCollectionStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "SELECT COUNT(key) FROM `\(collectionName)` WHERE schemaVersion=?", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.numberOfKeysAtVersionInCollectionStmt = stmt
    }

    fileprivate func setUpKeysInCollectionStmt() throws {
        var stmt: OpaquePointer? = nil

        defer { sqlite3_reset(stmt) }
        guard sqlite3_prepare_v2(db, "SELECT key FROM `\(collectionName)`", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        self.keysInCollectionStmt = stmt
    }

    fileprivate func setUpValueDataForKeyStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "SELECT valueData, schemaVersion FROM `\(collectionName)` WHERE key=? LIMIT 1", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        self.valueDataForKeyStmt = stmt
    }

    fileprivate func setUpRowIdForKeyStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "SELECT rowid FROM `\(collectionName)` WHERE key=?;", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        self.rowIdForKeyStmt = stmt
    }

    fileprivate func setUpInsertValueDataStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "INSERT INTO `\(collectionName)` (key, valueData, schemaVersion) VALUES (?,?,?);", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        self.insertValueDataStmt = stmt
    }

    fileprivate func setUpUpdateValueDataStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "UPDATE `\(collectionName)` SET valueData=?,schemaVersion=? WHERE key=?;", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }
        
        self.updateValueDataStmt = stmt
    }

    fileprivate func setUpAllKeysAndValuesStmt() throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "SELECT key, valueData, schemaVersion FROM `\(collectionName)`", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        self.allKeysAndValuesStmt = stmt
    }
}
