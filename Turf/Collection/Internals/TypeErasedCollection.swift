public protocol TypeErasedCollection: class {
    /// Collection name
    var name: String { get }

    /// Collection schema version - This must be incremented when the serialization structure changes
    var schemaVersion: UInt { get }

    /// Value cache size. If nil, it will use the default size for each connection
    var valueCacheSize: Int? { get }

    /**
     - parameter transaction
     */
    func setUp(transaction: ReadWriteTransaction)
}
