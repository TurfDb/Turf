/**
 Define a property of type `T` that will be indexed.
 */
public struct IndexedProperty<IndexedCollection: Collection, T: SQLiteType> {
    // MARK: Public properties

    public let name: String

    public let Type: T.Type = T.self

    // MARK: Internal properties

    /// Property getter
    internal var propertyValueForValue: (IndexedCollection.Value -> T)

    // MARK: Object lifecycle

    /**
    - parameter name: Property name
    - parameter propertyValueForValue: Getter for the property
    */
    public init(name: String, propertyValueForValue: (IndexedCollection.Value -> T)) {
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
    public func equals(value: T) -> String {
        return "WHERE \(name)=\(value.sqliteValue())"//TODO
    }

    public func lift() -> IndexedPropertyFromCollection<IndexedCollection> {
        return IndexedPropertyFromCollection(property: self)
    }

    // MARK: Internal methods

    internal func bindPropertyValue(value: IndexedCollection.Value, toSQLiteStmt stmt: COpaquePointer, atIndex index: Int32) -> Int32 {
        let value = propertyValueForValue(value)
        return value.sqliteBind(stmt, index: index)
    }
}