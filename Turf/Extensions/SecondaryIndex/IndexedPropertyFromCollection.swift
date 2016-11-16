public struct IndexedPropertyFromCollection<IndexedCollection: TurfCollection> {
    // MARK: Internal properties

    internal let propertyValueForValue: ((IndexedCollection.Value) -> SQLiteType)
    internal let sqliteTypeName: SQLiteTypeName
    internal let isNullable: Bool
    internal let name: String

    // MARK: Object lifecycle

    public init<T: SQLiteType>(property: IndexedProperty<IndexedCollection, T>) {
        self.sqliteTypeName = T.sqliteTypeName
        self.isNullable = false
        self.propertyValueForValue = property.propertyValueForValue
        self.name = property.name
    }

    public init<T: TurfSQLiteOptional>(property: IndexedProperty<IndexedCollection, T>) where T: SQLiteType {
        self.sqliteTypeName = T.sqliteTypeName
        self.isNullable = true
        self.propertyValueForValue = property.propertyValueForValue
        self.name = property.name
    }

    // MARK: Internal methods

    func bindPropertyValue(_ value: IndexedCollection.Value, toSQLiteStmt stmt: OpaquePointer, atIndex index: Int32) -> Int32 {
        let value = propertyValueForValue(value)
        return value.sqliteBind(stmt, index: index)
    }
}
