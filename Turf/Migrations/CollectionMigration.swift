public protocol CollectionMigration {
    var collectionName: String { get }
    var fromSchemaVersion: UInt64 { get }
    var toSchemaVersion: UInt64 { get }

    func migrate(serializedValue: NSData, key: String, operations: CollectionMigrationOperations) throws
}
