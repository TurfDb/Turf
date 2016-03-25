public final class ReadWriteTransaction: ReadTransaction {
    // MARK: Public properties

    // MARK: Internal properties

    internal var shouldRollback: Bool

    // MARK: Private properties

    // MARK: Object life cycle

    internal override init(connection: Connection) {
        self.shouldRollback = false
        super.init(connection: connection)
    }

    // MARK: Public methods

    /**
     Rollback all changes made in this transaction
     - note:
        - Thread safe
     */
    public func rollback() {
        shouldRollback = true
    }

    /**
     Removes all values in all collections
     - note:
        - Thread safe
     */
    public func removeAllCollections() {
        //TODO remove all collections
    }

    /**
     Returns a mutable read-write view of `collection` on the transaction
     - note:
        - Thread safe
     - returns: Read-write view of `collection`
     - parameter collection
    */
    public func readWrite<TCollection: Collection>(collection: TCollection) -> ReadWriteCollection<TCollection> {
        return ReadWriteCollection(collection: collection, transaction: self)
    }

    /**
     Register `collection` with the database to create a table.
     - note:
        - Thread safe
     - parameter collection
     */
    public func registerCollection<TCollection: Collection>(collection: TCollection) throws {
        try SQLiteCollection.createCollectionTableNamed(collection.name, db: connection.sqlite.db)
        connection.database.registerCollection(collection)
    }

    /**
     Register and install (if required) a database extension
     - note:
         - Thread safe
     - parameter extension An installable extension
     */
    public func registerExtension<Ext: Extension>(ext: Ext) throws {
        try connection.registerExtension(ext, onTransaction: self)
    }

    // MARK: Internal methods

    // MARK: Private methods
}
