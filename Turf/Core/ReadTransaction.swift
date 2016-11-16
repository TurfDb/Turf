open class ReadTransaction<DatabaseCollections: CollectionsContainer> {
    // MARK: Public properties

    /// Reference to parent connection
    open unowned let connection: Connection<DatabaseCollections>

    /// Available collections associated with this database transaction
    open var collections: DatabaseCollections { return connection.database.collections }

    // MARK: Internal properties

    // MARK: Private properties

    // MARK: Object life cycle

    internal init(connection: Connection<DatabaseCollections>) {
        self.connection = connection
    }

    // MARK: Public methods

    /// Collection names
    open var collectionNames: [String] {
        return []
    }

    /**
     Returns a queryable readonly view of `collection` on the transaction's snapshot
     - returns: Read only view of `collection`
     - parameter collection: The Collection we want a readonly view of
     */
    open func readOnly<TCollection: TurfCollection>(_ collection: TCollection) -> ReadCollection<TCollection, DatabaseCollections> {
        return ReadCollection(collection: collection, transaction: self)
    }

    // MARK: Internal methods

    // MARK: Private methods
}
