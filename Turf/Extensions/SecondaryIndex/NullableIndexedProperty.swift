/**
 Define a property of type `T?` that will be indexed.
 - note: Workaround for not having `extension Optional: SQLiteType where Wrapped = XYZ`. If Swift supports this we can greatly simplify the secondary indexing code, removing `IndexedCollectionProperty` etc.
 */
public struct NullableIndexedProperty<IndexedCollection: Collection, T: SQLiteType>: IndexedCollectionProperty, NullableProperty {
    typealias PropertyCollection = IndexedCollection
    typealias PropertyType = T?

    // MARK: Public properties

    public let name: String

    // MARK: Internal properties

    /// Property getter
    internal var propertyValueForValue: (IndexedCollection.Value -> T?)

    // MARK: Object lifecycle

    /**
    - parameter name: Property name
    - parameter propertyValueForValue: Getter for the property
    */
    public init(name: String, propertyValueForValue: (IndexedCollection.Value -> T?)) {
        self.name = name
        self.propertyValueForValue = propertyValueForValue
    }

    // MARK: Public methods

    /**
    Generates a SQL predicate for testing equality ogainst the property type T
    - note: Property must be comparable within SQLite
    - parameter value: The value to test equality against
    - returns: A predicate
    */
    public func equals(value: T?) -> String {
        return "WHERE \(name) = \(value)"//TODO
    }

    public func sqliteTypeName() -> SQLiteTypeName {
        return T.sqliteTypeName
    }
}
