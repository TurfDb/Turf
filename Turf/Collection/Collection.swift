import Foundation

/**
 Defines a collection that contains values of type `Value`
 */
public protocol Collection: class, TypeErasedCollection {
    /// Collection row type
    typealias Value

    /// Collection name
    var name: String { get }

    /// Collection schema version - This must be incremented when the serialization structure changes
    var schemaVersion: UInt64 { get }

    /// Value cache size
    var valueCacheSize: Int? { get }

    /**
     Serialize collection values for persistence
     - returns: Data to be stored as a SQLite blob
     - parameter value
     */
    func serializeValue(value: Value) -> NSData

    /**
     Deserialize collection values from persistent format
     - returns: Value if conforms to persisted format
     - parameter data Data from persistence
     */
    func deserializeValue(data: NSData) -> Value?

    /**
     Perform initial collection registration and setup.
     - note:
        Example implementation for a collection with a secondary index extension
        ```swift
         func setUp(transaction: ReadWriteTransaction) {
             transaction.registerCollection(self)
             transaction.registerExtension(index)
         }
        ```
     - warning: You must call `transaction.registerCollection(self)`
     - parameter transaction
     */
    func setUp(transaction: ReadWriteTransaction)
}
