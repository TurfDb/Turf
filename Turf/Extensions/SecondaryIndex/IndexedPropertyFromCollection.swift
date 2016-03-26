public struct IndexedPropertyFromCollection<IndexedCollection: Collection> {
    // MARK: Internal properties

    internal let propertyValueForValue: (IndexedCollection.Value -> SQLiteType)
    internal let sqliteTypeName: SQLiteTypeName
    internal let isNullable: Bool
    internal let name: String

    // MARK: Object lifecycle

    public init<T: SQLiteType>(property: IndexedProperty<IndexedCollection, T>) {
        self.sqliteTypeName = T.sqliteTypeName
        self.isNullable = T.isNullable
        self.propertyValueForValue = property.propertyValueForValue
        self.name = property.name
    }

    // MARK: Internal methods

    func bindPropertyValue(value: IndexedCollection.Value, toSQLiteStmt stmt: COpaquePointer, atIndex index: Int32) -> Int32 {
        let value = propertyValueForValue(value)
        return value.sqliteBind(stmt, index: index)
    }
}
