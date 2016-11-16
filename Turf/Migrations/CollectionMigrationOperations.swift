open class CollectionMigrationOperations {
    // MARK: Private properties
    fileprivate let operations: MigrationOperations
    fileprivate let collectionName: String
    fileprivate let toSchemaVersion: UInt64

    // MARK: Object lifecycle

    init(operations: MigrationOperations, collectionName: String, toSchemaVersion: UInt64) {
        self.operations = operations
        self.collectionName = collectionName
        self.toSchemaVersion = toSchemaVersion
    }

    open func removeValueWithKey(_ key: String) throws {
        try operations.removeValueWithKey(key, inCollection: collectionName)
    }

    open func setSerializedValue(_ serializedValue: Data, key: String) throws {
        try operations.setSerializedValue(serializedValue, key: key, version: toSchemaVersion, inCollection: collectionName)
    }

    open func getSerializedValueWithKey(_ key: String, inCollection name: String) throws -> (valueData: Data, schemaVersion: UInt64)? {
        return try operations.getSerializedValueWithKey(key, inCollection: name)
    }
}
