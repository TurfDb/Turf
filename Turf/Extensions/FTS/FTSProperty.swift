public struct FTSProperty<TCollection: Collection>: CollectionProperty {
    // MARK: Public properties

    public let name: String

    // MARK: Internal properties

    internal var propertyTextForValue: (TCollection.Value -> String)

    // MARK: Object lifecycle

    public init(name: String, propertyTextForValue: (TCollection.Value -> String)) {
        self.name = name
        self.propertyTextForValue = propertyTextForValue
    }

    // MARK: Public methods

    public func matches(value: String) -> Void {
        return 
    }

    public func sqliteTypeName() -> SQLiteTypeName {
        return String.sqliteTypeName
    }
}
