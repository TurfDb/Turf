/**
 Collection of indexed properties

 - note: TODO constrain `allProperties` further when Swift supports cyclic protocol definitions
    
    Example
    ```swift
     struct IndexedProperties: Turf.IndexedProperties {
         let isOnline = IndexedProperty<FriendsCollection, Bool>(name: "isOnline") { return $0.isOnline }
         let name = IndexedProperty<FriendsCollection, String>(name: "name") { return $0.name }

         var allProperties: [CollectionProperty] {
             return [isOnline, name]
         }
     }
    ```
 */

public protocol IndexedProperties {
    typealias IndexedCollection: Collection

    /// All indexed properties
    /// - warning: Do not mutate this after registering a SecondaryIndex extension
    var allProperties: [IndexedPropertyFromCollection<IndexedCollection>] { get }
}

public struct IndexedPropertyFromCollection<IndexedCollection: Collection> {
    internal let propertyValueForValue: (IndexedCollection.Value -> SQLiteType)
    internal let sqliteTypeName: SQLiteTypeName
    internal let isNullable: Bool
    internal let name: String

    //TODO Nice conversion?
    public init<T: SQLiteType>(property: IndexedProperty<IndexedCollection, T>) {
        self.sqliteTypeName = T.sqliteTypeName
        self.isNullable = T.isNullable
        self.propertyValueForValue = property.propertyValueForValue
        self.name = property.name
    }

    func bindPropertyValue(value: IndexedCollection.Value, toSQLiteStmt stmt: COpaquePointer, atIndex index: Int32) -> Int32 {
        let value = propertyValueForValue(value)
        print("\(index) \(name) = \(value)")
        return value.sqliteBind(stmt, index: index)
    }
}