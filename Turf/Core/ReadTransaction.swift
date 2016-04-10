public class ReadTransaction<DatabaseCollections: CollectionsContainer> {
    // MARK: Public properties

    /// Reference to parent connection
    public unowned let connection: Connection<DatabaseCollections>

    // MARK: Internal properties

    // MARK: Private properties

    // MARK: Object life cycle

    internal init(connection: Connection<DatabaseCollections>) {
        self.connection = connection
    }

    // MARK: Public methods

    /// Collection names
    public var collectionNames: [String] {
        return []
    }

    /**
     Returns a queryable readonly view of `collection` on the transaction's snapshot
     - returns: Read only view of `collection`
     - parameter collection: The Collection we want a readonly view of
     */
    public func readOnly<TCollection: Collection>(collection: TCollection) -> ReadCollection<TCollection, DatabaseCollections> {
        return ReadCollection(collection: collection, transaction: self)
    }

    // MARK: Internal methods

    // MARK: Private methods
}
