import Foundation

public protocol WritableCollection {
    associatedtype Value

    /**
     - parameter value: Value
     - parameter key: Primary key
     */
    func set(value: Value, forKey key: String)

    /**
     - parameter withKeys: Collection of primary keys to remove if they exist
     */
    func removeValues(withKeys keys: [String])

    /**
     Remove all values in the collection
     */
    func removeAllValues()
}
