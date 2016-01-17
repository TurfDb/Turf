let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)

internal final class SQLiteCollection {
    // MARK: Private properties

    private let db: COpaquePointer

    // MARK: Object lifecycle

    init(db: COpaquePointer) {
        self.db = db
    }

    // MARK: Internal methods

    /**
     Create a new table called `name`.
     */
    func createCollectionTableNamed(name: String) throws {
        if sqlite3_exec(db,
            "CREATE TABLE IF NOT EXISTS `\(name)` (" +
                "    `key` TEXT NOT NULL," +
                "    `valueData` BLOB," +
                "    `schemaVersion` INTEGER DEFAULT 0," +
                "    PRIMARY KEY(key)" +
            ");",
            nil, nil, nil).isNotOK {
                throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    /**
     Drop a collection table.
     */
    func dropCollectionTableNamed(name: String) throws {
        if sqlite3_exec(db,
            "DROP TABLE IF EXISTS \(name);",
            nil, nil, nil).isNotOK {
                throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    /**
     - returns: Count of user collections in the database.
     */
    func numberOfCollections() -> UInt {
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
    func collectionNames() -> [String] {
        var stmt: COpaquePointer = nil

        defer { sqlite3_finalize(stmt) }
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
    func numberOfKeysInCollectionNamed(collection: String) -> UInt {
        var stmt: COpaquePointer = nil

        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, "SELECT COUNT(key) FROM `\(collection)`", -1, &stmt, nil).isOK else {
            return 0
        }

        let numberOfKeysIndex = SQLITE_FIRST_COLUMN

        var numberOfKeys: UInt = 0
        if sqlite3_step(stmt).hasRow {
            numberOfKeys =  UInt(sqlite3_column_int64(stmt, numberOfKeysIndex))
        }

        return numberOfKeys
    }

    /**
     - returns: All keys in `collection`.
     */
    func keysInCollectionNamed(collection: String) -> [String] {
        var stmt: COpaquePointer = nil

        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, "SELECT key FROM `\(collection)`", -1, &stmt, nil).isOK else {
            return []
        }

        let keyColumnIndex = SQLITE_FIRST_COLUMN

        var keys = [String]()
        var result = sqlite3_step(stmt)

        while(result.hasRow) {
            if let key = String.fromCString(UnsafePointer(sqlite3_column_text(stmt, keyColumnIndex))) {
                keys.append(key)
            }
            result = sqlite3_step(stmt)
        }
        
        return keys
    }

    /**
     - parameter key: Primary key of the value.
     - parameter collection: Collection name.
     - returns: Serialized value and schema version of the persisted value.
     */
    func valueDataForKey(key: String, inCollectionNamed collection: String) -> (valueData: NSData, schemaVersion: UInt64)? {
        var stmt: COpaquePointer = nil

        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, "SELECT valueData, schemaVersion FROM `\(collection)` WHERE key=? LIMIT 1", -1, &stmt, nil).isOK else {
            return nil
        }
        let keyIndex = SQLITE_FIRST_BIND_COLUMN
        let valueDataColumnIndex = SQLITE_FIRST_COLUMN
        let schemaVersionColumnIndex = SQLITE_FIRST_COLUMN + 1

        sqlite3_bind_text(stmt, keyIndex, key, -1, SQLITE_TRANSIENT)

        if sqlite3_step(stmt).hasRow {
            let bytes = sqlite3_column_blob(stmt, valueDataColumnIndex)
            let bytesLength = Int(sqlite3_column_bytes(stmt, valueDataColumnIndex))
            let valueData = NSData(bytes: bytes, length: bytesLength)

            let schemaVersion = UInt64(sqlite3_column_int64(stmt, schemaVersionColumnIndex))
            return (valueData: valueData, schemaVersion: schemaVersion)
        }

        return nil
    }

    /**
     - parameter key: Primary key.
     - parameter collection: Collection name.
     - returns: Internal sqlite rowid column value.
     */
    func rowIdForKey(key: String, inCollectionNamed collection: String) -> Int64? {
        var stmt: COpaquePointer = nil

        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, "SELECT rowid FROM `\(collection)` WHERE key=?;", -1, &stmt, nil).isOK else {
            return nil
        }

        let keyIndex = SQLITE_FIRST_BIND_COLUMN
        let rowIdIndex = SQLITE_FIRST_COLUMN

        sqlite3_bind_text(stmt, keyIndex, key, -1, SQLITE_TRANSIENT)

        var rowId: Int64? = nil
        if sqlite3_step(stmt).hasRow {
            rowId = sqlite3_column_int64(stmt, rowIdIndex)
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
    func setValueData(valueData: NSData, valueSchemaVersion: UInt64, forKey key: String, inCollectionNamed collection: String) throws -> SQLiteRowChangeType {

        var stmt: COpaquePointer = nil
        defer { sqlite3_finalize(stmt) }

        if let rowId = rowIdForKey(key, inCollectionNamed: collection) {

            guard sqlite3_prepare_v2(db, "UPDATE `\(collection)` SET `valueData`=?,`schemaVersion`=? WHERE key=?;", -1, &stmt, nil).isOK else {
                throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
            }

            let dataIndex = SQLITE_FIRST_BIND_COLUMN
            let schemaVersionIndex = SQLITE_FIRST_BIND_COLUMN + 1
            let keyIndex = SQLITE_FIRST_BIND_COLUMN + 2

            sqlite3_bind_blob(stmt, dataIndex, valueData.bytes, Int32(valueData.length), nil)
            sqlite3_bind_int64(stmt, schemaVersionIndex, Int64(valueSchemaVersion))
            sqlite3_bind_text(stmt, keyIndex, key, -1, SQLITE_TRANSIENT)

            if sqlite3_step(stmt).isNotDone {
                throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
            } else {
                return .Update(rowId: rowId)
            }
        } else {
            guard sqlite3_prepare_v2(db, "INSERT INTO `\(collection)` (`key`,`valueData`, `schemaVersion`) VALUES (?,?,NULL);", -1, &stmt, nil).isOK else {
                throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
            }

            let keyIndex = SQLITE_FIRST_BIND_COLUMN
            let dataIndex = SQLITE_FIRST_BIND_COLUMN + 1
            let schemaVersionIndex = SQLITE_FIRST_BIND_COLUMN + 2

            sqlite3_bind_blob(stmt, dataIndex, valueData.bytes, Int32(valueData.length), nil)
            sqlite3_bind_int64(stmt, schemaVersionIndex, Int64(valueSchemaVersion))
            sqlite3_bind_text(stmt, keyIndex, key, -1, SQLITE_TRANSIENT)

            if sqlite3_step(stmt).isNotDone {
                throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
            } else {
                return .Insert(rowId: sqlite3_last_insert_rowid(db))
            }
        }
    }
}
