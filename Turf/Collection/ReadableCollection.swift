import Foundation

public protocol ReadableCollection {
    /// Collection row type
    associatedtype Value

    /**
     - returns: Number of keys in the collection
     */
    var numberOfKeys: UInt { get }

    /**
     - returns: All primary keys in collection
     */
    var allKeys: [String] { get }

    /**
     - parameter for: Primary key
     - returns: Value for primary key if it exists
     */
    func value(for key: String) -> Value?
}
