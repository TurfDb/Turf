import Foundation

public protocol ReadableCollection {
    /// Collection row type
    typealias Value

    /**
     - returns: Number of keys in the collection
     */
    var numberOfKeys: UInt { get }

    /**
     - returns: All primary keys in collection
     */
    var allKeys: [String] { get }

    /**
     - parameter key: Primary key
     - returns: Value for primary key if it exists
     */
    func valueForKey(key: String) -> Value?
}
