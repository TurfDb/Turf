public class CollectionMigrationOperations {
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

    public func removeValueWithKey(key: String) throws {
        try operations.removeValueWithKey(key, inCollection: collectionName)
    }

    public func setSerializedValue(serializedValue: NSData, key: String) throws {
        try operations.setSerializedValue(serializedValue, key: key, version: toSchemaVersion, inCollection: collectionName)
    }

    public func getSerializedValueWithKey(key: String, inCollection name: String) throws -> (valueData: NSData, schemaVersion: UInt64)? {
        return try operations.getSerializedValueWithKey(key, inCollection: name)
    }
}
