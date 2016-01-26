/**
 Define a property of type `T` that will be indexed.
 */
internal protocol IndexedCollectionProperty: CollectionProperty, TypeErasedIndexedProperty {
    typealias PropertyCollection: Collection
    typealias PropertyType//:SQLiteType

    /// Property name
    var name: String { get }

    /// Property getter
    var propertyValueForValue: (PropertyCollection.Value -> PropertyType) { get }

    // MARK: Object lifecycle

    /**
    - parameter name: Property name
    - parameter propertyValueForValue: Getter for the property
    */
    init(name: String, propertyValueForValue: (PropertyCollection.Value -> PropertyType))

    /**
     Generates a SQL predicate for testing equality ogainst the property type T
     - note: Property must be comparable within SQLite
     - parameter value: The value to test equality against
     - returns: A predicate
     */
    func equals(value: PropertyType) -> String
}
