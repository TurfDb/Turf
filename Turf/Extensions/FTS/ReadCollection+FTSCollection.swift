public extension ReadCollection where TCollection: FTSCollection {
    // MARK: Public properties

    public var textProperties: TCollection.TextProperties { return collection.textProperties }

    // MARK: Internal properties

    // MARK: Private properties

    // MARK: Public methods

    public func findFirstValueWhereFTS(predicate: String) -> Value? {
        return nil
    }

    public func findValuesWhereFTS(predicate: String) -> [Value] {
        return []
    }

    // MARK: Internal methods

    // MARK: Private methods

    private func extensionConnection() -> FTSConnection<TCollection, TCollection.TextProperties> {
        return readTransaction.connection.connectionForExtension(collection.fts) as! FTSConnection<TCollection, TCollection.TextProperties>
    }
}
