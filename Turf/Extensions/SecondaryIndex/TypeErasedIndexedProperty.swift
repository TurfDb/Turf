public protocol TypeErasedIndexedProperty: CollectionProperty {
    /// Property name
    var name: String { get }

    func sqliteTypeName() -> SQLiteTypeName
}
