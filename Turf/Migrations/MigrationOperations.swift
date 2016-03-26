public class MigrationOperations {
    // MARK: Private properties

    private let sqlite: SQLiteAdapter
    private var sqliteCollectionCache: [String: SQLiteCollection]

    // MARK: Object lifecycle

    init(sqlite: SQLiteAdapter) {
        self.sqlite = sqlite
        self.sqliteCollectionCache = [:]
    }

    // MARK: Public methods

    public func removeCollection(name: String) throws {
        try SQLiteCollection.dropCollectionTableNamed(name, db: sqlite.db)
    }

    public func createCollection(name: String) throws {
        try SQLiteCollection.createCollectionTableNamed(name, db: sqlite.db)
    }

    public func enumerateValuesInCollection(name: String, each: (index: UInt, key: String, version: UInt64, value: NSData) throws -> Bool) throws {
        var index = UInt(0)
        var caughtError: ErrorType? = nil

        try sqliteCollectionFor(name).enumerateKeySchemaVersionAndValueDataInCollection({ (key, version, value) -> Bool in
            var `continue` = true
            do {
                `continue` = try each(index: index, key: key, version: version, value: value)
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

    public func removeValueWithKey(key: String, inCollection name: String) throws {
        try sqliteCollectionFor(name).removeValueWithKey(key)
    }

    public func setSerializedValue(serializedValue: NSData, key: String, version: UInt64, inCollection name: String) throws {
        try sqliteCollectionFor(name).setValueData(serializedValue, valueSchemaVersion: version, forKey: key)
    }

    public func getSerializedValueWithKey(key: String, inCollection name: String) throws -> (valueData: NSData, schemaVersion: UInt64)? {
        return try sqliteCollectionFor(name).valueDataForKey(key)
    }

    public func countOfValuesInCollection(name: String) throws -> UInt {
        return try sqliteCollectionFor(name).numberOfKeysInCollection()
    }

    public func countOfValuesInCollection(name: String, atVersion version: UInt64) -> UInt {
        
        return 0
    }

    // MARK: Private methods

    private func sqliteCollectionFor(name: String) throws -> SQLiteCollection {
        if let cached = sqliteCollectionCache[name] {
            return cached
        } else {
            let collection = try SQLiteCollection(db: sqlite.db, collectionName: name)
            sqliteCollectionCache[name] = collection
            return collection
        }
    }
}