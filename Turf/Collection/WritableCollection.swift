import Foundation

public protocol WritableCollection {
    associatedtype Value

    /**
     - parameter value: Value
     - parameter key: Primary key
     */
    func setValue(_ value: Value, forKey key: String)

    /**
     - parameter keys: Collection of primary keys to remove if they exist
     */
    func removeValuesWithKeys(_ keys: [String])

    /**
     Remove all values in the collection
     */
    func removeAllValues()
}
