public protocol CollectionMigration {
    var collectionName: String { get }
    var fromModelVersion: UInt64 { get }
    var toModelVersion: UInt64 { get }

    func migrate(serializedValue: NSData, key: String, operations: CollectionMigrationOperations) throws
}

public class CollectionMigrationOperations {
    public func setSerializedValue(serializedValue: NSData, Key key: String) throws {

    }

    public func getSerializedValueWithKey(key: String, inCollection name: String) throws -> (value: NSData, version: UInt64) {
        return (NSData(), 0)
    }
}