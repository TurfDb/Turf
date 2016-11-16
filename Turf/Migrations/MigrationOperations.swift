open class MigrationOperations {
    // MARK: Private properties

    fileprivate let sqlite: SQLiteAdapter
    fileprivate var sqliteCollectionCache: [String: SQLiteCollection]

    // MARK: Object lifecycle

    init(sqlite: SQLiteAdapter) {
        self.sqlite = sqlite
        self.sqliteCollectionCache = [:]
    }

    // MARK: Public methods

    open func removeCollection(_ name: String) throws {
        try SQLiteCollection.dropCollectionTableNamed(name, db: sqlite.db)
    }

    open func createCollection(_ name: String) throws {
        try SQLiteCollection.createCollectionTableNamed(name, db: sqlite.db)
    }

    open func enumerateValuesInCollection(_ name: String, each: @escaping (_ index: UInt, _ key: String, _ version: UInt64, _ value: Data) throws -> Bool) throws {
        var index = UInt(0)
        var caughtError: Error? = nil

        try sqliteCollectionFor(name).enumerateKeySchemaVersionAndValueDataInCollection({ (key, version, value) -> Bool in
            var `continue` = true
            do {
                `continue` = try each(index, key, version, value)
                index += 1
            } catch {
                caughtError = error
                `continue` = false
            }
            return `continue`
        })

        if let error = caughtError {
            throw error
        }
    }

    open func removeValueWithKey(_ key: String, inCollection name: String) throws {
        try sqliteCollectionFor(name).removeValueWithKey(key)
    }

    open func setSerializedValue(_ serializedValue: Data, key: String, version: UInt64, inCollection name: String) throws {
        try sqliteCollectionFor(name).setValueData(serializedValue, valueSchemaVersion: version, forKey: key)
    }

    open func getSerializedValueWithKey(_ key: String, inCollection name: String) throws -> (valueData: Data, schemaVersion: UInt64)? {
        return try sqliteCollectionFor(name).valueDataForKey(key)
    }

    open func countOfValuesInCollection(_ name: String) throws -> UInt {
        return try sqliteCollectionFor(name).numberOfKeysInCollection()
    }

    open func countOfValuesInCollection(_ name: String, atSchemaVersion version: UInt64) throws -> UInt {
        return try sqliteCollectionFor(name).numberOfKeysInCollectionAtSchemaVersion(version)
    }

    // MARK: Private methods

    fileprivate func sqliteCollectionFor(_ name: String) throws -> SQLiteCollection {
        if let cached = sqliteCollectionCache[name] {
            return cached
        } else {
            let collection = try SQLiteCollection(db: sqlite.db, collectionName: name)
            sqliteCollectionCache[name] = collection
            return collection
        }
    }
}
