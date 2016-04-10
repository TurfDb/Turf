public final class ReadWriteTransaction<DatabaseCollections: CollectionsContainer>: ReadTransaction<DatabaseCollections> {
    // MARK: Public properties

    // MARK: Internal properties

    internal var shouldRollback: Bool

    // MARK: Private properties

    // MARK: Object life cycle

    internal override init(connection: Connection<DatabaseCollections>) {
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
     Returns a mutable read-write view of `collection` on the transaction
     - note:
        - Thread safe
     - returns: Read-write view of `collection`
     - parameter collection: The Collection we want a read-write view of
    */
    public func readWrite<TCollection: Collection>(collection: TCollection) -> ReadWriteCollection<TCollection, DatabaseCollections> {
        //TODO Cache 
        return ReadWriteCollection(collection: collection, transaction: self)
    }

    /**
     Register `collection` with the database to create a table.
     - note:
        - Thread safe
     - parameter collection: The Collection we want to register. This creates a table in the database with the same name as the collection's 'name' property
     */
    public func registerCollection<TCollection: Collection>(collection: TCollection) throws {
        try SQLiteCollection.createCollectionTableNamed(collection.name, db: connection.sqlite.db)
        connection.database.registerCollection(collection)
    }

    /**
     Register and install (if required) a database extension
     - note:
         - Thread safe
     - parameter ext: An installable extension
     */
    public func registerExtension<Ext: Extension>(ext: Ext) throws {
        try connection.registerExtension(ext, onTransaction: self)
    }
}
