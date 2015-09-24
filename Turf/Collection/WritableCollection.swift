import Foundation

public protocol WritableCollection {
    typealias Value

    /**
     - parameter value: Value
     - parameter key: Primary key
     */
    func setValue(value: Value, forKey key: String)

    /**
     - parameter keys: Collection of primary keys to remove if they exist
     */
    func removeValuesWithKeys(keys: [String])

    /**
     Remove all values in the collection
     */
    func removeAllValues()
}