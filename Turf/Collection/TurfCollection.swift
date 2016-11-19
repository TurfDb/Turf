import Foundation

/**
 Defines a collection that contains values of type `Value`
 */
public protocol TurfCollection: class, TypeErasedCollection {
    /// Collection row type
    associatedtype Value

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
    func serialize(value: Value) -> Data

    /**
     Deserialize collection values from persistent format
     - returns: Value if conforms to persisted format
     - parameter data Data from persistence
     */
    func deserialize(data: Data) -> Value?

    /**
     Perform initial collection registration and setup.
     - note:
        Example implementation for a collection with a secondary index extension
        ```swift
         func setUp(transaction: ReadWriteTransaction) throws {
             transaction.registerCollection(self)
             transaction.registerExtension(index)
         }
        ```
     - warning: You must call `transaction.registerCollection(self)`
     - parameter transaction
     */
    func setUp<Collections: CollectionsContainer>(using transaction: ReadWriteTransaction<Collections>) throws
}
