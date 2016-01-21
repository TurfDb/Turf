public extension ReadCollection where TCollection: IndexedCollection {
    // MARK: Public properties

    /// Indexed properties on collection
    public var indexed: TCollection.IndexProperties { return collection.indexed }

    // MARK: Public methods

    /**
     Find the first value that matches the given predicate using the collection's secondary index
     - parameter predicate: Query on secondary indexed properties
     - returns: Value if there is a match
     */
    public func findFirstValueWhere(predicate: String) -> Value? {
        let connection = extensionConnection()
        let _ = connection.queryCache.q("SELECT value FROM table \(predicate) LIMIT 1")

        

        return nil
    }

    /**
     Find all values that matches the given predicate using the collection's secondary index
     - parameter predicate: Query on secondary indexed properties
     - returns: Values that match the predicate
     */
    public func findValuesWhere(predicate: String) -> [Value] {
        let connection = extensionConnection()
//        let _ = connection.queryCache.q("SELECT value FROM table \(predicate)")

        return []
    }

    // MARK: Private methods

    private func extensionConnection() -> SecondaryIndexConnection<TCollection, TCollection.IndexProperties> {
        return readTransaction.connection.connectionForExtension(collection.index) as! SecondaryIndexConnection<TCollection, TCollection.IndexProperties>
    }
}
