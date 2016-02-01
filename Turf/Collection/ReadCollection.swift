public class ReadCollection<TCollection: Collection>: ReadableCollection {
    /// Collection row type
    public typealias Value = TCollection.Value

    // MARK: Public properties

    /// Collection name
    var name: String { return collection.name }

    /// Collection schema version - This must be incremented when the serialization structure changes
    var schemaVersion: UInt64 { return collection.schemaVersion }

    // MARK: Internal properties

    /// Reference to user defined collection
    internal unowned let collection: TCollection

    /// Reference to read transaction from which this collection reads on
    internal unowned let readTransaction: ReadTransaction

    /// Internal attributes required for functionality
    internal let localStorage: CollectionLocalStorage<Value>

    // MARK: Object lifecycle

    /// Work around to stop swift segfaulting when calling self.collection.deserializeValue(...)
    private let deserializeValue: (NSData) -> Value?

    /**
     - parameter collection: Collection this read-only view wraps
     - parameter transaction: Read transaction the read-only view reads on
     */
    internal init(collection: TCollection, transaction: ReadTransaction) {
        self.collection = collection
        self.readTransaction = transaction
        self.localStorage = readTransaction.connection.localStorageForCollection(collection)
        self.deserializeValue = collection.deserializeValue
    }

    // MARK: Public methods

    /**
     - returns: Number of keys in the collection
    */
    public var numberOfKeys: UInt {
        return localStorage.sql.numberOfKeysInCollection()
    }

    /**
     - returns: Primary keys in collection
     */
    public var allKeys: [String] {
        return localStorage.sql.keysInCollection()
    }

    /**
     Lazyily iterates over all values in the collection
     - warning: A ValueSequence is not a `struct` as it requires a `deinit` hook for safety
     - returns: All values in the collection
     */
    public var allValues: ValuesSequence<Value> {
        var stmt: COpaquePointer = nil
        //TODO cache
        sqlite3_prepare_v2(readTransaction.connection.sqlite.db, "SELECT data FROM table",  -1, &stmt, nil)
        return ValuesSequence(stmt: stmt, valueDataColumnIndex: 1, deserializer: collection.deserializeValue)
    }

    public var allKeysAndValues: [String: Value] {
        return [:]//TODO
    }

    /**
     Fetch the latest value from the database.
     - note: This can either hit the value cache or hit the database and deserialize the data blob.
     - parameter key: Primary key
     - returns: Value for primary key if it exists
     */
    public func valueForKey(key: String) -> Value? {
        if let cachedValue = localStorage.valueCache[key] {
            return cachedValue
        }

        if let result = localStorage.sql.valueDataForKey(key) {
            precondition(result.schemaVersion == collection.schemaVersion,
                "Collection \(name) requires a migration")

            if let value = deserializeValue(result.valueData) {
                localStorage.valueCache[key] = value
                return value
            }
        }

        return nil
    }
}
