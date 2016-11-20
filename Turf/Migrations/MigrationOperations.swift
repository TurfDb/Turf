open class MigrationOperations {
    // MARK: Private properties

    private let sqlite: SQLiteAdapter
    private var sqliteCollectionCache: [String: SQLiteCollection]

    // MARK: Object lifecycle

    init(sqlite: SQLiteAdapter) {
        self.sqlite = sqlite
        self.sqliteCollectionCache = [:]
    }

    // MARK: Public methods

    open func remove(collection name: String) throws {
        try SQLiteCollection.dropCollectionTableNamed(name, db: sqlite.db)
    }

    open func create(collection name: String) throws {
        try SQLiteCollection.createCollectionTableNamed(name, db: sqlite.db)
    }

    open func enumerateValues(in name: String, each: @escaping (_ index: UInt, _ key: String, _ version: UInt64, _ value: Data) throws -> Bool) throws {
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

    open func removeValue(withKey key: String, in name: String) throws {
        try sqliteCollectionFor(name).removeValueWithKey(key)
    }

    open func set(serializedValue: Data, key: String, version: UInt64, in name: String) throws {
        try sqliteCollectionFor(name).setValueData(serializedValue, valueSchemaVersion: version, forKey: key)
    }

    open func getSerializedValue(for key: String, in name: String) throws -> (valueData: Data, schemaVersion: UInt64)? {
        return try sqliteCollectionFor(name).valueDataForKey(key)
    }

    open func countOfValues(in name: String) throws -> UInt {
        return try sqliteCollectionFor(name).numberOfKeysInCollection()
    }

    open func countOfValues(in name: String, atSchemaVersion version: UInt64) throws -> UInt {
        return try sqliteCollectionFor(name).numberOfKeysInCollectionAtSchemaVersion(version)
    }

    // MARK: Private methods

    private func sqliteCollectionFor(_ name: String) throws -> SQLiteCollection {
        if let cached = sqliteCollectionCache[name] {
            return cached
        } else {
            let collection = try SQLiteCollection(db: sqlite.db, collectionName: name)
            sqliteCollectionCache[name] = collection
            return collection
        }
    }
}
