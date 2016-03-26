public class MigrationOperations {
    // MARK: Object lifecycle

    init(sqlite: SQLiteAdapter) {
        
    }

    // MARK: Internal methods

    public func deleteCollection(name: String) throws {

    }

    public func createCollection(name: String) throws {

    }

    public func enumerateValuesInCollection(name: String, each: (value: NSData, version: UInt64) throws -> Bool) throws {

    }

    public func setSerializedValue(serializedValue: NSData, Key key: String, version: UInt64, inCollection name: String) throws {

    }

    public func getSerializedValueWithKey(key: String, inCollection name: String) throws -> (value: NSData, version: UInt64) {
        return (NSData(), 0)
    }
}