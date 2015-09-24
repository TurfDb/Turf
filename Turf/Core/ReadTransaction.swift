public class ReadTransaction {
    // MARK: Public properties

    /// Reference to parent connection
    public unowned let connection: Connection

    // MARK: Internal properties

    // MARK: Private properties

    // MARK: Object life cycle

    internal init(connection: Connection) {
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
     - parameter collection
     */
    public func readOnly<TCollection: Collection>(collection: TCollection) -> ReadCollection<TCollection> {
        return ReadCollection(collection: collection, transaction: self)
    }

    // MARK: Internal methods

    // MARK: Private methods
}
