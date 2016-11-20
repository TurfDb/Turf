open class CollectionMigrationOperations {
    // MARK: Private properties
    private let operations: MigrationOperations
    private let collectionName: String
    private let toSchemaVersion: UInt64

    // MARK: Object lifecycle

    init(operations: MigrationOperations, collectionName: String, toSchemaVersion: UInt64) {
        self.operations = operations
        self.collectionName = collectionName
        self.toSchemaVersion = toSchemaVersion
    }

    open func removeValue(withKey key: String) throws {
        try operations.removeValue(withKey: key, in: collectionName)
    }

    open func set(serializedValue: Data, key: String) throws {
        try operations.set(serializedValue: serializedValue, key: key, version: toSchemaVersion, in: collectionName)
    }

    open func getSerializedValue(for key: String, in name: String) throws -> (valueData: Data, schemaVersion: UInt64)? {
        return try operations.getSerializedValue(for: key, in: name)
    }
}
