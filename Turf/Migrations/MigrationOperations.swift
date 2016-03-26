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

    // TODO
//    public func deleteCollection(name: String) throws {
//
//    }

    public func createCollection(name: String) throws {
        try SQLiteCollection.createCollectionTableNamed(name, db: sqlite.db)
    }

    public func enumerateValuesInCollection(name: String, each: (key: String, version: UInt64, value: NSData) -> Bool) throws {
        try sqliteCollectionFor(name).enumerateKeySchemaVersionAndValueDataInCollection(each)
    }

    public func setSerializedValue(serializedValue: NSData, Key key: String, version: UInt64, inCollection name: String) throws {
        try sqliteCollectionFor(name).setValueData(serializedValue, valueSchemaVersion: version, forKey: key)
    }

    public func getSerializedValueWithKey(key: String, inCollection name: String) throws -> (valueData: NSData, schemaVersion: UInt64)? {
        return try sqliteCollectionFor(name).valueDataForKey(key)
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