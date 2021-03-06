public struct IndexedPropertyFromCollection<IndexedCollection: TurfCollection> {
    // MARK: Internal properties

    internal let propertyValueForValue: ((IndexedCollection.Value) -> SQLiteType)
    internal let sqliteTypeName: SQLiteTypeName
    internal let isNullable: Bool
    internal let name: String

    // MARK: Object lifecycle

    public init<T>(property: IndexedProperty<IndexedCollection, T>) {
        self.sqliteTypeName = T.sqliteTypeName
        self.isNullable = T.isNullable
        self.propertyValueForValue = property.propertyValueForValue
        self.name = property.name
    }

    // MARK: Internal methods

    /// TODO: Remove `@discardableResult`.
    @discardableResult
    func bindPropertyValue(_ value: IndexedCollection.Value, toSQLiteStmt stmt: OpaquePointer, atIndex index: Int32) -> Int32 {
        let value = propertyValueForValue(value)
        return value.sqliteBind(stmt, index: index)
    }
}
